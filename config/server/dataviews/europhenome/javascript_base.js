
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
        tip: "topMiddle",
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
    event
  }
);
