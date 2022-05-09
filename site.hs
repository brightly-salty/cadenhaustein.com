{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative (Alternative (empty))
import Data.Aeson
import Data.Foldable (forM_, foldl')
import Data.List (intercalate, isSuffixOf, sortBy)
import Data.List.Split (splitOn)
import Data.Maybe (fromJust, fromMaybe)
import Data.Monoid (mappend)
import Data.String (IsString (..))
import GHC.Generics
import Hakyll
import System.FilePath (takeBaseName, takeDirectory, (</>))
import Text.HTML.TagSoup (Tag (..))

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
  forM_ ["robots.txt", "favicon.ico", "books/*.epub", "books/*.pdf", "books/*.mobi", "fonts/*"] $ \f -> match f $ do
    route idRoute
    compile copyFileCompiler

  match "books/*/read/index.html" $ do
    route idRoute
    compile $
      getResourceString
        >>= relativizeUrls
        >>= cleanIndexUrls
        >>= cleanInlineCSS

  match "books/*/index.html" $ do
      route idRoute
      compile $
        getResourceString
          >>= relativizeUrls
          >>= cleanIndexUrls
          >>= cleanInlineCSS

  match "styles/*" $ do
    route idRoute
    compile compressCssCompiler

  match "404.md" $ do
    route $ customRoute $ const "404.html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> dontDoBooks)
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "about.md" $ do
    route $ customRoute $ const "about/index.html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> dontDoBooks)
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "index.html" $ do
    route idRoute
    dependency <- makePatternDependency "books.json"
    rulesExtraDependencies [dependency] $
      compile $ do
        Just books <- recompilingUnsafeCompiler $ decodeFileStrict "books.json"
        getResourceBody >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> booksField books <> boolField "doBooks" (const True)) >>= relativizeUrls 

  create ["sitemap.txt"] $ do
    route idRoute
    compile $ do
      pages <- loadAll ("books/*/index.html" .||. "books/*/read/index.html" .||. fromList ["about.md", "index.html"])
      let sitemapCtx = listField "pages" (constField "root" root <> defaultContext) (pure pages) <> constField "root" root
      makeItem "" >>= loadAndApplyTemplate "templates/sitemap.txt" sitemapCtx

  match ("templates/hakyll.html" .||. "templates/sitemap.txt") $ compile templateBodyCompiler

config :: Configuration
config = defaultConfiguration {destinationDirectory = "docs"}

--------------------------------------------------------------------------------

dontDoBooks :: Context a
dontDoBooks = boolField "doBooks" (const False)

domain :: String
domain = "cadenhaustein.com"

root :: String
root = "https://" <> domain

cleanInlineCSS :: Item String -> Compiler (Item String)
cleanInlineCSS = withItemBody (pure . withTagList editTags)
  where
    editTags :: [Tag String] -> [Tag String]
    editTags = reverse . snd . foldl' editTag ([], [])

    editTag :: ([Tag String], [Tag String]) -> Tag String -> ([Tag String], [Tag String])
    editTag ([], done) (TagOpen "style" attrs) = ([TagOpen "style" attrs], done)
    editTag ([], done) tag = ([], tag : done)
    editTag (previous, done) (TagClose "style") = ([], TagClose "style" : (reverse previous <> done))
    editTag (previous, done) (TagText text) = (previous <> [TagText (compressCss text)], done)
    editTag (previous, done) tag = (previous <> [tag], done)

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = pure . fmap (withUrls cleanIndex)

replace :: Eq a => [a] -> [a] -> [a] -> [a]
replace from to = intercalate to . splitOn from

cleanIndex :: String -> String
cleanIndex = replace ".html" "" . replace "index.html" "./" . replace "/index.html" "/"

data Book = Book {author :: String, title :: String, year :: Int, tag :: String, source :: Maybe String, votes :: Int}
  deriving (Generic, Show)

instance ToJSON Book where
  toEncoding = genericToEncoding defaultOptions

instance FromJSON Book

compareBooks :: Book -> Book -> Ordering
compareBooks a b
  | votes a > votes b = LT
  | votes a < votes b = GT
  | otherwise = compare (year b) (year a)

booksField :: [Book] -> Context String
booksField books = listField "books" bookCtx (pure items)
  where
    items = (\book -> Item (fromString (tag book)) book) <$> sortBy compareBooks books
    bookCtx =
      field "tag" (pure . tag . itemBody)
        <> field "author" (pure . author . itemBody)
        <> field "title" (pure . title . itemBody)
        <> field "year" (pure . show . year . itemBody)
        <> field "votes" (pure . show . votes . itemBody)
        <> field
          "source"
          ( \item ->
              case source (itemBody item) of
                Just src -> pure src
                Nothing -> noResult ""
          )