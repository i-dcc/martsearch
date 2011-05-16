# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def ikmc_unitrap_sort_results( results )
      projects = @config[:searching][:filters][:project].split(',')
      
      ##
      ## Collate all of the info we need from the result data
      ##
      
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        
        unless sorted_results[ result[ joined_attribute ] ]
          sorted_results[ result[ joined_attribute ] ] = {
            :traps                => {},
            :project_counts_total => {},
            :unitrap_counts_total => {}
          }
          
          data = sorted_results[ result[ joined_attribute ] ]
          projects.each do |proj|
            project_name = proj.clone
            project_name = 'NorCOMM' if ['Stanford','ESCells','CMHD'].include?(project_name)
            
            data[:project_counts_total][project_name.to_sym] = 0
            data[:traps][project_name.to_sym]                = {}
          end
        end
        
        data       = sorted_results[ result[ joined_attribute ] ]
        
        result[:unitrap_accession_id] = result[:unitrap_accession_id].match(/^(ENS\w+)-(UNI.+)$/)[2]
        unitrap_id                    = result[:unitrap_accession_id].to_sym
        
        project = result[:project].to_sym
        project = :NorCOMM if ['Stanford','ESCells','CMHD'].include?(result[:project])
        
        # Instanciate variables
        data[:traps][ project ][ unitrap_id ]     = [] unless data[:traps][ project ][ unitrap_id ]
        data[:unitrap_counts_total][ unitrap_id ] = 0  unless data[:unitrap_counts_total][ unitrap_id ]
        
        # Increment counts
        data[:unitrap_counts_total][ unitrap_id ] = data[:unitrap_counts_total][ unitrap_id ] + 1
        data[:project_counts_total][ project ]    = data[:project_counts_total][ project ] + 1
        
        # Update the cell line and strain if we have no data
        if result[:escell_line].nil?
          result[:escell_line] = case result[:project]
          when 'TIGM'     then 'Lex3.13'
          when 'Stanford' then 'R1'
          when 'CMHD'     then 'R1'
          when 'ESCells'  then 'E14Tg2a.4'
          when 'EUCOMM'
            case result[:escell_clone]
            when /EUCJ/ then 'JM8'
            when /EUCE/ then 'E14Tg2a'
            when /EUCG/ then 'E14Tg2a'
            end
          end
        end
        
        if result[:escell_strain].nil?
          result[:escell_strain] = case result[:project]
          when 'TIGM'     then 'C57Bl/6N'
          when 'Stanford' then '129S3'
          when 'CMHD'     then '129S3'
          when 'ESCells'  then '129 sv'
          when 'EUCOMM'
            case result[:escell_clone]
            when /EUCJ/ then 'C57Bl/6N'
            when /EUCE/ then '129P2/OlaHsd'
            when /EUCG/ then '129P2/OlaHsd'
            end
          end
        end
        
        # Store data
        result[:project] = 'NorCOMM' if ['Stanford','ESCells','CMHD'].include?(result[:project])
        data[:traps][ project ][ unitrap_id ].push(result)
      end
      
      ##
      ## After the first pass, quickly collate the traps into a 
      ## useful (sorted and grouped) data structure for the template...
      ##
      
      sorted_results.each do |result_key,result_value|
       result_value[:traps_by] = {}
       
       # Group traps by project...
       result_value[:project_counts_total].keys.each do |project|
         traps = result_value[:traps][project].values.flatten
         traps.sort!{ |a,b| a[:unitrap_accession_id] <=> b[:unitrap_accession_id] }
         
         result_value[:traps_by][project] = traps
       end
       
       # Group traps by unitrap...
       result_value[:unitrap_counts_total].keys.each do |unitrap|
         traps = []
         result_value[:traps].each do |project,data_by_unitrap|
           traps.push( data_by_unitrap[unitrap] ) unless data_by_unitrap[unitrap].nil?
         end
         traps.flatten!.sort!{ |a,b| a[:project] <=> b[:project] }
         
         result_value[:traps_by][unitrap] = traps
       end
      end
      
      return sorted_results
      
    end
    
  end
end
