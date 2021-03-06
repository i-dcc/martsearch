
// eurexpress custom javascript

jQuery(".eurexpress_assay_ontology").each( function() {
  var id_arg = jQuery(this).attr('id');

  jQuery("#"+id_arg).jstree({
    core: {
      html_titles: true
    },
    json_data: {
      ajax: {
        url: martsearch_url + "/eurexpress_emap",
        data: function (n) {
          return { id : n.attr ? n.attr("id") : id_arg };
        }
      }
    },
    themes: {
      theme: "classic",
      dots: true,
      icons: true
    },
    types: {
      valid_children: ["default"],
      types: {
        "default": {
          valid_children: [ "default", "leaf_node" ]
        },
        "leaf_node": {
          icon: { image: martsearch_url + "/images/silk/page_white.png" },
          valid_children: "none",
          hover_node: false
        }
      }
    },
    progressive_render: true,
    plugins: [ "json_data", "themes", "types" ]
  });
});
