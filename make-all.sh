#!/bin/bash

rm -rf books

for i in $(seq 0 $(($(jq 'length' books.json) - 1)));
do 
  ./make.sh "$i"
done