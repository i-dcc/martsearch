
// gene-details custom javascript

jQuery("a.go_ontology_tree_open").live( "click", function() {
  jQuery(this).parent().find(".go_ontology_tree").jstree("open_all");
  return false;
});

jQuery("a.go_ontology_tree_close").live( "click", function() {
  jQuery(this).parent().find(".go_ontology_tree").jstree("close_all");
  return false;
});
