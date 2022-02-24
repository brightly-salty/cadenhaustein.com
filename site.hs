{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative (Alternative (empty))
import Data.Aeson
import Data.Foldable (forM_)
import Data.List (intercalate, isSuffixOf, sortBy)
import Data.List.Split (splitOn)
import Data.Maybe (fromJust, fromMaybe)
import Data.Monoid (mappend)
import Data.String (IsString (..))
import GHC.Generics
import Hakyll
import System.FilePath (takeBaseName, takeDirectory, (</>))

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
  forM_ ["robots.txt", "favicon.ico", "books/*.epub", "books/*.pdf", "books/*.mobi", "books/*/images/*", "scripts/*", "fonts/*", "images/*"] $ \f -> match f $ do
    route idRoute
    compile copyFileCompiler

  match ("books/*/index.html") $ do
    route idRoute
    compile $
      getResourceString
        >>= relativizeUrls
        >>= cleanIndexUrls

  match ("books/*/*.html" .&&. complement "books/*/index.html") $ do
    route cleanRoute
    compile $
      getResourceString
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "styles/*" $ do
    route idRoute
    compile compressCssCompiler

  match "404.md" $ do
    route $ customRoute $ const "404.html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> boolField "doBooks" (const False))
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "about.md" $ do
    route $ customRoute $ const "about/index.html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> boolField "doBooks" (const False))
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "index.html" $ do
    route idRoute
    dependency <- makePatternDependency "books.json"
    rulesExtraDependencies [dependency] $ compile $ do
      body <- getResourceBody
      Just books <- recompilingUnsafeCompiler $ decodeFileStrict "books.json"
      newBody <- loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> booksField books <> boolField "doBooks" (const True)) body
      relativizeUrls newBody

  create ["sitemap.txt"] $ do
    route idRoute
    compile $ do
      pages <- loadAll ("books/*/*.html" .||. fromList ["about.md", "index.html"])
      let sitemapCtx = listField "pages" (constField "root" root <> defaultContext) (pure pages) <> constField "root" root
      makeItem "" >>= loadAndApplyTemplate "templates/sitemap.txt" sitemapCtx

  match ("templates/hakyll.html" .||. "templates/sitemap.txt") $ compile templateBodyCompiler

config :: Configuration
config = defaultConfiguration {destinationDirectory = "docs"}

--------------------------------------------------------------------------------

domain :: String
domain = "cadenhaustein.com"

root :: String
root = "https://" <> domain

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
      where
        p = toFilePath ident

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