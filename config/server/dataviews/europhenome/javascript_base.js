
// europhenome custom javascript

jQuery(".europhenome table.europhenome-data").delegate(
  "td[rel^='qtip']",
  'mouseover',
  function(event) {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
      content:   jQuery(this).attr("tooltip"),
      overwrite: false,
      style: {
        tip: false,
        classes: "ui-tooltip-light ui-tooltip-rounded ui-tooltip-shadow europhenome-tooltip"
      },
      position: {
        at: "bottom center",
        my: "top center",
        adjust: {
           screen: true
        }
      },
      hide: {
        fixed: true,
        event: "mouseout"
      },
      show: {
        event: event.type,
        ready: true
      }
    });
  },
  event
);

if ( !jQuery.browser.msie ) {
  jQuery(".csstransforms table.europhenome-data th .user_instructions").show();
  jQuery(".csstransforms table.europhenome-data th").css({ "height": "30px", "overflow": "hidden" });
  jQuery(".csstransforms table.europhenome-data th")
    .live( "mouseover", function() { jQuery(this).css({ "height": "188px" }); })
    .live( "mouseout", function()  { jQuery(this).css({ "height": "30px" });  });
}
