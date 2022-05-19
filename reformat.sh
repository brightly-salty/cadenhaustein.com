#!/bin/sh

pandoc -f markdown -t markdown --wrap=auto --columns=60 "$1" -o "$1.new"
mv "$1.new" "$1"
