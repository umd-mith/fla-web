require 'json'
require 'jekyll'

module Clipping 

  class Generator < Jekyll::Generator

    def generate(site)
      coll = site.collections['clippings']
      new_files = []
      count = 0
      for clipping in site.collections['clippings'].docs
        count += 1
        break if count > 370
        new_files += process clipping
      end
      for file in new_files 
        coll.docs << Jekyll::Document.new(file, {site: site, collection: coll})
      end
    end

    def process(clipping)
      new_files = []
      manifest = make_manifest clipping
      clipping_dir = File.dirname clipping.path
      tiffs = Dir.entries(clipping_dir).select { |f| f[/^\d+.tif$/] }.sort()
      for tiff in tiffs
        canvas = make_canvas(File.join(clipping_dir, tiff), clipping.url)
        manifest[:sequences][0][:canvases] << canvas
      end

      manifest_file = File.join(File.dirname(clipping.path), 'manifest.json')
      File.open(manifest_file, 'w') do |f|
        f.write(JSON.pretty_generate(manifest))
      end

      clipping.data['javascript'] = [
        '/js/clipping.js',
        '/mirador/mirador.js'
      ]
      clipping.data['css'] = [
        '/mirador/css/mirador-combined.css'
      ]

      return new_files
    end

    def make_manifest(clipping)
      puts "generating manifest for #{clipping.path}"
      manifest_uri = clipping.url.sub('index.html', 'manifest.json')
      manifest = {
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": manifest_uri,
        "@type": "sc:Manifest",
        "label": "#{clipping.data['title']}",
        "attribution": "Foreign Literatures in America",
        "sequences": [
          {
            "@id": "normal",
            "@type": "sc:Sequence",
            "label":  "page order",
            "canvases": []
          }
        ]
      }

      return manifest
    end

    def make_canvas(tiff, clipping_url)
      # only generate tiles if they're not there already
      tile_dir = tiff.sub('.tif', '')
      tiff_rgba = tiff.sub '.tif', '-rgba.tif'
      if not Dir.exists? tile_dir or File.exists? tiff_rgba
        puts "creating tiles for #{tiff}"
        `tiff2rgba #{tiff} #{tiff_rgba}`
        `iiif_static.py --api-version=2.0 --dst #{tile_dir} --tilesize 1024 #{tiff_rgba}`
        File.delete tiff_rgba
      end

      # read in info.json that was just generated for dimensions
      info_file = File.join(tile_dir, 'info.json')
      info = JSON.parse(File.read(info_file))

      # determine some relative urls
      canvas_url = File.dirname(clipping_url)
      tiff_url = File.join(canvas_url, File.basename(tiff))
      img_seq = File.basename(tiff).sub('.tif', '')
      service_url = File.join(canvas_url, img_seq)
      image_url = File.join(canvas_url, img_seq)
      thumbnail_url = get_thumbnail(tile_dir)

      canvas = {
        "@id": image_url,
        "@type": "sc:Canvas",
        "label": "image %i" % img_seq.to_i,
        "height": info["height"],
        "width": info["width"],
        "thumbnail": thumbnail_url,
        "images": [
          {
            "@id": image_url,
            "@type": "oa:Annotation",
            "motivation": "sc:painting",
            "resource": {
              "@id": tiff_url,
              "@type": "dctypes:Image",
              "format": "image/jpeg",
              "service": {
                "@id": service_url,
                "@context": "http://iiif.io/api/image/2/context.json",
                "profile": "http://iiif.io/api/image/2/level0.json"
              },
              "height": info['height'],
              "width": info['width']
            }
          }
        ]
      }

      return canvas
    end

    def get_thumbnail(tile_dir)
      full_dir = File.join(tile_dir, "full")
      full_url = File.join(File.basename(tile_dir), "full")

      # get largest full image for thumbnail w/ width < 200 
      thumb_w = nil
      for dir in Dir.entries(full_dir) 
        next if dir !~ /,$/
        w = dir.to_i
        if ! thumb_w or (w > thumb_w and w < 200)
          thumb_w = w
        end
      end
      thumbnail_url = File.join(full_url, '%s,' % thumb_w, '0', 'default.jpg')

      return thumbnail_url
    end
  end
end
