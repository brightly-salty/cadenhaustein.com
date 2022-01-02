--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import qualified Data.Text as T
import           Slug (toSlug)
import           Data.Maybe (fromMaybe)
import           Data.Foldable (forM_)

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    forM_ ["CNAME", "images/*"] $ \f -> match f $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.md", "contact.md"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        let ctx = constField "type" "article" <> postCtx
        route $ metadataRoute titleRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    ctx
            >>= loadAndApplyTemplate "templates/default.html" ctx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

config :: Configuration
config = defaultConfiguration { destinationDirectory = "docs", deployCommand = "git checkout main; stack exec site clean; stack exec site build ; git add -A; git commit -m \"Publish.\"; git push origin main:main" }

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

titleRoute :: Metadata -> Routes
titleRoute = constRoute . fileNameFromTitle

fileNameFromTitle :: Metadata -> FilePath
fileNameFromTitle = T.unpack . (`T.append` ".html") . toSlug . T.pack . getTitleFromMeta

getTitleFromMeta :: Metadata -> String
getTitleFromMeta = fromMaybe "no title" . lookupString "title"

