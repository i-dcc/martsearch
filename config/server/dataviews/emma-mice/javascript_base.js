
// emma-mice custom javascript

jQuery("#search_results tr.emma-strains-information-content").hide();
jQuery("#search_results .emma-strains-information-toggle").each( function () {
  jQuery(this).removeClass("toggle-open");
  jQuery(this).addClass("toggle-close");
});
