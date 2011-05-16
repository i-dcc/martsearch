# encoding: utf-8

module MartSearch
  
  # Custom DataSource class for reading files off the local filesystem.
  #
  # @author Darren Oakley
  class DummyDataSource < DataSource
    # Simple heartbeat function to check that the datasource is online.
    #
    # @see MartSearch::DataSource#is_alive?
    def is_alive?
      true
    end
    
    # Function to query a biomart datasource and return all of the data ready for indexing.
    #   - THIS FEATURE HAS NOT BEEN IMPLEMENTED FOR THIS CLASS.
    # 
    # @see MartSearch::DataSource#fetch_all_terms_for_indexing
    # @raise [NotImplementedError] This feature has not been implemented for this class
    def fetch_all_terms_for_indexing( conf )
      raise NotImplementedError, "This feature has not been implemented for the DummyDataSource class."
    end
    
    # Function to search a biomart datasource given an appropriate configuration.
    #
    # @see MartSearch::DataSource#search
    # @raise [MartSearch::DataSourceError] Raised if an error occurs during the seach process
    def search( query, conf )
      return_obj = []
      query.each do |term|
        return_obj.push({ :mgi_accession_id => term })
      end
      return return_obj
    end
    
    # Function to provide a link URL to the original datasource given a 
    # dataset query.
    #
    # @see MartSearch::DataSource#data_origin_url
    def data_origin_url( query, conf )
      nil
    end
    
  end
  
end