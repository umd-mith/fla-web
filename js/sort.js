$(function() {
  var items = $('.sortable li').get();
  items.sort(function(a, b) {
    var keyA = $(a).text();
    var keyB = $(b).text();

    if (keyA < keyB) return -1;
    if (keyA > keyB) return 1;
    return 0; 
  });

  var ul = $('.sortable');
  $.each(items, function(i, li) {
    ul.append(li);
  });
});
