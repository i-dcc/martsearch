
# Template helper function to map the status descriptions retrived from MIG into 
# a CSS class that is used to draw the heat map.
#
# @param [String] status_desc The long status description (supplied by MIG)
# @return [String] The short css class for this test result
def wtsi_phenotyping_css_class_for_test(status_desc)
  case status_desc
  when "Complete and data/resources available"  then "completed_data_available"
  when "CompleteDataAvailable"                  then "completed_data_available"
  when "Significant"                            then "significant_difference"
  when "CompleteInteresting"                    then "significant_difference"
  when "Not Significant"                        then "no_significant_difference"
  when "CompleteNotInteresting"                 then "no_significant_difference"
  when "Early indication of possible phenotype" then "early_indication_of_possible_phenotype"
  when "EarlyIndicator"                         then "early_indication_of_possible_phenotype"
  when "Not performed or applicable"            then "not_applicable"
  when "NotPerformedApplicable"                 then "not_applicable"
  when "Abandoned"                              then "test_abandoned"
  else                                               "test_pending"
  end
end

# Helper function to fetch report data (for the pheno report pages) out 
# of the cache.
#
# @param [String] colony_prefix The WTSI colony_prefix to look up
# @param [String] pheno_test The phenotyping test to look for report data on
# @return [Object] Either an Array or Hash of data ready for the template
def wtsi_phenotyping_fetch_report_data( colony_prefix, pheno_test )
  ms = MartSearch::Controller.instance()
  
  cached_data = ms.fetch_from_cache("wtsi-pheno-data:#{colony_prefix}")
  if cached_data.nil?
    ms.search("colony_prefix:#{colony_prefix}")
    cached_data = ms.fetch_from_cache("wtsi-pheno-data:#{colony_prefix}")
  end
  
  if cached_data != nil
    return cached_data[ "#{pheno_test}_data".to_sym ]
  else
    return nil
  end
end