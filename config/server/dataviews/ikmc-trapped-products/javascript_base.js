
// ikmc-trapped-products custom javascript

jQuery("#search_results .ikmc-trapped-products div.unitraps_by div").hide();

jQuery("#search_results .ikmc-trapped-products a.unitraps_by_link").click( function() {
  var parent = jQuery(this).parentsUntil("div.dataset_content").last().parent();
  
  // Hide any existing tables...
  parent.find("div.unitraps_by div").slideUp("fast");
  
  // Show the one we want...
  parent.find("div.unitraps_by div." + jQuery(this).attr("rel")).slideDown("fast");
  
  return false;
});
