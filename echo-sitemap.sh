#!/usr/bin/env bash
set -e

ROOT_URL="https://cadenhaustein.com/"

echo $ROOT_URL

for page in docs/*/index.html; do
    page=${page#"docs/"}
    page=${page%"index.html"}
    echo $ROOT_URL"$page"
done

for page in docs/books/*/index.html; do
    page=${page#"docs/"}
    page=${page%"index.html"}
    echo $ROOT_URL"$page"
done

GLOBIGNORE="docs/books/*/index.html"
for page in docs/books/*/*.html; do
    page=${page#"docs/"}
    page=${page%".html"}
    echo $ROOT_URL"$page"
done
unset GLOBIGNORE