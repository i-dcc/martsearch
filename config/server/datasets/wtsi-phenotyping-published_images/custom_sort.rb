# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def wtsi_phenotyping_published_images_sort_results( results )
      sorted_results = {}
      
      # remove the 'published_images_' prefix from the attributes
      prefix            = /^published\_images\_/
      processed_results = []
      results.each do |result|
        processed_result = {}
        result.each do |key,value|
          processed_result[key] = value if key == @config[:searching][:joined_attribute].to_sym
          processed_result[ key.to_s.gsub(prefix,'').to_sym ] = value
        end
        processed_results.push(processed_result)
      end
      results = processed_results
      
      results.sort{ |a,b| "#{a[:tissue]}-#{a[:gender]}" <=> "#{b[:tissue]}-#{b[:gender]}" }.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        unless sorted_results[ result[ joined_attribute ] ]
          sorted_results[ result[ joined_attribute ] ] = {}
        end
        
        unless sorted_results[ result[ joined_attribute ] ][ result[:colony_prefix].to_sym ]
          sorted_results[ result[ joined_attribute ] ][ result[:colony_prefix].to_sym ] = {
            :adult_lac_z_expression    => [],
            :embryo_lac_z_expression   => [],
            :tail_epidermis_wholemount => []
          }
        end
        
        result_data = sorted_results[ result[ joined_attribute ] ][ result[:colony_prefix].to_sym ]
        
        # work out the thumbnail URL (as the one in the mart can be flakey...)
        result[:thumbnail_url] = result[:url].sub("\.(\w+)$","thumb.\1")
        
        case result[:image_type]
        when 'Wholemount Expression'
          if result[:tissue].match('Embryo')
            if result[:tissue].match('14.5')
              result_data[:embryo_lac_z_expression].push(result)
            end
          else
            result_data[:adult_lac_z_expression].push(result)
          end
        when 'Confocal Skin Screen'
          result_data[:tail_epidermis_wholemount].push(result)
        end
      end
      
      return sorted_results
    end
    
  end
end
