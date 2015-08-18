$(function() {
  var grid = $(".grid").masonry({
    itemSelector: ".grid-item",
    columnWidth: 210,
    isFitWidth: true
  });
  grid.imagesLoaded().progress(function() {
    grid.masonry('layout');
  });
});
