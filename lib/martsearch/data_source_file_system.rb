# encoding: utf-8

module MartSearch
  
  # Custom DataSource class for reading files off the local filesystem.
  #
  # @author Darren Oakley
  class FileSystemDataSource < DataSource
    # The location on the file system of this dataset.
    attr_reader :fs_location
    
    # @param [Hash] conf configuration hash
    def initialize( conf )
      super
      @fs_location = "#{MARTSEARCH_PATH}#{@conf[:location]}"
      
      unless File.exists?(@fs_location) and File.directory?(@fs_location)
        raise MartSearch::InvalidConfigError, "#{@fs_location} does not exist, or is not a directory!"
      end
    end
    
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
      raise NotImplementedError, "This feature has not been implemented for the FileSystemDataSource class."
    end
    
    # Function to search a biomart datasource given an appropriate configuration.
    #
    # @see MartSearch::DataSource#search
    # @raise [MartSearch::DataSourceError] Raised if an error occurs during the seach process
    def search( query, conf )
      unless conf[:file_globs]
        raise MartSearch::DataSourceError, "You have not specifed any 'glob' patterns!"
      end
      
      results   = []
      file_list = []
      pwd       = Dir.pwd
      
      begin
        Dir.chdir(@fs_location)
        conf[:file_globs].each do |glob_str|
          Dir.glob(glob_str).each do |file|
            file_list.push( file )
          end
        end
      rescue => error
        Dir.chdir(pwd)
        raise MartSearch::DataSourceError, "Error querying file system: #{error}"
      end
      
      Dir.chdir(pwd)
      
      file_list.each do |file|
        query.each do |string|
          if file.include?(string)
            results.push({ conf[:joined_index_field].to_sym => string, :file => file })
          end
        end
      end
      
      return results.uniq
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