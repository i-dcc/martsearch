
# Template helper function to map the status descriptions retrived from MIG into 
# a CSS class that is used to draw the heat map
def wtsi_phenotyping_css_class_for_test(status_desc)
  case status_desc
  when "Test complete and data\/resources available"  then "completed_data_available"
  when "Test complete and considered interesting"     then "significant_difference"
  when "Test complete but not considered interesting" then "no_significant_difference"
  when "Early indication of possible phenotype"       then "early_indication_of_possible_phenotype"
  when /^Test not performed or applicable/i           then "not_applicable"
  when "Test abandoned"                               then "test_abandoned"
  else                                                     "test_pending"
  end
end