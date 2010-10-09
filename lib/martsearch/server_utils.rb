module MartSearch
  
  # Utility module for the web app code
  #
  # @author Darren Oakley
  module ServerUtils
    include MartSearch::Utils
    
    # Helper function - returns all of the javascript for the head
    # of the web app concatenated into one file and compressed using 
    # the Google Closure Compiler.
    #
    # @param [String] version The version tag to put in the file name
    # @return [String] The concatenated and compressed javascript code
    def compressed_head_js( version )
      text = compress_js_or_css('js-head')
      save_to_disk( text, 'js', "martsearch-head-#{version}.js" )
      text
    end
    
    # Helper function - returns all of the javascript for the base
    # of the web app concatenated into one file and compressed using 
    # the Google Closure Compiler.
    #
    # @param [String] version The version tag to put in the file name
    # @return [String] The concatenated and compressed javascript code
    def compressed_base_js( version )
      text = compress_js_or_css('js-base')
      save_to_disk( text, 'js', "martsearch-base-#{version}.js" )
      text
    end

    # Helper function - returns all of the css for the web app 
    # concatenated into one file and compressed using the YUI 
    # CSS Compressor.
    #
    # @param [String] version The version tag to put in the file name
    # @return [String] The concatenated and compressed css code
    def compressed_css( version )
      text = compress_js_or_css('css')
      save_to_disk( text, 'css', "martsearch-#{version}.css" )
      text
    end
    
    private
      
      # Utility function to do the actual javascript/css concatenation 
      # and compression.
      #
      # @param [String] js_or_css Pass either 'js-head', 'js-base' or 'css'
      # @return [String] The concatenated and compressed code
      def compress_js_or_css( js_or_css )
        compressed_code = ''
        
        if js_or_css == 'js-head'
          defaults  = MartSearch::Server::DEFAULT_HEAD_JS_FILES
          short_str = 'js'
          symbol    = :javascript_head
          warn_str  = 'Closure::Compiler javascript'
        elsif js_or_css == 'js-base'
          defaults  = MartSearch::Server::DEFAULT_BASE_JS_FILES
          short_str = 'js'
          symbol    = :javascript_base
          warn_str  = 'Closure::Compiler javascript'
        else
          defaults  = MartSearch::Server::DEFAULT_CSS_FILES
          short_str = 'css'
          symbol    = :stylesheet
          warn_str  = 'YUI::CssCompressor CSS'
        end
        
        defaults.each do |file|
          compressed_code << get_file_as_string("#{MARTSEARCH_PATH}/lib/martsearch/server/public/#{short_str}/#{file}")
        end
        
        MartSearch::Controller.instance().config[:server][:dataviews].each do |dv|
           compressed_code << dv.send(symbol) unless dv.send(symbol).nil?
        end
        
        begin
          Dir.mktmpdir do |dir|
            if js_or_css =~ /js/
              compressed_code = Closure::Compiler.new(:compilation_level => 'SIMPLE_OPTIMIZATIONS').compress(compressed_code)
            else
              compressed_code = YUI::CssCompressor.new.compress(compressed_code)
            end
          end
        rescue Exception => e
          warn "[ERROR] - #{warn_str} compression failed - resorting to concatenated files"
          puts e
        end
        
        return compressed_code
      end
      
      # Utility function to save a given text string to disk
      #
      # @param [String] content The file content
      # @param [String] type The subdirectory in /public to save to
      # @param [String] name The file name to save
      def save_to_disk( content, type, name )
        file = File.new("#{MARTSEARCH_PATH}/lib/martsearch/server/public/#{type}/#{name}",'w')
        file.write content
        file.close
      end
      
  end
  
end