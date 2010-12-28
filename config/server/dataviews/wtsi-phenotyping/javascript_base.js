
// wtsi-phenotyping custom javascript

jQuery(".wtsi-phenotyping table.wtsi-phenotyping_heatmap").delegate(
  'td.pheno_result',
  'mouseover',
  function(event) {
    jQuery(this).attr( "tooltip", jQuery(this).attr("title") );
    jQuery(this).attr( "title", "" );
    jQuery(this).qtip({
      content:   jQuery(this).attr("tooltip"),
      overwrite: false,
      style: {
        tip: false,
        classes: "ui-tooltip-light ui-tooltip-rounded ui-tooltip-shadow"
      },
      position: {
        at: "bottom center",
        my: "top center",
        adjust: {
           screen: true
        }
      },
      show: {
        event: event.type,
        ready: true
      }
    });
    event
  }
);
