
// Eurexpress custom javascript

// jQuery("#search_results .eurexpress-accordion").accordion({
//   collapsible: true,
//   active:      false,
//   autoHeight:  false,
//   icons: {
//     header: "ui-icon-circle-arrow-e",
//     headerSelected: "ui-icon-circle-arrow-s"
//   },
//   change: function(event, ui) {
//     jQuery(ui.newContent).find('table.tree').each( function() {
//       if ( !jQuery(this).hasClass('treeTable') ) {
//         jQuery(this).treeTable({
//           clickableNodeNames: true,
//           expandable: true,
//           initialState: 'expanded'
//         });
//       }
//     });
//   }
// });

jQuery.jstree._themes = "css/jstree/"
jQuery(document).ready(function() {
  
  jQuery(".eurexpress_assay_ontology").each( function() {
    var id_arg = jQuery(this).attr('id');

    jQuery("#"+id_arg).jstree({
      "json_data": {
        "ajax": {
          "url": "http://localhost:3000/eurexpress_browse",
          "data": function (n) {
            return { id : n.attr ? n.attr("id") : id_arg };
          }
        }
      },
      "themes": {
        "theme": "classic",
        "dots": true,
        "icons": true
      },
      "types": {
        "valid_children": ["default"],
        "types": {
          "default": {
            "valid_children": [ "default", "leaf_node" ]
          },
          "leaf_node": {
            "icon": { "image": "http://localhost:3000/images/silk/page_white.png" },
            "valid_children": "none",
            "hover_node": false
          }
        }
      },
      "progressive_render": true,
      "plugins": [ "json_data", "themes", "types", "ui" ]
    });
    
  });
  
});

jQuery("a.eurexpress_assay_ontology_expand").live( "click", function() {
  jQuery(this).parent().find(".eurexpress_assay_ontology").jstree("open_all");
  return false;
});

jQuery("a.eurexpress_assay_ontology_close").live( "click", function() {
  jQuery(this).parent().find(".eurexpress_assay_ontology").jstree("close_all");
  return false;
});
