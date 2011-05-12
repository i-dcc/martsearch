module MartSearch
  module DataSetUtils
    
    def europhenome_sort_results( results )
      sorted_results                  = {}
      europhenome_significance_cutoff = 0.0001
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        if sorted_results[ result[ joined_attribute ] ].nil?
          sorted_results[ result[ joined_attribute ] ] = {}
        end
        
        ##
        ## First, set up a holder for a test_id/zygosity group
        ##
        
        het_hom = case result[:zygosity].to_s
          when '1' then 'Hom'
          when '0' then 'Het'
        end
        
        result_data = sorted_results[ result[ joined_attribute ] ][ "#{result[:europhenome_id]}-#{het_hom}" ]
        if result_data.nil?
          result_data = {
            :europhenome_id => result[:europhenome_id],
            :line_name      => result[:line_name],
            :zygosity       => het_hom,
            :allele_id      => result[:allele_id],
            :allele_name    => result[:allele_name],
            :emma_id        => result[:emma_id],
            :escell_clone   => result[:escell_clone],
            :stocklist_id   => result[:stocklist_id],
            :mp_groups      => {} 
          }
        end
        
        ##
        ## Now process and store the individual results data...
        ##
        
        parameter_eslim_id = result[:parameter_eslim_id]
        test_eslim_id      = nil
        
        unless parameter_eslim_id.nil?
          test_eslim_id = parameter_eslim_id[ 0, ( parameter_eslim_id.size - 4 ) ]
        end
        
        # First, determine which MP group (top-level term) it belongs to
        mp_group = nil
        @config[:mp_heatmap_config].each do |mp_conf|
          next unless mp_group.nil?
          
          if result[:mp_term]
            # Can we test by MP term?
            mp_group = mp_conf[:term] if mp_conf[:child_terms].include?( result[:mp_term] )
          else
            # No MP term - try to match via ESLIM ID's
            if test_eslim_id != nil
              mp_group = mp_conf[:term] if mp_conf[:test_eslim_ids].include?( test_eslim_id )
            end
          end
        end
        
        unless mp_group.nil?
          if result_data[:mp_groups][mp_group].nil?
            result_data[:mp_groups][mp_group] = {
              :results               => { :significant => [], :insignificant => [] },
              # :male_results          => { :significant => [], :insignificant => [] },
              # :female_results        => { :significant => [], :insignificant => [] },
              :is_significant        => nil
              # :is_male_significant   => nil,
              # :is_female_significant => nil,
            }
          end
          
          # sex_basket       = "#{result[:sex].downcase}_results".to_sym
          # sex_significance = "is_#{result[:sex].downcase}_significant".to_sym
          data_to_save = {
            :sex                => result[:sex],
            :parameter_name     => result[:parameter_name],
            :parameter_eslim_id => parameter_eslim_id,
            :test_eslim_id      => test_eslim_id,
            :significance       => result[:significance],
            :effect_size        => result[:effect_size],
            :mp_term            => result[:mp_term],
            :mp_term_name       => result[:mp_term_name]
          }
          
          # Assess the significance of the result, then store the data...
          if BigDecimal.new(result[:significance]).to_f < europhenome_significance_cutoff
            result_data[:mp_groups][mp_group][:results][:significant].push(data_to_save)
            # result_data[:mp_groups][mp_group][sex_basket][:significant].push(data_to_save)
            result_data[:mp_groups][mp_group][:is_significant]  = true
            # result_data[:mp_groups][mp_group][sex_significance] = true
          else
            result_data[:mp_groups][mp_group][:results][:insignificant].push(data_to_save)
            # result_data[:mp_groups][mp_group][sex_basket][:insignificant].push(data_to_save)
            result_data[:mp_groups][mp_group][:is_significant]  = false if result_data[:mp_groups][mp_group][:is_significant].nil?
            # result_data[:mp_groups][mp_group][sex_significance] = false if result_data[:mp_groups][mp_group][sex_significance].nil?
          end
        end
        
        sorted_results[ result[ joined_attribute ] ][ "#{result[:europhenome_id]}-#{het_hom}" ] = result_data
      end
      
      # Finally order the test results by parameter_eslim_id
      sorted_results.each do |sorted_results_key,sorted_results_data|
        sorted_results_data.each do |result_data_key,result_data|
          next if result_data.nil? or result_data[:mp_groups].nil?
          result_data[:mp_groups].each do |mp_term,mp_term_data|
            # groups = [:results,:male_results,:female_results]
            groups = [:results]
            groups.each do |results_group|
              next if mp_term_data[results_group].nil?
              [:significant, :insignificant].each do |signif_group|
                mp_term_data[results_group][signif_group].sort! { |a,b| a[:parameter_eslim_id] <=> b[:parameter_eslim_id] }
              end
            end
          end
        end
      end
      
      sorted_results.recursively_symbolize_keys!
      
      return sorted_results
    end
    
  end
end