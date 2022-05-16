#!/bin/bash

rm -rf books

jq -c 'sort_by(.year, .author) | .' books.json > books.json~
mv books.json~ books.json 

LENGTH=$(jq length books.json)

for i in $(seq 0 $((LENGTH - 1)));
do 
  echo -ne "$i/$LENGTH\033[0K\r"
  ./make.sh "$i"
done