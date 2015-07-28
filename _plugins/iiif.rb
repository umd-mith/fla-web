require 'json'
require 'jekyll'

module IIIF

  class Manifest

    # Pass in a Jekyll::Page for a clipping to generate. The Jekyll hooks
    # registered below will take care of this for all clippings, to make
    # sure that they all have IIIF manifests and image tiles.

    def initialize(clipping)
      @clipping = clipping
      @clipping_id = File.basename(File.dirname(clipping.path))
      @clipping_url = File.join clipping.site.config['url'], clipping.site.config['baseurl'], @clipping_id
      @clipping_dir = File.dirname clipping.path
      @tiles_dir = File.join clipping.site.source, '_tiles', @clipping_id
      @tiles_url = File.join clipping.site.config['tiles_url'], @clipping_id
      @manifest_file = File.join @tiles_dir, 'manifest.json'
    end

    def generate
      json_data = make_manifest

      tiffs = Dir.entries(@tiles_dir).select { |f| f[/^\d+.tif$/] }.sort()
      if tiffs.length == 0
        return
      end 

      for tiff in tiffs
        canvas = make_canvas(File.join(@tiles_dir, tiff))
        json_data[:sequences][0][:canvases] << canvas
      end

      File.open(@manifest_file, 'w') do |f|
        f.write(JSON.pretty_generate(json_data))
      end
    end

    def make_manifest
      puts "iiif: generating manifest for #{@clipping.path}"
      manifest_uri = File.join @tiles_url, 'manifest.json'
      manifest = {
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": manifest_uri,
        "@type": "sc:Manifest",
        "label": "#{@clipping.data['title']}",
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

    def make_canvas(tiff)
      img_seq = File.basename(tiff).sub('.tif', '')
      img_tiles_dir = File.join(@tiles_dir, img_seq)
      info_file = File.join(img_tiles_dir, 'info.json')

      # only generate tiles if they're not there already
      tiff_rgba = tiff.sub '.tif', '-rgba.tif'
      if not File.exists? info_file or File.exists? tiff_rgba
        FileUtils::mkdir_p img_tiles_dir
        puts "iiif: creating tiles for #{tiff}"
        `tiff2rgba #{tiff} #{tiff_rgba}`
        `iiif_static.py --api-version=2.0 --dst #{img_tiles_dir} --tilesize 1024 #{tiff_rgba}`
        File.delete tiff_rgba
      end

      # read in info.json that was just generated for dimensions
      info = JSON.parse(File.read(info_file))

      # determine some urls
      canvas_url = @clipping_url
      tiff_url = File.join canvas_url, File.basename(tiff)
      service_url = File.join @tiles_url, img_seq
      image_url = "#{canvas_url}-#{img_seq}"
      thumbnail_url = File.join service_url, get_thumbnail(img_tiles_dir)

      # update image info with full URL
      info['@id'] = service_url
      File.open(info_file, 'w') do |f|
        f.write(JSON.pretty_generate(info))
      end

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

    def get_thumbnail(img_tiles_dir)
      full_dir = File.join(img_tiles_dir, "full")

      # get full image with largest width
      thumb_w = nil
      for dir in Dir.entries(full_dir) 
        next if dir !~ /,$/
        w = dir.to_i
        if ! thumb_w or w > thumb_w
          thumb_w = w
        end
      end

      return File.join('full/%s,' % thumb_w, '0', 'default.jpg')
    end
  end

end

Jekyll::Hooks.register :site, :pre_render do |site|
  puts "iiif: generating manifests/tiles"
  for clipping in site.collections['clippings'].docs
    manifest = IIIF::Manifest.new(clipping)
    manifest.generate
  end
end
