# encoding: utf-8

module MartSearch
  module DataSetUtils
    
    def ikmc_dcc_other_mutants_sort_results( results )
      sorted_results = {}
      
      results.each do |result|
        joined_attribute = @config[:searching][:joined_attribute].to_sym
        stuff_to_report  = false
        
        data_stash = {
          #:mgi_gene_traps      => result[:mgi_gene_traps].to_i,
          :igtc                => result[:igtc].to_i,
          :imsr                => result[:imsr].to_i,
          :targeted_mutations  => result[:targeted_mutations].to_i,
          :other_mutations     => result[:other_mutations].to_i
        }
        
        data_stash.keys.each do |mut_type|
          stuff_to_report = true if data_stash[mut_type] > 0
        end
        
        if stuff_to_report
          sorted_results[ result[ joined_attribute ] ] = data_stash
        end
      end
      
      return sorted_results
    end
    
  end
end
