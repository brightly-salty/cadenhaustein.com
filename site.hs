--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.Foldable (forM_)
import Data.List (isSuffixOf)
import Data.Maybe (fromMaybe)
import Data.Monoid (mappend)
import Hakyll
import System.FilePath (takeBaseName, takeDirectory, (</>))

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
  forM_ ["_redirects", "CNAME", "sitemap.txt", "robots.txt", "favicon.ico", "books/*.epub", "books/*.pdf", "books/*.mobi", "books/*/menu.svg", "books/*/images/*.png", "books/*/print.css", "books/*/stylesheet.css"] $ \f -> match f $ do
    route idRoute
    compile copyFileCompiler

  match "books/*/*.html" $ do
    route idRoute
    compile $
      getResourceString
        >>= relativizeUrls

  match "css/default.css" $ do
    route idRoute
    compile compressCssCompiler

  match "about.md" $ do
    route cleanRoute
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/hakyll.html" defaultContext
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "index.html" $ do
    route idRoute
    compile $
      getResourceBody
        >>= loadAndApplyTemplate "templates/hakyll.html" defaultContext
        >>= relativizeUrls

  match "templates/hakyll.html" $ compile templateBodyCompiler

config :: Configuration
config = defaultConfiguration {destinationDirectory = "docs"}

--------------------------------------------------------------------------------

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
      where
        p = toFilePath ident

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = pure . fmap (withUrls cleanIndex)

cleanIndexHtmls :: Item String -> Compiler (Item String)
cleanIndexHtmls = pure . fmap (replaceAll "/index.html" (const "/"))

cleanIndex :: String -> String
cleanIndex url
  | idx `isSuffixOf` url = take (length url - length idx) url
  | otherwise = url
  where
    idx = "index.html"
