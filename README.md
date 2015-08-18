[![Build Status](https://travis-ci.org/umd-mith/fla-web.svg)](http://travis-ci.org/umd-mith/fla-web)

This a Jekyll static website for the [Foreign Literatures in America](http://mith.umd.edu/research/project/fla/) project. As their name implies static sites are designed to change infrequently. The advantage is that since they are simply static files being served up on the Web they don't require running software on a server, and thus require very little maintenance. The downside is that adding content can be a bit more involved.

### Build the Site

In order to change the structure of the pages, or some of their content 
you will need to use Jekyll to build the static site. We have a Travis-CI
automated build job configured to watch for changes to the fla-web GitHub
project, and automatically build/deploy the new content. The process should take
about 30 seconds or so.

However, if you want to build the website locally on you workstation you will
need to follow these instructions to get Jekyll properly installed:

1. `git clone https://github.com/umd-mith/fla-web`
1. [install ruby](https://www.ruby-lang.org/en/)
1. [install rvm](https://rvm.io/rvm/install)
1. `rvm gemset create fla`
1. `rvm use ruby-2.2.2@fla`
1. `gem install bundler`
1.  jekyll build

After you have run `build` you should see a `_site` directory which has 
the full content of the static site.

### Add Content

In order to add a new *clipping* to the website you need to build the website 
locally on your workstation in order to add the images and create the image
tiles used by the Mirador viewer. First get the images: 

    mkdir _tiles
    aws s3 sync s3://mith-fla-tiles/ _tiles

Then add the metadata for a clippping by creating a file that has frontmatter 
resembling another clipping:

    _clippings/02123/index.html

Next add your TIFF file(s) for the scans you have to the appropriate directory 
in _tiles:

    _tiles/02123/001.tif
    _tiles/02123/002.tif
    _tiles/02123/003.tif

You need to run the jekyll build process again, but first you will need
to make sure that the iiif utility is available in order to create the tiles
used by the viewer. It's a Python utility so we need to get Python, and make 
sure the tiff processing library is available, and then install:

    sudo apt-get install python libtiff-tools
    sudo pip install git+https://github.com/edsu/iiif.git@fix-off-by-one-sizes

Now (finally) we are ready to build again:

    jekyll build

After the tiles have been created for your new clipping you need to sync them
back to Amazon S3 so that they are available for the live website:

    aws s3 sync _tiles s3://mith-fla-tiles

Last but not least commit and push the _clipping to github:

    git add _clippings/02123
    git commit -m 'new clipping!' -a
    git push

That's it, whew!
