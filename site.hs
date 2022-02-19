--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.Foldable (forM_)
import Data.List (isSuffixOf, sortOn, intercalate)
import Data.Maybe (fromMaybe)
import Data.Monoid (mappend)
import Data.String (IsString (..))
import Hakyll
import System.FilePath (takeBaseName, takeDirectory, (</>))
import Control.Applicative (Alternative(empty))
import Data.List.Split (splitOn)

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
  forM_ ["robots.txt", "favicon.ico", "books/*.epub", "books/*.pdf", "books/*.mobi", "books/*/images/*", "scripts/*", "fonts/*", "images/*", "wordle/manifest.json", "wordle/main.js", "wordle/images/*"] $ \f -> match f $ do
    route idRoute
    compile copyFileCompiler

  match ("books/*/index.html" .||. "wordle/index.html") $ do
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

  match "about.md" $ do
    route $ customRoute $ const "about/index.html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> boolField "doBooks" (const False))
        >>= relativizeUrls
        >>= cleanIndexUrls

  match "index.html" $ do
    route idRoute
    compile $
      getResourceBody
        >>= loadAndApplyTemplate "templates/hakyll.html" (defaultContext <> booksField <> boolField "doBooks" (const True))
        >>= relativizeUrls

  create ["CNAME"] $ do
    route idRoute
    compile $ makeItem domain

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

data Book = Book {author :: String, title :: String, year :: Int, tag :: String, source :: String}

books :: [Book]
books =
  [ Book {author = chesterton, title = "Outline of Sanity", year = 1926, tag = "outline-sanity", source = ""},
    Book {author = chesterton, title = "What I Saw in America", year = 1922, tag = "saw-america", source = "https://archive.org/details/whatisawinamer00chesrich"},
    Book {author = chesterton, title = "Utopia of Usurers", year = 1917, tag = "utopia-usurers", source = "https://archive.org/details/utopiaofusurerso00ches/page/n16"},
    Book {author = chesterton, title = "Orthodoxy", year = 1908, tag = "orthodoxy", source = "https://archive.org/details/orthodoxy00chesuoft"},
    Book {author = chesterton, title = "The Napoleon of Notting Hill", year = 1904, tag = "napoleon-notting", source = "https://archive.org/details/napoleonofnottin00chesiala"},
    Book {author = chesterton, title = "Eugenics and Other Evils", year = 1922, tag = "eugenics-evils", source = "https://archive.org/details/eugenics00chesuoft"},
    Book {author = penty, title = "Guilds, Trade, and Agriculture", year = 1921, tag = "guilds-trade", source = "https://archive.org/details/guildstradeagric00pentuoft"},
    Book {author = penty, title = "A Guildsman's Interpretation of History", year = 1920, tag = "guildsman-history", source = "https://archive.org/details/guildsmanhistory00pentuoft"},
    Book {author = penty, title = "The Restoration of the Guild System", year = 1906, tag = "restoration-guild", source = "https://archive.org/details/restorationofgil00pentrich"},
    Book {author = belloc, title = "The Free Press", year = 1918, tag = "the-free-press", source = "https://archive.org/details/freepress00bellrich"},
    Book {author = belloc, title = "The Servile State", year = 1912, tag = "servile-state", source = "https://archive.org/details/servilestate00belluoft"},
    Book {author = belloc, title = "Economics for Helen", year = 1924, tag = "economics-helen", source = "https://archive.org/details/belloc-hilaire-economics-for-helen-1924"},
    Book {author = douglas, title = "The Control and Distribution of Production", year = 1922, tag = "control-distribution", source = "https://archive.org/details/controldistribut00douguoft"},
    Book {author = douglas, title = "Economic Democracy", year = 1920, tag = "economic-democracy", source = "https://archive.org/details/econdemocracy00dougiala"},
    Book {author = george, title = "Social Problems", year = 1883, tag = "social-problems", source = "https://archive.org/details/socialproblems83geor"},
    Book {author = george, title = "The Condition of Labor", year = 1891, tag = "condition-labor", source = "https://archive.org/details/conditionoflabor00georuoft"},
    Book {author = "Leo Tolstoy", title = "Christianity and Patriotism", year = 1894, tag = "christianity-patriotism", source = "https://archive.org/details/completeworksofc20tols/page/381"},
    Book {author = "Ralph Borsodi", title = "Flight from the City", year = 1933, tag = "flight-from-city", source = "https://archive.org/details/flightfromcityan00borsrich"},
    Book {author = "Thomas Paine", title = "Agrarian Justice", year = 1797, tag = "agrarian-justice", source = "https://archive.org/details/agrarianjusticeo00pain"}
  ]
  where
    chesterton = "G. K. Chesterton"
    penty = "Arthur Penty"
    belloc = "Hilaire Belloc"
    douglas = "C. H. Douglas"
    george = "Henry George"

booksField :: Context String
booksField =
  let items = (\book -> Item (fromString (tag book)) book) <$> sortOn year books
   in let bookCtx = field "tag" (pure . tag . itemBody) <> field "author" (pure . author . itemBody) <> field "title" (pure . title . itemBody) <> field "year" (pure . show . year . itemBody) <> field "source" (\item -> let src = source (itemBody item) in if src /= "" then pure src else noResult "")
       in listField "books" bookCtx (pure items)