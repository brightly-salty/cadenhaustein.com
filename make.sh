#!/bin/bash

AUTHOR=$(jq --raw-output ".[$1].author" books.json)
TITLE=$(jq --raw-output ".[$1].title" books.json)
YEAR=$(jq --raw-output ".[$1].year" books.json)
SOURCE=$(jq --raw-output ".[$1].source?" books.json)
TAG=$(jq --raw-output ".[$1].tag" books.json)
#votes=$(jq --raw-output ".[$1].votes" books.json)

source_file="src/$TAG.md"
output_dir="books/$TAG"
html_dir="read"

mkdir -p "$output_dir"
mkdir -p "$output_dir/$html_dir"

pdf_file="$TAG.pdf"
pandoc -M "author=$AUTHOR" -M "title=$TITLE" -M "date=$YEAR" -f markdown -t pdf --wrap=auto --toc -s --reference-location=block --pdf-engine=xelatex "$source_file" -o "$output_dir/$pdf_file"

html_file="index.html"
pandoc -M "author=$AUTHOR" -M "title=$TITLE" -M "date=$YEAR" -f markdown -t html --wrap=auto --toc -s --reference-location=block --template=templates/pandoc.html "$source_file" -o "$output_dir/$html_dir/$html_file" 

epub_file="$TAG.epub"
pandoc -M "author=$AUTHOR" -M "title=$TITLE" -M "date=$YEAR" -f markdown -t epub3 --wrap=auto --toc -s --reference-location=block --template=templates/pandoc.epub "$source_file" -o "$output_dir/$epub_file"  

mobi_file="$TAG.mobi"
ebook-convert "$output_dir/$epub_file" "$output_dir/$mobi_file" > /dev/null

index_file="$output_dir/index.html"
{
  echo "<!doctype html><head><meta charset='utf-8'><meta http-equiv='x-ua-compatibleo content='ie=edge'><meta name='viewport' content='width=device-width, initial-scale=1'><link rel='stylesheet' href='../../styles/hakyll.css'/><title>$TITLE</title><meta name='author' content='$AUTHOR'></head>"
  echo "<body><header><div class='logo'><a href='/'>Caden Haustein</a></div><nav><a href='/'>Home</a><a href='/about/'>About</a><a href='/blog/'>Blog</a></nav></header>"
  echo "<main role='main'><h1>$TITLE</h1>"
  echo "<p>Written by $AUTHOR in $YEAR</p>"
  echo "<p><a href=\"$html_dir/$html_file\">Read it online</a></p>"
  echo "<p><a href=\"$pdf_file\">Download a PDF version</a></p>"
  echo "<p><a href=\"$epub_file\">Download an EPUB version</a><p>"
  echo "<p><a href=\"$mobi_file\">Download a MOBI version</a></p>"
  if [ "$SOURCE" != "null" ]
  then
    echo "<br>"
    echo "<p>Created from the page scans <a href=\"$SOURCE\">here</a>." 
  fi
  echo "<p xmlns:dct='http://purl.org/dc/terms/''><a rel='license' href='http://creativecommons.org/publicdomain/mark/1.0/'><img src='http://i.creativecommons.org/p/mark/1.0/88x31.png' style='border-style: none' alt='Public Domain Mark' /></a><br />This work (<span property='dct:title'>$TITLE</span>, by <span resource='[_:creator]' rel='dct:creator'><span property='dct:title'>$AUTHOR</span></span>), identified by <a href='https://cadenhaustein.com' rel='dct:publisher'><span property='dct:title'>Caden Haustein</span></a>, is free of known copyright restrictions.</p>"
  echo "</main></body></html>"
} > "$index_file"

pandoc -f markdown -t markdown "$source_file" -o "$source_file.new"
mv "$source_file.new" "$source_file"
