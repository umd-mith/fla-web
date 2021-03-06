#!/bin/sh

# build jekyll site and deploy to gh-pages

rm -rf _site
jekyll build --safe
cd _site
echo "www.flaproject.com" > CNAME
touch .nojekyll
git init
git config user.name "Ed Summers"
git config user.email "ehs@pobox.com"
git remote add origin "https://$GH_TOKEN@github.com/umd-mith/fla-web.git"
git checkout -b gh-pages
git add .
git commit -m "Deploy to GitHub Pages"
git push --force --quiet origin gh-pages
