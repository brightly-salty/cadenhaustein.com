#!/usr/bin/env nimcr

import os, osproc, rdstdin, times
import std/[algorithm, enumerate, exitProcs, marshal, json, sequtils, streams, strutils, sugar, terminal, with]

type BuilderError = object of CatchableError

type Book = object
  author: string 
  source: string
  tag: string
  title: string
  year: int
  lastWriteTime: string
  category: int

func `<`(x, y: Book): bool {.raises: [].} =
  if x.category != y.category: return x.category < y.category
  x.year > y.year
  
type BookBuilder = object
  books: seq[Book]
  categories: seq[string]

func sourceFile(book: Book): string {.raises: [].} =
  "src" / book.tag.addFileExt "md"

proc createBuilder(): BookBuilder {.raises: [BuilderError].} =
  try:
    let fileContents = "books.json".readFile
    to[BookBuilder](fileContents)
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

func addBook(builder: var BookBuilder, book: Book) {.raises: [].} =
  builder.books.add book

proc save(builder: var BookBuilder) {.raises: [BuilderError].} =
  try:
    builder.books.sort()
    "books.json".writeFile $$builder
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

proc executeCommand(command: string) {.raises: [BuilderError].} =
  var res: tuple[output: string, exitCode: int]
  try:
    res = execCmdEx(command)
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())
  if res.exitCode != 0: raise newException(BuilderError, "Command \n" & command & "\n exited with code " & $res.exitCode & " and output \n" & res.output)
  
proc make(book: var Book) {.raises: [BuilderError].}=
  let dir = "books" / book.tag
  let readDir = dir / "read"
  try:
    dir.createDir
    readDir.createDir
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())
  let indexFile = dir / "index.html" 
  let commonCommand = "/usr/local/bin/pandoc --wrap=auto --table-of-contents --standalone --reference-location=block --section-divs --from=markdown+smart+auto_identifiers --metadata=author:" & book.author.quoteShell & " --metadata=title:" & book.title.quoteShell & " --metadata=date:" & quoteShell($book.year) & " " & book.sourceFile.quoteShell
  let pdfFile = dir / book.tag.addFileExt("pdf")
  let htmlFile = readDir / "index.html"
  let epubFile = dir / book.tag.addFileExt("epub")
  let mobiFile = dir / book.tag.addFileExt("mobi")
  executeCommand(commonCommand & " --to=pdf --pdf-engine=xelatex --output=" & pdfFile)
  executeCommand(commonCommand & " --to=html --template=templates/pandoc.html --output=" & htmlFile)
  executeCommand(commonCommand & " --to=epub --template=templates/pandoc.epub --output=" & epubFile)
  executeCommand("/usr/local/bin/ebook-convert " & epubFile & " " & mobiFile)
  try:
    var s = indexFile.openFileStream fmWrite 
    with s:
      write "<!doctype html>"
      write "<head><meta charset='utf-8'><meta http-equiv='x-ua-compatible' content='ie=edge'><meta name='viewport' content='width=device-width, initial-scale=1'><link rel='stylesheet' href='../../styles/hakyll.css'/><title>"
      write book.title
      write "</title><meta name='author' content='"
      write book.author
      write "'></head>"
      write "<body>"
      write "<header><div class='logo'><a href='/'>Caden Haustein</a></div><nav><a href='/'>Home</a><a href='/about/'>About</a><a href='/blog/'>Blog</a></nav></header>"
      write "<main role='main'>"
      write "<h1>"
      write book.title
      write "</h1>"
      write "<p>Written by "
      write book.author
      write " in "
      write ($book.year)
      write "</p>"
      write "<p><a href='read/index.html'>Read it online</a></p>"
      write "<p><a href='"
      write book.tag
      write ".pdf'>Download a PDF</a></p>"
      write "<p><a href='"
      write book.tag
      write ".epub'>Download an EPUB</a></p>"
      write "<p><a href='"
      write book.tag
      write ".mobi'>Download a MOBI</a></p>"
    if book.source != "":
      with s:
        write "<br>"
        write "<p>Created from the page scans <a href='"
        write book.source
        write "'>here</a>."
    with s:
      write "<p xmlns:dct='http://purl.org/dc/terms/'><a rel='license' href='http://creativecommons.org/publicdomain/mark/1.0/'><img src='http://i.creativecommons.org/p/mark/1.0/88x31.png' style='border-style: none' alt='Public Domain Mark' /></a><br />This work (<span property='dct:title'>"
      write book.title
      write "</span>, by <span resource='[_:creator]' rel='dct:creator'><span property='dct:title'>"
      write book.author
      write "</span></span>), identified by <a href='https://cadenhaustein.com' rel='dct:publisher'><span property='dct:title'>Caden Haustein</span></a>, is free of known Copyright restrictions.</p>"
      write "</main>"
      write "</body>"
      write "</html>"
      close()
    book.lastWriteTime = $getTime()
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

func useCategory(builder: var BookBuilder, category: string): int {.raises: [].} =
  for (i, c) in enumerate(builder.categories):
    if c == category:
      return i
  builder.categories.add category
  return builder.categories.len - 1

proc add(builder: var BookBuilder, book: Book) {.raises: [BuilderError].} =
  try:
    var book: Book
    book.author = "Author:".readLineFromStdin
    book.source = "Source:".readLineFromStdin
    book.tag = "Tag:".readLineFromStdin
    book.title = "Title:".readLineFromStdin
    book.year = "Year:".readLineFromStdin.parseInt
    book.category = builder.useCategory "Category:".readLineFromStdin
    book.sourceFile.writeFile "\n"
    book.make
    builder.books.add book
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

proc init() {.raises: [BuilderError].} =
  var book: Book
  var builder = createBuilder()
  builder.add book
  builder.save

proc skipWhenAble(book: Book): bool =
  try:
    book.sourceFile.getFileInfo.lastWriteTime <= book.lastWriteTime.parseTime("yyyy-MM-dd'T'HH:mm:sszzz", utc()):
  except TimeParseError, OSError: false

proc neverSkip(_: Book): bool = false

proc make(canSkip: proc(book: Book): bool {.raises: [BuilderError].}) {.raises: [BuilderError].} =
  try:
    "books".createDir
  except Exception: raise newException(BuilderError, getCurrentExceptionMsg())
  
  var builder = createBuilder()

  proc modifyBook(book: var Book) {.raises: [BuilderError].} =
    if book.canSkip:
      echo "Skipping: " & book.tag
    else:
      echo "Making: " & book.tag
      book.make

  builder.books.apply(modifyBook)  
  builder.save
    
  let validFiles = collect(for book in builder.books: book.tag)
  var toDelete: seq[string]
  try:
    for file in "books".walkDir(relative = true):
      if file.path notIn validFiles: toDelete.add("books" / file.path)
  except Exception: raise newException(BuilderError, getCurrentExceptionMsg())
  for file in toDelete:
    try:
      file.removeFile
    except Exception: raise newException(BuilderError, getCurrentExceptionMsg())

proc help() {.raises: [].} =
  echo "Usage:"
  echo "  bookbuilder init"
  echo "  bookbuilder make"

proc main(): int =
  result = QuitSuccess
  let params = commandLineParams()
  if params.len == 0:
    help()
  else:
    case params[0]:
    of "init": 
      try:
        init()
      except BuilderError as e:
        echo "Error: " & e.msg
        return QuitFailure
    of "make":
      try:
        make(skipWhenAble)
      except BuilderError as e:
        echo "Error: " & e.msg
        return QuitFailure
    of "make-all":
      try:
        make(neverSkip)
      except BuilderError as e:
        echo "Error: " & e.msg
        return QuitFailure
    else:
      help()

when isMainModule:
  exitProcs.addExitProc resetAttributes
  main().quit