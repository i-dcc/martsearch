module MartSearch
  
  # Utility module for the web app code
  #
  # @author Darren Oakley
  module ServerUtils
    include MartSearch::Utils
    
    # Helper function - returns all of the javascript for the 
    # web app concatenated into one file and compressed using 
    # the Google Closure Compiler.
    #
    # @return [String] The concatenated and compressed javascript code
    def compressed_js
      compress_js_or_css('js')
    end
    
    # Helper function - returns all of the css for the web app 
    # concatenated into one file and compressed using the YUI 
    # CSS Compressor.
    #
    # @return [String] The concatenated and compressed css code
    def compressed_css
      compress_js_or_css('css')
    end
    
    private
      
      # Utility function to do the actual javascript/css concatenation 
      # and compression.
      #
      # @param [String] js_or_css Pass either 'js' or 'css'
      # @return [String] The concatenated and compressed code
      def compress_js_or_css( js_or_css )
        compressed_code = ''
        
        if js_or_css == 'js'
          defaults  = MartSearch::Server::DEFAULT_JS_FILES
          short_str = 'js'
          symbol    = :javascript
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
           compressed_code << dv[symbol] unless dv[symbol].nil?
        end
        
        begin
          Dir.mktmpdir do |dir|
            if js_or_css == 'js'
              #compressed_code = Closure::Compiler.new(:compilation_level => 'SIMPLE_OPTIMIZATIONS').compress(compressed_code)
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
      
  end
  
end