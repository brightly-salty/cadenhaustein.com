{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative (Alternative (empty))
import Data.Aeson
import Data.Foldable (forM_, foldl')
import Data.List (sort, nub, intercalate, isSuffixOf, sortBy)
import Data.List.Split (splitOn)
import Data.Maybe (fromJust, fromMaybe)
import Data.Monoid (mappend)
import Data.String (IsString (..))
import GHC.Generics
import Hakyll
import System.FilePath (takeBaseName, takeDirectory, (</>))
import Text.HTML.TagSoup (Tag (..))
import Prelude hiding (words)
import Control.Arrow (second)
import GHC.Float

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
  forM_ ["robots.txt", "favicon.ico", "count.js", "books/*/*.epub", "books/*/*.pdf", "books/*/*.mobi", "fonts/*"] $ \f -> match f $ do
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

  match "blog/*.md" $ do
    route $ gsubRoute ".md" (const "/index.html") 
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/hakyll.html" (postCtx <> dontDoBooks)
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
        result <- recompilingUnsafeCompiler $ eitherDecodeFileStrict "books.json"
        case result of
          Right bookData ->
            getResourceBody >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> booksField bookData <> boolField "doBooks" (const True)) >>= relativizeUrls 
          Left e -> error e

  create ["blog/index.html"] $ do
    route idRoute
    compile $ do
      posts <- loadAll "blog/*.md"
      let ctx = listField "posts" postCtx (pure posts) <> constField "title" "Blog" <> dontDoBooks <> defaultContext
      makeItem ""
        >>= loadAndApplyTemplate "templates/blog.html" ctx
        >>= loadAndApplyTemplate "templates/hakyll.html" ctx
        >>= relativizeUrls
        >>= cleanIndexUrls

  create ["sitemap.txt"] $ do
    route idRoute
    compile $ do
      pages <- loadAll ("books/*/index.html" .||. "books/*/read/index.html" .||. "blog/*.md" .||. fromList ["about.md", "index.html", "blog/index.html"])
      let sitemapCtx = listField "pages" (constField "root" root <> defaultContext) (pure pages) <> constField "root" root
      makeItem "" >>= loadAndApplyTemplate "templates/sitemap.txt" sitemapCtx

  match ("templates/hakyll.html" .||. "templates/sitemap.txt" .||. "templates/post.html" .||. "templates/post-list.html" .||. "templates/blog.html") $ compile templateBodyCompiler

config :: Configuration
config = defaultConfiguration {destinationDirectory = "docs"}

--------------------------------------------------------------------------------

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

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

data BookData = BookData {categories :: [String], books :: [Book]}
  deriving (Generic, Show)

instance FromJSON BookData

data Book = Book {author :: String, title :: String, year :: Int, tag :: String, source :: String, hash :: String, words :: Int, category :: Int}
  deriving (Generic, Show)

instance FromJSON Book

prettyWords :: Book -> String
prettyWords book =
  let wds = fromIntegral $ words book in
  let order = double2Int (logBase 10 wds) - 1 in
  let [c1, c2] = show $ double2Int $ wds / (10 ** (fromIntegral order)) in
  case order of 
    1 -> c1:c2:"0"
    2 -> c1:'.':c2:"k"
    3 -> c1:c2:"k"
    4 -> c1:c2:"0k"
    5 -> c1:'.':c2:"m"
    6 -> c1:c2:"m"
    7 -> c1:c2:"0m"
    _ -> error $ show order

compareBooks :: Book -> Book -> Ordering
compareBooks a b = compare (year b) (year a)

booksField :: BookData -> Context String
booksField bookData = listField "categories" categoryCtx (pure cats)
  where
    makeCatItem index cat = Item (fromString cat) (cat, filter ((index ==) . category) (books bookData))
    cats = zipWith makeCatItem [0..] $ categories bookData
    categoryCtx = listFieldWith "books" bookCtx (\item -> let bks = snd (itemBody item) in pure ((\book -> Item (fromString (tag book)) book) <$> sortBy compareBooks bks)) <> field "category" (pure . fst . itemBody)
    bookCtx =
      field "tag" (pure . tag . itemBody)
        <> field "author" (pure . author . itemBody)
        <> field "title" (pure . title . itemBody)
        <> field "year" (pure . show . year . itemBody)
        <> field "words" (pure . prettyWords . itemBody)
        <> field
          "source"
          ( \item ->
              if source (itemBody item) == ""
                then noResult ""
                else pure $ source $ itemBody item
          )