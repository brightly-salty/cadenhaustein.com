#!/usr/bin/env nimcr

import os, osproc, rdstdin, times
import std/[algorithm, enumerate, exitProcs, marshal, json, streams, strutils, terminal, with]

type BuilderError = object of CatchableError

type Book = object
  author: string 
  source: string
  tag: string
  title: string
  year: int
  lastWriteTime: string

func `<`(x, y: Book): bool {.raises: [].} =
  return x.year < y.year
  
type BookBuilder = object
  books: seq[Book]

func sourceFile(book: Book): string {.raises: [].} =
  "src" / book.tag.addFileExt "md"

proc makeBookBuilder(): BookBuilder {.raises: [BuilderError].} =
  try:
    let fileContents = "books.json".readFile
    BookBuilder(books: to[seq[Book]](fileContents))
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

func addBook(builder: var BookBuilder, book: Book) {.raises: [].} =
  builder.books.add book

proc save(builder: BookBuilder) {.raises: [BuilderError].} =
  try:
    let fileContents = $$builder.books.sorted
    "books.json".writeFile fileContents
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

proc executeCommand(command: string) {.raises: [BuilderError].} =
  var res: tuple[output: string, exitCode: int]
  try:
    res = execCmdEx(command)
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())
  if res.exitCode != 0: raise newException(BuilderError, "Command \n" & command & "\n exited with code " & $res.exitCode & " and output \n" & res.output)
  
proc make(book: var Book): int {.raises: [BuilderError].}=
  result = QuitFailure
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
  return QuitSuccess

proc askAuthor(): string {.raises: [IOError].} =
  "Author:".readLineFromStdin

proc askSource(): string {.raises: [IOError].} =
  "Source:".readLineFromStdin

proc askTag(): string {.raises: [IOError].} =
  "Tag:".readLineFromStdin

proc askTitle(): string {.raises: [IOError].} =
  "Title:".readLineFromStdin

proc askYear(): int {.raises: [IOError, ValueError].} =
  "Year:".readLineFromStdin.parseInt

proc initialize(book: var Book) {.raises: [BuilderError].} =
  try:
    book.author = askAuthor()
    book.source = askSource()
    book.tag = askTag()
    book.title = askTitle()
    book.year = askYear()
    book.sourceFile.writeFile "\n"
    discard book.make
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())

proc init(): int {.raises: [BuilderError].} =
  result = QuitFailure
  var book: Book
  book.initialize
  var builder = makeBookBuilder()
  builder.addBook book
  builder.save
  return QuitSuccess

proc makeAll(): int {.raises: [BuilderError].} =
  result = QuitFailure
  try:
    "books".createDir
  except Exception:
    raise newException(BuilderError, getCurrentExceptionMsg())
  var builder = makeBookBuilder()
  var newBuilder = BookBuilder(books: @[])
  for (i, book) in enumerate(builder.books):
    let canSkip =
      try:
        book.sourceFile.getFileInfo.lastWriteTime <= book.lastWriteTime.parseTime("yyyy-MM-dd'T'HH:mm:sszzz", utc()):
      except TimeParseError, OSError: false
    var newBook = 
      if canSkip:
        echo "Skipping: " & book.tag
        book
      else:
        echo "Making: " & book.tag
        var newBook = book
        if newBook.make != QuitSuccess: return
        newBook
    newBuilder.addBook newBook
  newBuilder.save
  return QuitSuccess

proc help(): int {.raises: [].} =
  echo "Usage:"
  echo "  bookbuilder init"
  echo "  bookbuilder make"
  return QuitSuccess

proc main(): int =
  let params = commandLineParams()
  return
    if params.len == 0: help()
    else:
      case params[0]:
      of "init": 
        init()
      of "make":
        makeAll()
      else: help()

when isMainModule:
  exitProcs.addExitProc resetAttributes
  main().quit