# encoding: utf-8

module MartSearch

  # Singleton controller class for MartSearch.  This is the central contoller
  # for the MartSearch framework - it handles the config file parsing, building
  # up all of the DataSource and Index objects, and managing the search mechanics.
  #
  # @author Darren Oakley
  class Controller
    include Singleton
    include MartSearch::Utils
    include MartSearch::ControllerUtils

    USE_CACHE = true
    warn "#### NOT USING CACHE!!!" if ! USE_CACHE

    attr_reader :config, :cache, :logger, :index, :errors, :search_data
    attr_reader :search_results, :datasources, :datasets, :dataviews, :dataviews_by_name

    def initialize()
      config_dir = "#{MARTSEARCH_PATH}/config"

      @config = {
        :index         => build_index_conf( config_dir ),
        :datasources   => build_datasources( config_dir ),
        :server        => build_server_conf( "#{config_dir}/server" ),
        :index_builder => build_index_builder_conf( "#{config_dir}/index_builder" )
      }

      @cache             = initialize_cache( @config[:server][:cache] )
      @index             = MartSearch::Index.new( @config[:index] )
      @datasources       = @config[:datasources]
      @datasets          = @config[:server][:datasets]
      @dataviews         = @config[:server][:dataviews]
      @dataviews_by_name = @config[:server][:dataviews_by_name]

      # OLS
      #OLS.setup_cache(
      #  {
      #    :host => 'web-mei-t87p.internal.sanger.ac.uk',
      #    :port => 3334,
      #    :database => 'htgt_ols_cache',
      #    :user => 'htgt',
      #    :password => 'htgt'
      #  }
      #)

      # Logger
      @logger                 = Logger.new($stdout)
      @logger                 = Logger.new($stderr)
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S "
      @logger.level           = case @config[:server][:log][:level]
        when 'debug' then Logger::DEBUG
        when 'info'  then Logger::INFO
        when 'warn'  then Logger::WARN
        when 'error' then Logger::ERROR
        when 'fatal' then Logger::FATAL
      end

      # Stores for search result data and errors...
      @errors         = { :index => [], :datasets => {} }
      @search_data    = {}
      @search_results = []
    end

    
    def get_targrep_mart_results(mgi_accession_id)
      targ_rep_mart = datasources[:'ikmc-idcc_targ_rep'].ds
      error_string  = "Information on Targeting Vectors and ES Cells is missing"
      results       = handle_biomart_errors( "ikmc-ikmc-targ_rep", error_string ) do
        targ_rep_mart.search({
          :process_results => true,
          :filters         => { 'mgi_accession_id' => mgi_accession_id},
          :attributes      => [
            'mutation_subtype',
            'parental_cell_line',
            'allele_symbol_superscript',
            'allele_id',
            'parental_cell_line',
            'escell_pipeline',
            'escell_ikmc_project_id'
          ].flatten
        })
      end
      return results
    end
    
    def add_targ_rep_data(mgi_accession_id, displayed_alleles)
      
      results = get_targrep_mart_results(mgi_accession_id)
      
      tm1a = nil
      tm1e = nil
      tm1 = nil
      puts results
      results.each do |result|
        puts "ES RESULT #{result}"
        next unless !(result["parental_cell_line"].nil?)
        pipeline = result["escell_pipeline"]
        project_id = result["escell_ikmc_project_id"]
        if((pipeline == "EUCOMM") || (pipeline == "EUCOMMTools") || (pipeline == "EUCOMMToolsCre"))
          order_url = "http://www.eummcr.org/order.php"
          order_visual = "EUMMCR"
        elsif ((pipeline == "KOMP-CSD") || (pipeline == "KOMP-Regeneron"))
          if(project_id =~ /VG/)
            order_url = "http://www.komp.org/geneinfo.php?project=#{project_id}"
          else
            order_url = "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
          end
          order_visual = "KOMP"
        elsif ((pipeline == "MirKO") || (pipeline == "Sanger MGP"))
          order_url = "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{result["marker_symbol"]}"
          order_visual = "WTSI"
        elsif (pipeline == "NorCOMM")
          order_url = "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
          order_visual = "NorCOMM"
        end  
        result["product"] = 'ES Cell'
        result["order_url"] = order_url
        result["order_visual"] = order_visual
        if (result["mutation_subtype"] == 'conditional_ready' && tm1a.nil?)
          tm1a = result
        end
        if (result["mutation_subtype"] == 'targeted_non_conditional' && tm1e.nil?)
          tm1e = result
        end
        if (result["mutation_subtype"] == 'deletion' && tm1.nil?)
          tm1 = result
        end
      end
      
      # Display the conditional in preference to the targeted non-conditional
      if(!tm1a.nil?)
        displayed_alleles["tm1a"] = tm1a
      elsif(!tm1e.nil?)
        displayed_alleles["tm1e"] = tm1e
      end
      
      # Display the deletion if we have it
      if(!tm1.nil?)
        displayed_alleles["tm1"] = tm1
      end
    end

    def get_imits_mart_results(mgi_accession_id)
      imits_mart = datasources[:'ikmc-imits'].ds
      error_string  = "Information on Mice is missing"
      results       = handle_biomart_errors( "ikmc-imits", error_string ) do
      imits_mart.search({
          :process_results => true,
          :filters         => {
            'mgi_accession_id' => mgi_accession_id,
          },
          :attributes      => [
            'marker_symbol',
            'consortium',
            'distribution_centre',
            'colony_background_strain',
            'production_centre',
            'distribution_centre',
            'emma',
            'microinjection_status',
            'allele_symbol_superscript',
            'mouse_allele_symbol_superscript',
            'phenotype_allele_type',
            'phenotype_status',
            'phenotype_is_active',
            'distribution_centre',
            'report_ikmc_project_id'
          ].flatten
        })
      end
    end
    
    def add_imits_data( mgi_accession_id, displayed_alleles)
      tm1a = nil
      tm1e = nil
      tm1 = nil
      results = get_imits_mart_results( mgi_accession_id )
            
      #Work out if the starting allele is conditional (tm1a/e) or a deletion (tm1)
      # - if it's conditional, work out if the mouse is also conditional (blank mouse allele)
      # or if the mouse is targeted non-conditional (tm1e)
      results.each do |result|
        #puts "MOUSE RESULT #{result}"
        next unless ((result["microinjection_status"] == 'Genotype confirmed') or (result["phenotype_status"] == "Cre Excision Complete"))
        product = "Mouse"
        pipeline = result["consortium"]
        
        if(result["microinjection_status"] == 'Genotype confirmed')
          starting_allele = result["allele_symbol_superscript"]
          final_allele = result["mouse_allele_symbol_superscript"]
          if(/tm\d\w/.match(starting_allele))
            #If there's no override to the input allele, then use it
            if(final_allele.nil?)
              final_allele = 'conditional_ready'
              final_allele_id = displayed_alleles["tm1a"]["allele_id"]
            elsif(/tm\de/.match(final_allele))
              final_allele = 'targeted_non_conditional'
              final_allele_id = "not yet"
            end
          elsif(/tm\d/.match(starting_allele))
              final_allele = 'deletion'
              final_allele_id = displayed_alleles["tm1"]["allele_id"]
          end
          allele_type = final_allele
          allele_strain = result["colony_background_strain"]
          order_url = nil
          order_visual = nil
          if(result["distribution_centre"]=="UCD")
            project_id = result["report_ikmc_project_id"]
            if(project_id =~ /VG/)
              order_url = "http://www.komp.org/geneinfo.php?project=#{project_id}"
            else
              order_url = "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
            end
            order_visual = "KOMP"
          elsif(result["emma"] == "1")
            order_url = "http://www.emmanet.org/mutant_types.php?keyword=#{result["marker_symbol"]}"
            order_visual = "EMMA"
          elsif(result["distribution_centre"] == "WTSI")
            order_url = "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{result["marker_symbol"]}"
            order_visual = "WTSI"
          end
          
          new_row = {
            "product" => product,
            "escell_pipeline" => pipeline,
            "mutation_subtype" => final_allele,
            "parental_cell_line" => allele_strain,
            "allele_id" => final_allele_id,
            "order_url" => order_url,
            "order_visual" => order_visual
          }
          displayed_alleles["mouse_1"] = new_row
        end
        
        
        if(result["phenotype_status"] == "Cre Excision Complete")
          phenotype_allele_type = result["phenotype_allele_type"]
          if(phenotype_allele_type)
            final_allele = 'Cre Excised'
            final_allele_id = 'not yet'
            new_row = {
              "product" => product,
              "escell_pipeline" => pipeline,
              "mutation_subtype" => final_allele,
              "parental_cell_line" => allele_strain,
              "allele_id" => final_allele_id
            }
            displayed_alleles["mouse_2"] = new_row
          end
        end
      end
    end
    
    def handle_biomart_errors( data_source, error_string )
      MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::handle_biomart_errors - running handle_biomart_errors( '#{data_source}', '#{error_string}' )")

      results      = { :data => {}, :error => {} }
      error_prefix = "There was a problem querying the '#{data_source}' biomart."
      error_suffix = "Try refreshing your browser or come back in 10 minutes."
      begin
        results[:data] = yield
      rescue Biomart::BiomartError => error
        results[:error] = {
          :text  => error_prefix + " " + error_string + " " + error_suffix,
          :error => error.to_s,
          :type  => error.class
        }
      rescue Timeout::Error => error
        results[:error] = {
          :text  => error_prefix + " " + error_string + " " + error_suffix,
          :error => error.to_s,
          :type  => error.class
        }
      end
    end
  
    def search_impc (mgi_accession_id)
      @displayed_alleles = {}

      # add the tm1a or tm1e allele AND the tm1 allele if they exist
      add_targ_rep_data( mgi_accession_id, @displayed_alleles)
      
      # add the corresponding mouse alleles if they exist
      add_imits_data( mgi_accession_id, @displayed_alleles)
      
      @displayed_alleles["order"] = ["tm1a","tm1","tm1e","mouse_1","mouse_2"]
      puts "<<<<<"
      puts @displayed_alleles
      puts "<<<<<"
      return @displayed_alleles
    end
    
    # Function to perform the searches against the index and marts.
    #
    # Sets up a results stash (@search_data) holding the data in a structure like:
    #   {
    #     IndexDocUniqueKey => {
    #       "index"         => {}, # index results for this doc
    #       "internal_name" => []/{}, # array/hash of sorted biomart data
    #       "internal_name" => []/{}, # array/hash of sorted biomart data
    #     }
    #   }
    #
    # But returns an ordered list of the results/index docs (@search_results)
    #
    # @param [String] query The query string to pass to the search index
    # @param [Integer] page The page of results to search for/return
    # @param [Boolean] use_cache Use cached data if available
    # @param [Boolean] save_index_data Try to save the index return to the cache
    # @return [Array] A list of the search results (primary index fields)
    def search( query, page=1, use_cache=true, save_index_data=true )
      self.logger.debug("[MartSearch::Controller] ::search - running search( '#{query}', #{page}, #{use_cache}, #{save_index_data} )")
      page = 1 if page == 0
      clear_instance_variables

      cached_index_data = fetch_from_cache( "index:#{query}-page#{page}" )
      if cached_index_data != nil and use_cache
        search_from_cached_index( cached_index_data )
      else
        if search_from_fresh_index( query, page ) and save_index_data
          obj_to_cache    = {
            :search_data           => @search_data,
            :search_results        => @search_results,
            :current_page          => @index.current_page,
            :current_results_total => @index.current_results_total,
            :cache_timestamp       => DateTime.now.to_s
          }
          write_to_cache( "index:#{query}-page#{page}", obj_to_cache )
        end
      end

      unless @search_data.empty?
        fresh_ds_queries_to_do = []

        @search_data.each do |data_key,data|
          cached_dataset_data = fetch_from_cache( "datasets:#{data_key}" )

          if cached_dataset_data != nil and use_cache
            @search_data[data_key] = cached_dataset_data.merge(data)
          else
            fresh_ds_queries_to_do.push(data_key)
          end
        end

        unless fresh_ds_queries_to_do.empty?
          grouped_search_terms = prepare_dataset_search_terms( fresh_ds_queries_to_do )
          if search_from_fresh_datasets( fresh_ds_queries_to_do, grouped_search_terms )
            fresh_ds_queries_to_do.each do |data_key|
              unless @search_data[data_key].nil?
                @search_data[data_key][:cache_timestamp] = DateTime.now.to_s
                write_to_cache( "datasets:#{data_key}", @search_data[data_key] )
              end
            end
          end
        end
      end

      # Return paged_results
      return @search_results
    end

    # Function to load in the browsable content config and then query the index
    # for each term and get a count of items returned...
    #
    # @param [Boolean] use_cache Use cached data if available
    # @return [Hash] A hash of all of the browsable content counts
    def browse_counts( use_cache=true )
      self.logger.debug("[MartSearch::Controller] ::browse_counts - running browse_counts( '#{use_cache}' )")
      counts = fetch_from_cache( "browse_counts" )
      if counts.nil? || use_cache == false
        all_ok = true
        counts = {}
        @config[:server][:browsable_content].each do |field,field_config|
          counts[field] = {}
          Parallel.each( field_config[:options].keys, :in_threads => 5 ) do |option|
            begin
              option_config         = field_config[:options][option]
              counts[field][option] = @index.count( option_config[:query] )
            rescue MartSearch::IndexSearchError => error
              all_ok                              = false
              counts[field][option] = nil
            end
          end
        end

        write_to_cache( "browse_counts", counts ) if all_ok
      end

      return counts
    end

    # Function to calculate the progress of the WTSI Mouse Genetics Project (MGP).
    # This should return counts for three categories:
    #   - Number of genes with lines with Standard Phenotyping (MGP pipeline) done
    #   - Number of genes with lines with Infection Challenge (Citrobacter & Salmonella) done
    #   - Number of genes with lines with Expression (embryo and adult) done
    #
    # @param [Boolean] use_cache Use cached data if available
    # @return [Hash] A hash of the status counts that the MGP wants
    def wtsi_phenotyping_progress_counts( use_cache=true )
      self.logger.debug("[MartSearch::Controller] ::wtsi_phenotyping_progress_counts - running wtsi_phenotyping_progress_counts( '#{use_cache}' )")
      heatmap_dataset = self.datasets[:'wtsi-phenotyping-heatmap']
      raise MartSearch::InvalidConfigError, "MartSearch::Controller.wtsi_phenotyping_progress_counts cannot be called if the 'wtsi-phenotyping-heatmap' dataset is inactive" if heatmap_dataset.nil?

      counts = fetch_from_cache( "wtsi_phenotyping_progress_counts" )
      if counts.nil? || use_cache == false
        heatmap_test_groups_conf = heatmap_dataset.config[:test_groups]
        heatmap_mart             = heatmap_dataset.datasource.ds
        counts                   = {}
        all_ok                   = true

        begin
          counts = {
            :standard_phenotyping => complete_mgp_alleles_count( heatmap_mart, ['haematology_cbc'], ['CompleteInteresting','CompleteNotInteresting'] ),
            :infection_challenge  => complete_mgp_alleles_count( heatmap_mart, ['salmonella_challenge','citrobacter_challenge'], ['CompleteInteresting','CompleteNotInteresting'] ),
            :expression           => complete_mgp_alleles_count( heatmap_mart, ['adult_lac_z_expression','embryo_lac_z_expression'], ['CompleteDataAvailable'] )
          }
        rescue Biomart::BiomartError => error
          all_ok = false
          counts = {
            :standard_phenotyping => counts[:standard_phenotyping]  ? counts[:standard_phenotyping] : '-',
            :infection_challenge  => counts[:infection_challenge]   ? counts[:infection_challenge]  : '-',
            :expression           => counts[:expression]            ? counts[:expression]           : '-',
          }
        end

        write_to_cache( "wtsi_phenotyping_progress_counts", counts, { :expires_in => 12.hours } ) if all_ok
      end

      return counts
    end

    # Cache interaction helper - fetch data from the cache for a given key.
    #
    # @param [String] key The cache identifer to look up
    # @return [Object/nil] The deserialized object from the cache, or nil if none found
    def fetch_from_cache( key )
      return nil if ! USE_CACHE
      self.logger.debug("[MartSearch::Controller] ::fetch_from_cache - running fetch_from_cache( '#{key}' )")
      cached_data = @cache.fetch( key )

      unless cached_data.nil?
        if @cache.is_a?(MartSearch::MongoCache)
          cached_data = JSON.parse( cached_data['json'], :max_nesting => false )
        else
          cached_data = JSON.parse( cached_data, :max_nesting => false )
        end
        cached_data = cached_data.clean_hash if RUBY_VERSION < '1.9'
        cached_data.recursively_symbolize_keys!
      end
      self.logger.debug("[MartSearch::Controller] ::fetch_from_cache - running fetch_from_cache( '#{key}' ) - DONE")

      return cached_data
    end

    # Cache interaction helper - use this to store data in the cache.
    #
    # @param [String] key The cache identifer to store 'value' under
    # @param [Object] value The cache 'value' to store
    # @param [Hash] options An options hash (see #{ActiveSupport::Cache} for more info)
    def write_to_cache( key, value, options={} )
      return if ! USE_CACHE
      self.logger.debug("[MartSearch::Controller] ::write_to_cache - running write_to_cache( '#{key}', Object, '#{options.inspect}' )")
      @cache.delete( key )
      if @cache.is_a?(MartSearch::MongoCache)
        @cache.write( key, { 'json' => JSON.generate( value, :max_nesting => false ) }, { :expires_in => 36.hours }.merge(options) )
      else
        @cache.write( key, JSON.generate( value, :max_nesting => false ), { :expires_in => 36.hours }.merge(options) )
      end
      self.logger.debug("[MartSearch::Controller] ::write_to_cache - running write_to_cache( '#{key}', Object, '#{options.inspect}' ) - DONE")
    end

    private

      # Helper function for #wtsi_phenotyping_progress_counts. This function queries the
      # MGP mart for a defined set of tests/attributes and computes the number of completed
      # alleles (by complete, we mean that any of the tests listed have a status defined in the
      # allowed_values argument passed in).
      #
      # @param [Biomart::Dataset] mart A Biomart::Dataset object for the MGP mart
      # @param [Array] attributes The list of tests/attributes to check for completeness
      # @param [Array] allowed_values The attribute values to look for to consider a result 'complete'
      # @return [Integer] The count of unique genes that have data on all the tests queried
      def complete_mgp_alleles_count( mart, attributes, allowed_values )
        self.logger.debug("[MartSearch::Controller] ::complete_mgp_alleles_count - running complete_mgp_alleles_count()")
        complete_genes = []
        results        = mart.search(
          :process_results => true,
          :attributes      => attributes.unshift('allele_name'),
          :filters         => {}
        )

        results.each do |result|
          pass_count = 0
          result.each do |key,value|
            next if key == 'allele_name'
            pass_count += 1 if allowed_values.include?(value)
          end
          complete_genes.push( result['allele_name'] ) if pass_count == ( attributes.size - 1 )
        end

        return complete_genes.uniq.size
      end

      # Utility function that drives the index searches.
      #
      # @param [String] query The search term to hit the index with
      # @param [Integer] page The page of results to retrieve
      # @return [Boolean] true/false reporting if the search went without error (actual results are stored in @search_data)
      def search_from_fresh_index( query, page )
        self.logger.debug("[MartSearch::Controller] ::search_from_fresh_index - running search_from_fresh_index( '#{query}', '#{page}' )")
        begin
          if @index.is_alive?
            @search_data    = @index.search( query, page )
            @search_results = @index.paginated_results
            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_index - running search_from_fresh_index( '#{query}', '#{page}' ) - DONE")
            return true
          end
        rescue MartSearch::IndexUnavailableError => error
          self.logger.error("[MartSearch::Controller] ::search_from_fresh_index - MartSearch::IndexUnavailableError thrown")
          @errors[:index].push({
            :text  => 'The search index is currently unavailable, please check back again soon.',
            :error => error,
            :type  => 'MartSearch::IndexUnavailableError'
          })
          return false
        rescue MartSearch::IndexSearchError => error
          self.logger.error("[MartSearch::Controller] ::search_from_fresh_index - MartSearch::IndexSearchError thrown")
          @errors[:index].push({
            :text  => 'The search term you used has caused an error on the search engine, please try another search term without any special characters in it.',
            :error => error,
            :type  => 'MartSearch::IndexSearchError'
          })
          return false
        end
      end

      # Utility function to load index data into the instance variables from a
      # cached object.
      #
      # @param [String] cached_data The marshaled object to load
      def search_from_cached_index( cached_data )
        self.logger.debug("[MartSearch::Controller] ::search_from_cached_index - running search_from_cached_index()")
        @search_data                 = cached_data[:search_data]
        @index.current_page          = cached_data[:current_page]
        @index.current_results_total = cached_data[:current_results_total]
        @search_results              = @index.paginate_results(cached_data[:search_results])
      end

      # Utility function to prepare the search terms used to drive the dataset searches.
      #
      # @param [Array] search_keys The keys/docs in @search_data to prepare dataset searches for
      # @return [Hash] A hash keyed by the document fields containing all the terms found for the given field
      def prepare_dataset_search_terms( search_keys )
        self.logger.debug("[MartSearch::Controller] ::prepare_dataset_search_terms - running prepare_dataset_search_terms()")
        grouped_terms = {}

        search_keys.each do |key|
          doc = @search_data[key][:index]
          doc.each do |field,value|
            grouped_terms_for_field = grouped_terms[field]
            grouped_terms_for_field = [] if grouped_terms_for_field.nil?

            if value.is_a?(Array)
              value.each do |val|
                grouped_terms_for_field.push( val )
              end
            else
              grouped_terms_for_field.push( value )
            end

            grouped_terms[field] = grouped_terms_for_field
          end
        end

        return grouped_terms
      end

      # Utility function that performs the dataset searches and
      # post-search sorting routines
      #
      # @params [Array] terms_to_query An array of @search_data keys that we should be feeding data into here...
      # @param [Hash] grouped_search_terms A hash of terms (grouped by index field) that can be used to drive the dataset searches
      # @return [Boolean] true/false reporting if the searches went without error (actual results are stored in @search_data)
      def search_from_fresh_datasets( terms_to_query, grouped_search_terms )
        self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running search_from_fresh_datasets()")
        success = true

        Parallel.each( @datasets.keys, :in_threads => 10 ) do |ds_name|
          begin
            dataset      = @datasets[ds_name]
            search_terms = grouped_search_terms[ dataset.joined_index_field.to_sym ]

            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running dataset search for #{ds_name}")
            results      = dataset.search( search_terms )
            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running dataset search for #{ds_name} - DONE")

            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running add_dataset_results_to_search_data for #{ds_name}")
            add_dataset_results_to_search_data( dataset.joined_index_field.to_sym, ds_name.to_sym, results )
            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running add_dataset_results_to_search_data for #{ds_name} - DONE")

          rescue MartSearch::DataSourceError => error
            self.logger.error("[MartSearch::Controller] ::search_from_fresh_datasets - MartSearch::DataSourceError thrown")
            warn "#{ds_name}: '#{error}'"
            @errors[:datasets][ds_name] = {
              :text  => "The '#{ds_name}' dataset has returned an error for this query.",
              :error => error,
              :type  => 'MartSearch::DataSourceError'
            }
            success = false
          rescue Timeout::Error => error
            self.logger.error("[MartSearch::Controller] ::search_from_fresh_datasets - Timeout::Error thrown")
            @errors[:datasets][ds_name] = {
              :text  => "The '#{ds_name}' dataset did not respond quickly enough for this query.",
              :error => error,
              :type  => 'Timeout::Error'
            }
            success = false
          rescue Errno::ETIMEDOUT => error
            self.logger.error("[MartSearch::Controller] ::search_from_fresh_datasets - Errno::ETIMEDOUT thrown")
            @errors[:datasets][ds_name] = {
              :text  => "The '#{ds_name}' dataset did not respond quickly enough for this query.",
              :error => error,
              :type  => 'Errno::ETIMEDOUT'
            }
            success = false
          end
        end

        # Run the dataset secondary sorts in serial, BUT only run them on the results we
        # haven't pulled them from the cache.
        @datasets.each do |dataset_name,dataset|
          if dataset.config[:custom_secondary_sort]
            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running dataset secondary sort for #{dataset_name}")
            search_data_copy = @search_data.clone
            search_data_copy.keys.each { |key| search_data_copy.delete(key) unless terms_to_query.include?(key) }
            @search_data.merge( dataset.secondary_sort( search_data_copy ) )
            self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running dataset secondary sort for #{dataset_name} - DONE")
          end
        end

        self.logger.debug("[MartSearch::Controller] ::search_from_fresh_datasets - running search_from_fresh_datasets() - DONE")
        return success
      end

      # Utility function to merge dataset results into the @search_data hash.
      #
      # @param [Symbol] index_field The index field link the results data with (as it's the primary key of the 'results' hash)
      # @param [Symbol] dataset_name The name of the dataset we're working with
      # @param [Hash] results The results that will be merged into @search_data
      def add_dataset_results_to_search_data( index_field, dataset_name, results )
        self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - running add_dataset_results_to_search_data( '#{index_field}', '#{dataset_name}', Hash )")
        # First, see if the primary key of the index is the same
        # as the primary key of our results data, if yes, use
        # this association as it's easy and bloody fast!
        if @index.primary_field == index_field
          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by primary index field")
          results.symbolize_keys!
          @search_data.each do |primary_key,data_value|
            data_value[dataset_name] = results[primary_key]
          end
          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by primary index field - DONE")
        else
          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by lookup hash")

          # Create a lookup hash of the 'index_field' values so that
          # we can easily associate our results back to a primary_key...
          lookup = {}

          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by lookup hash (creating lookup hash)")
          @search_data.each do |primary_key,data_value|
            joined_index_field_data = data_value[:index][index_field]

            if joined_index_field_data.is_a?(Array)
              joined_index_field_data.each do |lookup_key|
                lookup[lookup_key] = primary_key
              end
            else
              lookup[joined_index_field_data] = primary_key
            end
          end
          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by lookup hash (creating lookup hash) - DONE")

          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by lookup hash (merging in data)")
          results.each do |result_key,result_data|
            stash_to_append_to = @search_data[ lookup[result_key] ]

            if stash_to_append_to
              if @datasets[dataset_name].config[:custom_sort]
                current_stash = stash_to_append_to[dataset_name]

                if current_stash.nil?
                  current_stash = result_data
                elsif current_stash.is_a?(Array)
                  current_stash.push(result_data)
                elsif current_stash.is_a?(Hash)
                  current_stash.merge!(result_data)
                end

                stash_to_append_to[dataset_name] = current_stash
              else
                stash_to_append_to[dataset_name] = [] unless stash_to_append_to[dataset_name.to_sym]

                result_data.each do |data|
                  stash_to_append_to[dataset_name].push(data)
                end
              end
            end
          end
          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by lookup hash (merging in data) - DONE")

          self.logger.debug("[MartSearch::Controller] ::add_dataset_results_to_search_data - matching up search data by lookup hash - DONE")
        end
      end

      # Utility function to clear all instance variables
      def clear_instance_variables
        self.logger.debug("[MartSearch::Controller] ::clear_instance_variables - running clear_instance_variables()")
        @errors         = { :index => [], :datasets => {} }
        @search_data    = {}
        @search_results = []
      end
  end

end
