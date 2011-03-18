module MartSearch
  module IndexBuilderUtils
    
    # Helper module containing all of the functions for interacting with the 
    # file system whilst IndexBuilder is running.
    # 
    # @author Darren Oakley
    module FileSystem
      
      # Utility function to setup the expected IndexBuilder cache directory structure.
      def setup_and_move_to_work_directory
        index_builder_tmpdir = "#{MARTSEARCH_PATH}/tmp/index_builder"
        
        Dir.mkdir(index_builder_tmpdir) unless File.directory?(index_builder_tmpdir)
        Dir.chdir(index_builder_tmpdir)
        
        ['dataset_dowloads','document_cache','solr_xml'].each do |cache_dir|
          Dir.mkdir(cache_dir) unless File.directory?(cache_dir)
          if cache_dir == 'dataset_dowloads'
            Dir.chdir(cache_dir)
            Dir.mkdir('current') unless File.directory?('current')
            Dir.chdir('..')
          end
        end
      end
      
      # Utility function to setup and move the current program into a daily cache directory.
      # 
      # @param [String] cache_dir The type of cache_dir to open [dataset_dowloads / document_cache / solr_xml]
      # @param [Boolean] delete Delete an existing daily cache directory?
      def open_daily_directory( cache_dir, delete=true )
        setup_and_move_to_work_directory()
        Dir.chdir("#{MARTSEARCH_PATH}/tmp/index_builder/#{cache_dir}")
        daily_dir = "daily_#{Date.today.to_s}"
        
        system "/bin/rm -r #{daily_dir}" if File.directory?(daily_dir) and delete
        Dir.mkdir(daily_dir) if delete or !File.directory?(daily_dir)
        
        # clean up old daily directories
        directories = Dir.glob("daily_*").sort
        while directories.size > 5
          system("/bin/rm -rf '#{directories.shift}'")
        end
        
        Dir.chdir(daily_dir)
      end
      
    end
    
  end
end