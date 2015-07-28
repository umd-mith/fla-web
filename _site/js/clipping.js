$(function() {

  var loc = window.location;
  var imageId = loc.href.match(/clippings\/(\d+)\//)[1]
  var manifestUri = 'http://mith-fla-tiles.s3.amazonaws.com/' + imageId + '/manifest.json';
  console.log(manifestUri);

  Mirador({
    "id": "viewer",
    "currentWorkspaceType": "singleObject",
    "data": [
      { 
        "manifestUri": manifestUri, 
        "location": "Foreign Literatures in America"
      }
    ],
    "windowObjects": [
      {
        "loadedManifest": manifestUri, 
        "viewType" : "ImageView", 
        "availableViews": ["ThumbnailView", "ImageView", "BookView"]
      }
    ]
  });
});
