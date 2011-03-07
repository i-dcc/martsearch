
// ikmc-mice custom javascript

jQuery("#search_results .mice_qc_details_toggle").live("click", function () {
  jQuery(this).parent().parent().next("tr.mice_qc_details").toggle();
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});
