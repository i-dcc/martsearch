
// ikmc-unitrap custom javascript

jQuery(document).ready(function() {
  jQuery(".ikmc-trapped-products div.unitraps_by div").hide();
  
  jQuery(".ikmc-trapped-products a.unitraps_by_link").click( function() {
    var parent = jQuery(this).parentsUntil("div.dataset_content").last().parent();
    
    // Hide any existing tables...
    parent.find("div.unitraps_by div").slideUp("fast");
    
    // Show the one we want...
    parent.find("div.unitraps_by div." + jQuery(this).attr("rel")).slideDown("fast");
    
    return false;
  });
  
  // Temp Add-in for viv...
  jQuery(".ikmc-trapped-products").hide();
  var header = jQuery(".ikmc-trapped-products").parent().find(".dataset_title");
  header.removeClass("toggle-open");
  header.addClass("toggle-close");
});
