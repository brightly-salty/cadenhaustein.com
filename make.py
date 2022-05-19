#! /usr/bin/env python3

import os, subprocess, json, shutil
from subprocess import DEVNULL
from tqdm import tqdm


def make_pandoc_args(book):
    return [
        "/usr/local/bin/pandoc",
        "--wrap=auto",
        "--table-of-contents",
        "--standalone",
        "--reference-location=block",
        "--section-divs",
        "--from=markdown+smart+auto_identifiers",
        "--metadata=author:" + book["author"],
        "--metadata=title:" + book["title"],
        "--metadata=date:" + str(book["year"]),
        "src/" + book["tag"] + ".md",
    ]


def make_pdf(book):
    subprocess.run(
        make_pandoc_args(book)
        + [
            "--to=pdf",
            "--pdf-engine=xelatex",
            "--output=books/" + book["tag"] + "/" + book["tag"] + ".pdf",
        ],
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
    )


def make_html(book):
    subprocess.run(
        make_pandoc_args(book)
        + [
            "-t",
            "html",
            "--template=templates/pandoc.html",
            "-o",
            "books/" + book["tag"] +  "/read/index.html",
        ],
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
    )


def make_epub(book):
    subprocess.run(
        make_pandoc_args(book)
        + [
            "-t",
            "epub",
            "--template=templates/pandoc.epub",
            "-o",
            "books/" + book["tag"] + "/" + book["tag"] + ".epub",
        ],
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
    )


def make_mobi(book):
    subprocess.run(
        [
            "/usr/local/bin/ebook-convert",
            "books/" + book["tag"] + "/" + book["tag"] + ".epub",
            "books/" + book["tag"] + "/" + book["tag"] + ".mobi",
        ],
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
    )


def make_index(book):
    f = open("books/" + book["tag"] + "/index.html", "w")
    f.write(
        "<!doctype html><head><meta charset='utf-8'><meta http-equiv='x-ua-compatibleo content='ie=edge'><meta name='viewport' content='width=device-width, initial-scale=1'><link rel='stylesheet' href='../../styles/hakyll.css'/><title>"
        + book["title"]
        + "</title><meta name='author' content='"
        + book["author"]
        + "'></head>",
    )
    f.write(
        "<body><header><div class='logo'><a href='/'>Caden Haustein</a></div><nav><a href='/'>Home</a><a href='/about/'>About</a><a href='/blog/'>Blog</a></nav></header>"
    )
    f.write("<main role='main'><h1>" + book["title"] + "</h1>")
    f.write("<p>Written by " + book["author"] + " in " + str(book["year"]) + "</p>")
    f.write("<p><a href='read/index.html'>Read it online</a></p>")
    f.write("<p><a href='" + book["tag"] + ".pdf'>Download a PDF</a></p>")
    f.write("<p><a href='" + book["tag"] + ".epub'>Download an EPUB</a></p>")
    f.write("<p><a href='" + book["tag"] + ".mobi'>Download a MOBI</a></p>")
    if not (book["source"] is None):
        f.write(
            "<br><p>Created from the page scans <a href='"
            + book["source"]
            + "'>here</a>."
        )
    f.write(
        "<p xmlns:dct='http://purl.org/dc/terms/''><a rel='license' href='http://creativecommons.org/publicdomain/mark/1.0/'><img src='http://i.creativecommons.org/p/mark/1.0/88x31.png' style='border-style: none' alt='Public Domain Mark' /></a><br />This work (<span property='dct:title'>"
        + book["title"]
        + "</span>, by <span resource='[_:creator]' rel='dct:creator'><span property='dct:title'>"
        + book["author"]
        + "</span></span>), identified by <a href='https://cadenhaustein.com' rel='dct:publisher'><span property='dct:title'>Caden Haustein</span></a>, is free of known Copyright restrictions.</p>"
    )
    f.write("</main></body></html>")
    f.close()


def main():
    if os.path.isdir("books"):
        shutil.rmtree("books")

    with open("books.json", "r+") as f:
        data = f.read()
        books = json.loads(data)
        books.sort(key=lambda x: x["year"]);
        f.seek(0)
        f.write(json.dumps(books, separators=(',',':'), sort_keys=True))
        f.truncate()

        for book in tqdm(books):
            os.makedirs("books/" + book["tag"], exist_ok=True)
            os.makedirs("books/" + book["tag"] + "/read", exist_ok=True)

            make_pdf(book)
            make_epub(book)
            make_mobi(book)
            make_html(book)

            make_index(book)
            subprocess.run(["./reformat.sh", "src/" + book["tag"] + ".md"])


if __name__ == "__main__":
    main()
