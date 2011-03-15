module MartSearch
  module DataSetUtils
    
    def emma_strains_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = result[ @config[:searching][:joined_attribute].to_sym ]
        emma_id          = result[:emma_id]
        
        sorted_results[joined_attribute]          ||= {}
        sorted_results[joined_attribute][emma_id] ||= { :references => {}, :availability => [] }
        
        emma_record = sorted_results[joined_attribute][emma_id]
        
        # Add singular info first...
        singles = [
          :gene_symbol,
          :emma_id,
          :international_strain_name,
          :common_name,
          :synonym,
          :maintained_background,
          :mutation_main_type,
          :mutation_sub_type,
          :genetic_description,
          :phenotype_description,
          :owner
        ]
        
        singles.each do |attribute|
          emma_record[attribute] = result[attribute]
        end
        
        # Allele name...
        emma_record[:allele_name] = fix_superscript_text_in_attribute(result[:alls_form])
        
        # References...
        pubmed_id = result[:pubmed_id]
        emma_record[:references][pubmed_id] = { :pubmed_id => pubmed_id, :reference => result[:reference] } unless pubmed_id.nil?
        
        # Availability...
        availability = result[:availability]
        emma_record[:availability].push(availability) unless availability.nil?
      end
      
      return sorted_results
    end
    
  end
end
