
// emma-mice custom javascript

jQuery("#search_results .emma-strains-information-toggle").each( function (index) {
  jQuery( "#" + jQuery(this).attr("id").replace("toggle","content") ).hide();
  jQuery(this).removeClass("toggle-open");
  jQuery(this).addClass("toggle-close");
});
