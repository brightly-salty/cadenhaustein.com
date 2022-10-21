#!/usr/bin/env nim
mode = ScriptMode.Silent
--hints:off

import std/[linenoise]
import std/[algorithm, enumerate, hashes, json, macros, os, sequtils, strutils]

type BuilderError = object of CatchableError

type Book = object
  author: string 
  source: string
  tag: string
  title: string
  year: int
  words: int
  hash: string
  category: int

func `<`(x, y: Book): bool {.raises: [].} =
  if x.category != y.category: return x.category < y.category
  x.year > y.year
  
type BookBuilder = object
  books: seq[Book]
  categories: seq[string]

func sourceFile(book: Book): string {.raises: [].} =
  "src" / book.tag.addFileExt "md"

macro wrap(s) =
  quote do:
    try:
      `s`
    except Exception as e:
      raise newException(BuilderError, e.msg)

proc createBuilder(): BookBuilder {.raises: [BuilderError].} =
  wrap: result = "books.json".readFile.parseJson.to(BookBuilder)

proc save(builder: var BookBuilder) {.raises: [BuilderError].} =
  wrap:
    builder.books.sort()
    var jsonNode = %*builder 
    var data: string
    data.toUgly jsonNode
    "books.json".writeFile data

proc countWords(contents: string): int {.raises: [BuilderError].} =
  wrap:
    var inWord = false
    for c in contents:
      if c in Whitespace:
        inWord = false
      elif not inWord:
        result.inc
        inWord = true

proc make(book: var Book) {.raises: [BuilderError].}=
  let dir = "books" / book.tag
  wrap: dir.mkDir
  let readDir = dir / "read"
  wrap: readDir.mkDir
  let commonCommand = "/usr/local/bin/pandoc --wrap=auto --table-of-contents --standalone --reference-location=block --section-divs --from=markdown+smart+auto_identifiers --metadata=author:" & book.author.quoteShell & " --metadata=title:" & book.title.quoteShell & " --metadata=date:" & quoteShell($book.year) & " " & book.sourceFile.quoteShell
  let pdfFile = dir / book.tag.addFileExt("pdf")
  wrap: exec(commonCommand & " --to=pdf --pdf-engine=xelatex --output=" & pdfFile)
  let htmlFile = readDir / "index.html"
  wrap: exec(commonCommand & " --to=html --template=templates/pandoc.html --output=" & htmlFile)
  let epubFile = dir / book.tag.addFileExt("epub")
  wrap: exec(commonCommand & " --to=epub --template=templates/pandoc.epub --output=" & epubFile)
  let mobiFile = dir / book.tag.addFileExt("mobi")
  wrap: exec("/usr/local/bin/ebook-convert " & epubFile & " " & mobiFile)
  var s = "<!doctype html><head><meta charset='utf-8'><meta http-equiv='x-ua-compatible' content='ie=edge'><meta name='viewport' content='width=device-width, initial-scale=1'><link rel='stylesheet' href='../../styles/hakyll.css'/><title>"
  s &= book.title
  s &= "</title><meta name='author' content='"
  s &= book.author
  s &= "'></head><body><header><div class='logo'><a href='/'>Caden Haustein</a></div><nav><a href='/'>Home</a><a href='/about/'>About</a><a href='/blog/'>Blog</a></nav></header><main role='main'><h1>"
  s &= book.title
  s &= "</h1><p>Written by "
  s &= book.author
  s &= " in "
  s &= $book.year
  s &= "</p><p><a href='read/index.html'>Read it online</a></p><p><a href='"
  s &= book.tag
  s &= ".pdf'>Download a PDF</a></p><p><a href='"
  s &= book.tag
  s &= ".epub'>Download an EPUB</a></p><p><a href='"
  s &= book.tag
  s &= ".mobi'>Download a MOBI</a></p>"
  if book.source != "":
    s &= "<br><p>Created from the page scans <a href='"
    s &= book.source
    s &= "'>here</a>."
  s &= "<p xmlns:dct='http://purl.org/dc/terms/'><a rel='license' href='http://creativecommons.org/publicdomain/mark/1.0/'><img src='http://i.creativecommons.org/p/mark/1.0/88x31.png' style='border-style: none' alt='Public Domain Mark' /></a><br />This work (<span property='dct:title'>"
  s &= book.title
  s &= "</span>, by <span resource='[_:creator]' rel='dct:creator'><span property='dct:title'>"
  s &= book.author
  s &= "</span></span>), identified by <a href='https://cadenhaustein.com' rel='dct:publisher'><span property='dct:title'>Caden Haustein</span></a>, is free of known Copyright restrictions.</p></main><script async src=\"/count.js\"></script></body></html>"
  let indexFile = dir / "index.html" 
  wrap: indexFile.writeFile s
  wrap:
    exec("/usr/local/bin/pandoc --wrap=auto --from=markdown+smart+auto_identifiers " & book.sourceFile & " --to=markdown+smart+auto_identifiers --output=output.md")
    mvFile("output.md", book.sourceFile)
  wrap:
    let contents = book.sourceFile.readFile
    book.hash = $contents.hash
    book.words = contents.countWords
  
func useCategory(builder: var BookBuilder, category: string): int {.raises: [].} =
  for (i, c) in enumerate(builder.categories):
    if c == category:
      return i
  builder.categories.add category
  return builder.categories.len - 1

proc ask(prompt: string): string {.raises: [BuilderError].} =
  var buffer = linenoise.readLine(prompt)
  if buffer.isNil:
    raise newException(BuilderError, "Linenoise returned nil")
  result = $buffer
  if result.len > 0:
    buffer.historyAdd
  linenoise.free(buffer)

proc add(builder: var BookBuilder, book: Book) {.raises: [BuilderError].} =
  var book: Book
  book.author = "Author: ".ask
  book.title = "Title: ".ask
  book.source = "Source: ".ask
  book.tag = "Tag: ".ask
  wrap: book.year = "Year: ".ask.parseInt
  book.category = builder.useCategory "Category: ".ask
  wrap: book.sourceFile.writeFile "\n"
  book.make
  builder.books.add book

proc init() {.raises: [BuilderError].} =
  var book: Book
  var builder = createBuilder()
  builder.add book
  builder.save

proc skipWhenAble(book: Book): bool {.raises: [].} =
  try:
    $book.sourceFile.readFile.hash == book.hash
  except Exception:
    false

proc neverSkip(_: Book): bool {.raises: [].} = false

proc make(canSkip: proc(book: Book): bool {.raises: [BuilderError].}) {.raises: [BuilderError].} =
  proc modifyBook(book: var Book) {.raises: [BuilderError].} =
    if book.canSkip:
      echo "Skipping: " & book.tag
    else:
      echo "Making: " & book.tag
      book.make

  wrap: "books".mkDir
  var builder = createBuilder()
  builder.books.apply(modifyBook)  
  builder.save
  let validFiles = builder.books.mapIt(it.tag)
  wrap:
    for dir in "books".listDirs.filterIt(it in validFiles):
      dir.rmDir

proc help() {.raises: [].} =
  echo "Usage:"
  echo "  bookbuilder init"
  echo "  bookbuilder make"

proc main(): int =
  result = QuitSuccess
  if paramCount() < 2: help()
  else:
    try:
      case paramStr(2):
      of "init": init()
      of "make": make(skipWhenAble)
      of "make-all": make(neverSkip)
      else: help()
    except BuilderError as e:
      echo "Error: " & e.msg
      return QuitFailure

when isMainModule:
  main().quit