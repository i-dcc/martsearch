module MartSearch
  module DataSetUtils

    # Sort the mouse data from EMMA and KERMITS
    #
    # @param  [Hash] search_data
    # @return [Hash]
    def dummy_mice_secondary_sort( search_data )
      search_data.each do |key,result_data|
        kermits = result_data[:'ikmc-kermits'] || []
        emma    = result_data[:'emma-strains'] || {}

        # Empty the dummy mice and set default values for the columns we want
        result_data[:'dummy-mice'] = []
        columns_to_merge           = {}

        if kermits.empty? and emma.empty?
          result_data.delete(:'ikmc-kermits')
          result_data.delete(:'emma-strains')
          result_data.delete(:'dummy-mice')
          next
        elsif !kermits.empty? and emma.empty?
          kermits.each do |kermits_mouse|
            result_data[:'dummy-mice'].push( kermits_mouse.merge(columns_to_merge) )
          end
        elsif kermits.empty? and !emma.empty?
          emma.values.each do |emma_strain|
            result_data[:'dummy-mice'].push( emma_strain.merge(columns_to_merge) )
          end
        else
          kermits.each do |kermits_mouse|
            emma_mouse = emma.values.select do |strain|
              kermits_mouse[:escell_clone] == strain[:common_name]
            end
            result_data[:'dummy-mice'].push( kermits_mouse.merge( emma_mouse.first ) )
          end
        end
      end

      return search_data
    end
  end
end