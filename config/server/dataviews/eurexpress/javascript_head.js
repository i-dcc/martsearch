
// eurexpress custom javascript

jQuery("a.eurexpress_assay_ontology_open").live( "click", function() {
  jQuery(this).parent().find(".eurexpress_assay_ontology").jstree("open_all");
  return false;
});

jQuery("a.eurexpress_assay_ontology_close").live( "click", function() {
  jQuery(this).parent().find(".eurexpress_assay_ontology").jstree("close_all");
  return false;
});
