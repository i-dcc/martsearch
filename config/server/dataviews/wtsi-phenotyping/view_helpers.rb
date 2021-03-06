require "#{File.expand_path(File.dirname(__FILE__))}/raw_data_sort"

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

def wtsi_phenotyping_fetch_mp_report_data( colony_prefix, mp_slug )
  ms = MartSearch::Controller.instance()
  
  cached_data = ms.fetch_from_cache("wtsi-pheno-mp-data:#{colony_prefix}")
  if cached_data.nil?
    ms.search("colony_prefix:#{colony_prefix}")
    cached_data = ms.fetch_from_cache("wtsi-pheno-mp-data:#{colony_prefix}")
  end
  
  if cached_data != nil
    mp_data = cached_data[:mp_groups][mp_slug.to_sym]
    cached_data.keys.each do |key|
      next if key == :mp_groups
      mp_data[key] = cached_data[key]
    end
    
    return mp_data
  else
    return nil
  end
end

def wtsi_phenotyping_fetch_raw_data( population_id, parameter_id )
  ms = MartSearch::Controller.instance()
  mart = ms.datasources[:"wtsi-phenotyping"].ds
  
  results = mart.search(
    :process_results => true,
    :attributes => [
      "published_graph_data_allele_name",
      "published_graph_data_pipeline",
      "published_graph_data_membership",
      "published_graph_data_mouse_name",
      "published_graph_data_gender",
      "published_graph_data_genotype",
      "published_graph_data_genotype_str",
      "published_graph_data_genetic_background",
      "published_graph_data_observation",
      "published_graph_data_x_value",
      "published_graph_data_y_value",
      "colony_prefix",
      "published_graph_data_parameter_id",
      "published_graph_data_population_id",
      "published_graph_data_graph_type"
    ],
    :required_attributes => [
      "colony_prefix",
      "published_graph_data_parameter_id",
      "published_graph_data_population_id",
      "published_graph_data_graph_type"
    ],
    :filters => {
      'population_id' => population_id,
      'parameter_id'  => parameter_id
    }
  )

  graph_type, sorted_results = RawDataSort.sort( results )
  
  return graph_type, sorted_results
end
