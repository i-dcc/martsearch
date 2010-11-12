/*
* Use this script for all javascript code that needs to go 
* in the base of the html.
*/

jQuery(document).ready(function() {
  setup_toggles();
  check_browser_compatibility();
  
  // Add tooltips for the returned dataset links.
  jQuery(".dataset_link_bubble").each( function() {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
      content:  jQuery(this).attr("tooltip"),
      style:    { tip: "topRight", border: { radius: 5 }, name: "light" },
      position: { corner: { target: "bottomLeft", tooltip: "topRight" } }
    });
  });
  
  // Add prettyPhoto to anything with the property 'rel="prettyPhoto"'
  jQuery("a[rel^='prettyPhoto']").prettyPhoto({ theme: 'facebook', show_title: false });
  
  // Add tablesorter to anything with the class 'tablesorter'
  jQuery("table.tablesorter").tablesorter({ widgets: ['zebra'], dateFormat: "uk" });
  
  // Add the accordion effect to anything with the class 'accordion'
  jQuery(".accordion").accordion({
    collapsible: true,
    active:      false,
    autoHeight:  false,
    icons: {
      header: "ui-icon-circle-arrow-e",
      headerSelected: "ui-icon-circle-arrow-s"
    }
  });
  
  // For 'active' accordions - open the first element
  jQuery(".accordion.active").each( function() {
    jQuery(this).accordion( "activate", 0 );
  });
  
  // Add font resizing buttons
  jQuery("#fontresize").fontResize();
});


function setup_toggles() {
  // Single parent togglers...
  jQuery(".single_parent_toggler_content").hide();
  jQuery(".single_parent_toggler_toggle").removeClass("toggle-open");
  jQuery(".single_parent_toggler_toggle").addClass("toggle-close");
  
  // Add Toggling for search explainations
  jQuery("#search_explaination_toggle").click( function() {
      jQuery(".search_explaination").slideToggle("fast");
      return false;
  });
}

/*
* Check browser versions - so we can warn users of older browsers, 
* and switch off some advanced CSS3 features...
*/
function check_browser_compatibility() {
  var show_warning   = false;
  var warning_string = 
    "<strong>WARNING:</strong> It appears that your browser does not " + 
    "support some of the features needed by this site to work perfectly. " + 
    "Please consider upgrading or changing your browser for a better " + 
    "browsing experience."; 
  
  if ( !Modernizr.csstransforms ) {
    if ( jQuery.browser.msie ) {
      // IE is cool here (somewhat) - leave it alone!
    }
    else {
      show_warning = true;
      jQuery(".csstransforms_warning").show();
      jQuery(".vertical_text").toggleClass("vertical_text");
    }
  }
  
  if ( show_warning ) {
    jQuery("#browser_warnings").html( warning_string );
    jQuery("#browser_warnings").show();
  }
}
