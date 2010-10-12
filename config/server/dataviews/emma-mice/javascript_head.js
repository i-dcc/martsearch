
// emma-mice custom javascript

jQuery("#search_results .emma-strains-information-toggle").live("click", function () {
  jQuery(this).parent().parent().next("tr.emma-strains-information-content").toggle();
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
  return false;
});
