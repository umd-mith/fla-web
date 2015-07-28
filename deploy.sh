#!/bin/sh

# build jekyll site and deploy to gh-pages

rm -rf _site
jekyll build
cd _site
git init
git config user.name "Ed Summers"
git config user.email "ehs@pobox.com"
git add .
git commit -m "Deploy to GitHub Pages"
git push --force "https://$GH_TOKEN@github.com/umd-mith/fla-web.git master:gh-pages"
