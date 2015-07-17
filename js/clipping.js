$(function() {

  manifestUri = window.location.pathname.replace(/(index.html|#.+)/, '');
  manifestUri += 'manifest.json'
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
      }
    ]
  });
});
