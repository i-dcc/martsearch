
// emma-mice custom javascript

jQuery("#search_results .emma-strains-information-toggle").live("click", function () {
  jQuery( "#" + jQuery(this).attr("id").replace("toggle","content") ).toggle();
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
  return false;
});
