require 'vips'
require 'jekyll'
require 'tesseract'

#
# sudo apt-get install libleptonica-dev libtesseract-dev
# gem install tesseract-ocr
# 
# sudo apt-get install libvips-dev
# gem install ruby-vips
#

module Clipping 

  class Generator < Jekyll::Generator

    def generate(site)
      coll = site.collections['clippings']
      new_files = []
      for clipping in site.collections['clippings'].docs
        new_files += process clipping
        break
      end
      for file in new_files 
        coll.docs << Jekyll::Document.new(file, {site: site, collection: coll})
      end
    end

    def process(clipping)
      #has_ocr = clipping.data.has_key? "ocr"
      clipping_dir = File.dirname(clipping.path)
      new_files = []
      Dir.foreach(clipping_dir) do |filename|
        next if File.extname(filename) != '.tif'
        tiff = File.join(clipping_dir, filename)
        new_files += make_pngs tiff
      end
      return new_files
    end

    def make_pngs(tiff)
      new_files = []
      image = VIPS::Image.new(tiff)

      png = tiff.sub '.tif', '.png'
      if not File.exist? png
        image.write png
        new_files << png
        puts "generated #{png} from #{tiff}"
      end

      thumb = tiff.sub '.tif', '-thumb.png'
      if not File.exist? thumb
        shrink = [image.x_size, image.y_size].max / 250
        image.shrink(shrink).write(thumb)
        new_files << thumb
        puts "generated #{thumb} from #{tiff}"
      end
      return new_files
    end

  end
end

"""
Notes for OCR generation...

tiff = '/data/fla/data/_clippings/01323/001.tif'

e = Tesseract::Engine.new {|e|
  e.language = :eng
  e.blacklist = '|'
}

puts e.text_for(tiff).strip
"""
