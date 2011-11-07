# encoding: utf-8

module MartSearch
  module DataSetUtils

    def eurexpress_sort_results( results )
      sorted_results = {}

      results.each do |result|
        joined_attribute      = result[ @config[:searching][:joined_attribute].to_sym ]
        ass_assay_id_key      = result[:ass_assay_id_key]

        result_data           = sorted_results[joined_attribute] ||= {}
        result_data_for_assay = result_data[ass_assay_id_key]    ||= {}

        result_data_for_assay[:assay_id]            = ass_assay_id_key
        result_data_for_assay[:assay_image_count]   = result[:assay_image_count]
        result_data_for_assay[:annotations]       ||= {}

        emap_id = result[:emap_id]
        emap_id = "EMAP:#{emap_id}" unless emap_id =~ /EMAP/

        result_data_for_assay[:annotations][emap_id.to_sym] = {
          :ann_pattern  => result[:ann_pattern],
          :ann_strength => result[:ann_strength]
        }

      end

      # Now sort the annotations into order of the ones with more
      # annotations at the top...
      results_to_return = {}

      sorted_results.each do |id,the_results|
        assays = []
        the_results.each do |assay_id,assay_data|
          assays.push(assay_data)
        end
        results_to_return[id] = assays.sort_by { |elm| -1*(elm[:annotations].size) }
      end

      return results_to_return
    end

  end
end
