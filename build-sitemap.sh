#!/usr/bin/env bash 
set -e 

stack exec site build 

./echo-sitemap.sh > sitemap.txt

stack exec site build