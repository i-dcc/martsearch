/*
* Use this script for .live() initialisation and other functions that are 
* best placed in the <head> of the html (for performance reasons).
*/

// Single parent togglers...
jQuery(".single_parent_toggler_toggle").live("click", function() {
  if ( jQuery(this).hasClass("slide") ) {
    jQuery(this).parent().find(".single_parent_toggler_content").slideToggle("fast");
  } else {
    jQuery(this).parent().find(".single_parent_toggler_content").toggle();
  }
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
  return false;
});

// Add an observer for all the returned dataset links - this 
// will make sure that the target elment for the link is visible.
jQuery("a.dataset_link_bubble").live("click", function () {
  var target_id = jQuery(this).attr("href");
  if ( jQuery(target_id).parent().is(":hidden") ) {
    jQuery(target_id).parent().show();
    jQuery(target_id).parent().parent().find(".doc_title").toggleClass("toggle-open");
    jQuery(target_id).parent().parent().find(".doc_title").toggleClass("toggle-close");
  }
  jQuery(this).qtip("hide");
  jQuery.scrollTo( target_id, { duration: 800 } );
  return false;
});

// Add the toggling observers for results...
jQuery(".dataset_title").live("click", function() {
  jQuery(this).parent().find(".dataset_content").slideToggle("fast");
  jQuery(this).parent().find(".attribution").toggle();
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});

// Documents
jQuery(".doc_title").live("click", function () {
  jQuery(this).parent().parent().parent().parent().parent().find(".doc_content").slideToggle("fast");
  jQuery(this).toggleClass("toggle-open");
  jQuery(this).toggleClass("toggle-close");
});

// Search explaination closers
jQuery(".search_explaination_close").live("click", function() {
  jQuery(".search_explaination").hide();
  return false;
});
