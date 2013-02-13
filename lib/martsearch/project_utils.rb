# encoding: utf-8

module MartSearch

  # Utility module to house all of the data gathering logic for the IKMC
  # project page views.
  #
  # @author Sebastien Briois
  # @author Darren Oakley
  # @author Nelo Onyiah
  module ProjectUtils

    include MartSearch::Utils
    include MartSearch::DataSetUtils
    include MartSearch::ServerViewHelpers

    # Wrapper function to collate all of the data for a given IKMC project.
    #
    # @param [String] project_id The IKMC project ID
    # @return [Hash] A hash containing all the data for the given project
    def get_ikmc_project_page_data( project_id )
      MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_ikmc_project_page_data - running get_ikmc_project_page_data( '#{project_id}' )")
      datasources = MartSearch::Controller.instance().datasources
      index       = MartSearch::Controller.instance().index
      data        = { :project_id => project_id.to_s }
      errors      = []

      top_level_data = get_top_level_project_info( datasources, project_id )

      if top_level_data[:data].nil? or top_level_data[:data].empty?
        return { :data => nil }
      else
        data.merge!( top_level_data[:data][0] )
        errors.push( top_level_data[:error] ) unless top_level_data[:error].empty?

        ##
        ## Look for human orthalog's
        ##

        #if data[:ensembl_gene_id]
        #  human_orthalogs = get_human_orthalog( datasources, data[:ensembl_gene_id] )
        #  data.merge!( human_orthalogs[:data] ) unless human_orthalogs[:data].empty?
        #  errors.push( human_orthalogs[:error] ) unless human_orthalogs[:error].empty?
        #end

        ##
        ## Now search the targ_rep for vectors and es cells
        ##

        vectors_and_cells = get_vectors_and_cells( datasources, project_id )
        data.merge!( vectors_and_cells[:data] )
        errors.push( vectors_and_cells[:error] ) unless vectors_and_cells[:error].empty?

        # Calculate the intended allele type
        allele_design_type = nil
        if !data[:es_cells][:conditional].nil? && !data[:es_cells][:conditional][:cells].empty?
          allele_design_type = data[:es_cells][:conditional][:cells].first[:allele_type]
        elsif !data[:targeting_vectors].nil? && !data[:targeting_vectors].empty?
          allele_design_type = data[:targeting_vectors].first[:design_type]
        elsif !data[:intermediate_vectors].nil? && !data[:intermediate_vectors].empty?
          allele_design_type = data[:intermediate_vectors].first[:design_type]
        end
        data[:allele_design_type] = allele_design_type

        ##
        ## Search Kermits for mice
        ##

        es_cell_names = []
        [ :"targeted non-conditional", :conditional ].each do |symbol|
          es_cell_names.push( data[:es_cells][symbol][:cells] ) unless data[:es_cells][symbol].nil?
        end

        es_cell_names.flatten!.map! { |es_cell| es_cell[:name] }
        unless es_cell_names.empty?
          mice = get_mice( datasources, es_cell_names )
          data.merge!( mice[:data] ) unless mice[:data].empty?
          errors.push( mice[:error] ) unless mice[:error].empty?
        end

        ##
        ## Ammend the es cells data to say which cells have been made into a mouse, then sort the cells as
        ## we do in the current code (by mice, followed by qc count).
        ##

        mouse_data = nil
        mouse_data = data[:mice] if data[:mice]

        unless mouse_data.nil?
          mouse_data.each do |mouse|
            [ :"targeted non-conditional", :conditional ].each do |symbol|
              unless data[:es_cells][symbol].nil?
                # update the mouse status
                data[:es_cells][symbol][:cells].each do |es_cell|
                  if mouse[:escell_clone] == es_cell[:name]
                    es_cell.merge!({ "mouse?".to_sym => "yes" })
                    mouse.merge!({ :cassette => es_cell[:cassette], :cassette_type => es_cell[:cassette_type] })
                  end
                end

                # then sort (by mice > qc_count > name)
                data[:es_cells][symbol][:cells].sort! do |a, b|
                  res = b[:"mouse?"] <=> a[:"mouse?"]
                  res = b[:qc_count] <=> a[:qc_count] if res == 0
                  res = a[:name]     <=> b[:name]     if res == 0
                  res
                end
              end
            end
          end
        end

        ##
        ## Add the mutagenesis predictions and PCR primers
        ##

        unless ['KOMP-Regeneron','mirKO'].include?(data[:ikmc_project])
          mutagenesis_predictions        = get_mutagenesis_predictions( project_id )
          data[:mutagenesis_predictions] = mutagenesis_predictions[:data]
          errors.push( mutagenesis_predictions[:error] ) unless mutagenesis_predictions[:error].empty?
        end

        if ['KOMP-CSD','EUCOMM','mirKO'].include?(data[:ikmc_project])
          pcr_primers                    = get_pcr_primers( project_id, data )
          data[:pcr_primers]             = pcr_primers[:data]
          errors.push( pcr_primers[:error] ) unless pcr_primers[:error].empty?
        end

        ##
        ## Add the conf for the floxed exon display
        ##

        data.merge!( floxed_exon_display_conf( data ) )

        ##
        ## Add the coordinate information
        ##

        search_engine_data = search_engine_data( index, project_id )
        data.merge!( search_engine_data[:data] )  unless search_engine_data[:data].empty?
        errors.push( search_engine_data[:error] ) unless search_engine_data[:error].empty?

        ##
        ## Finally, categorize the stage of the pipeline that we are in
        ##

        data.merge!( get_pipeline_stage( data[:status]) ) if data[:status]
      end

      MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_ikmc_project_page_data - running get_ikmc_project_page_data( '#{project_id}' ) - DONE")

      return { :data => data, :errors => errors }
    end

    private

      # Helper function to perform quick searches against the Solr index
      #
      # @param  [MartSearch::Index] index      the MartSearch index object
      # @param  [String]            project_id the project ID
      # @return [Hash]
      def search_engine_data( index, project_id )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::search_engine_data - running search_engine_data( Index, '#{project_id}' )")

        results = handle_biomart_errors( "solr index", "This provides extra information on the project." ) do
          index.quick_search("ikmc_project_id:#{project_id}")
        end

        unless results[:data].blank?
          results[:data][0].symbolize_keys!

          # currently we only need the coordinate information
          results[:data] = {
            :chromosome  => results[:data][0][:chromosome],
            :coord_start => results[:data][0][:coord_start],
            :coord_end   => results[:data][0][:coord_end]
          }
        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::search_engine_data - running search_engine_data( Index, '#{project_id}' ) - DONE")

        return results
      end

      # Helper function to setup links to the floxed/deleted exons and all the config
      # needed for these activities in the templates.
      #
      # @param [Hash] data The current project page data hash
      # @return [Hash] The additional data required for the floxed exon display
      def floxed_exon_display_conf( data )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::floxed_exon_display_conf - running floxed_exon_display_conf")

        new_data = {}

        # Calculate the links to the Floxed/Deleted exons...
        exon_links = []
        unless data[:floxed_start_exon].nil?
          url = ensembl_link_url_from_exon( :mouse, data[:floxed_start_exon] )
          url = vega_link_url_from_exon( :mouse, data[:floxed_start_exon] ) if data[:floxed_start_exon] =~ /OTT/
          exon_links.push( '<a href="'+url+'" target="_blank">'+data[:floxed_start_exon]+'</a>' )
        end

        if !data[:floxed_end_exon].nil? && ( data[:floxed_start_exon] != data[:floxed_end_exon] )
          url = ensembl_link_url_from_exon( :mouse, data[:floxed_end_exon] )
          url = vega_link_url_from_exon( :mouse, data[:floxed_end_exon] ) if data[:floxed_end_exon] =~ /OTT/
          exon_links.push( '<a href="'+url+'" target="_blank">'+data[:floxed_end_exon]+'</a>' )
        end

        new_data[:floxed_exon_count] = exon_links.size
        new_data[:floxed_exon_link]  = exon_links.join(" - ")

        # Also, extablish id these are "Floxed" or "Deleted" exons...
        new_data[:deletion] = false
        new_data[:deletion] = true if data[:allele_design_type] == 'Deletion'

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::floxed_exon_display_conf - running floxed_exon_display_conf - DONE")

        return new_data
      end

      # Wrapper function to handle Biomart::BiomartErrors
      #
      # @param  [String] data_source - the biomart data source name
      # @param  [String] error_string - a brief explanation of potential errors
      # @param  [Block]  A block that queries the biomart
      # @return [Hash]   A hash containing the data and any errors
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

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::handle_biomart_errors - running handle_biomart_errors( '#{data_source}', '#{error_string}' ) - DONE")

        return results
      end

      # This function hits the ikmc-dcc mart for top level information
      # about the IKMC project ID being looked at.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] project_id The IKMC project ID
      # @return [Hash] The data relating to this project
      def get_top_level_project_info( datasources, project_id )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_top_level_project_info - running get_top_level_project_info( datasources, '#{project_id}' )")

        dcc_mart     = datasources[:'ikmc-dcc'].ds
        error_string = "This supplies information on gene identifiers and IKMC tracking information. This page will not work without this datasource."
        results      = handle_biomart_errors( "ikmc-dcc", error_string ) do
          dcc_mart.search({
            :process_results => true,
            :filters         => {'ikmc_project_id' => project_id },
            :attributes      => [
              'marker_symbol',   'mgi_accession_id', 'ensembl_gene_id',
              'vega_gene_id',    'ikmc_project',     'status',
              'mouse_available', 'escell_available', 'vector_available'
            ]
          })
        end

        unless results[:data].empty? or results[:data].nil?
          results[:data][0].symbolize_keys!
        else

          # assume if it doesn't contain a digit, it's rubbish
          if project_id && /\d/.match(project_id.to_s)
            # default to empty to ensure 404 is suppressed
            results = {
              :data=> [ { "marker_symbol"=>"", "mgi_accession_id"=>"", "ensembl_gene_id"=>"", "vega_gene_id"=>"", "ikmc_project"=>"",
                  "status"=>"", "mouse_available"=>"", "escell_available"=>"", "vector_available"=>""
                } ],
              :error=>{}
            }
          end

        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_top_level_project_info - running get_top_level_project_info( datasources, '#{project_id}' ) - DONE")

        return results
      end

      # This function hits the Ensembl (mouse) mart and looks for a human orthalog.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] ensembl_gene_id The (mouse) Ensembl ID to look for Human orthalogs of
      # @return [Hash] The data relating to the human orthalog
      def get_human_orthalog( datasources, ensembl_gene_id )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_human_orthalog - running get_human_orthalog( datasources, '#{ensembl_gene_id}' )")

        ens_mouse    = datasources[:'ensembl-mouse'].ds
        ens_human    = datasources[:'ensembl-human'].ds

        error_string = "This supplies information on the human ensembl gene orthalog. As a result this data will not be available on the page."
        results      = handle_biomart_errors( "ensembl-mouse", error_string ) do
          data      = {}
          mouse_res = ens_mouse.search({
            :process_results     => true,
            :filters             => { 'ensembl_gene_id' => ensembl_gene_id },
            :attributes          => [ 'human_ensembl_gene' ],
            :required_attributes => [ 'human_ensembl_gene' ]
          })

          unless mouse_res.empty?
            human_ensembl_gene        = mouse_res[0]['human_ensembl_gene']
            data[:human_ensembl_gene] = human_ensembl_gene

            human_res = ens_human.search({
              :process_results     => true,
              :filters             => { 'ensembl_gene_id' => human_ensembl_gene },
              :attributes          => [ 'ensembl_gene_id','chromosome_name','start_position','end_position' ],
              :required_attributes => [ 'chromosome_name' ]
            })

            unless human_res.empty?
              data[:human_ensembl_chromosome] = human_res[0]['chromosome_name']
              data[:human_ensembl_start]      = human_res[0]['start_position']
              data[:human_ensembl_end]        = human_res[0]['end_position']
            end
          end

          data
        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_human_orthalog - running get_human_orthalog( datasources, '#{ensembl_gene_id}' ) - DONE")

        return results
      end

      # This function hits the ikmc-imits mart for data on mice.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] escell_clones The escell clone names to search the mart by
      # @return [Hash] The data relating to mice for this project
      def get_mice( datasources, escell_clones )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_mice - running get_mice( datasources, '#{escell_clones}' )")

        qc_metrics  = [
          'qc_southern_blot',
          'qc_tv_backbone_assay',
          'qc_five_prime_lr_pcr',
          'qc_loa_qpcr',
          'qc_homozygous_loa_sr_pcr',
          'qc_neo_count_qpcr',
          'qc_lacz_sr_pcr',
          'qc_five_prime_cassette_integrity',
          'qc_neo_sr_pcr',
          'qc_mutant_specific_sr_pcr',
          'qc_loxp_confirmation',
          'genotyping_comment'
        ]

        imits_mart  = datasources[:'ikmc-imits'].ds
        targ_rep_mart = datasources[:'ikmc-idcc_targ_rep'].ds
        error_string  = "This supplies information on mouse breeding. As a result this data will not be available on the page."
        results       = handle_biomart_errors( "ikmc-imits", error_string ) do
          targ_rep_mart.search(
            :process_results => true,
            :filters => { 'escell_clone' => escell_clones },
            :attributes => [
              'escell_strain'
              #,
              #"distribution_qc_loa",
              #"distribution_qc_loxp",
              #"distribution_qc_lacz",
              #"distribution_qc_chr1",
              #"distribution_qc_chr8a",
              #"distribution_qc_chr8b",
              #"distribution_qc_chr11a",
              #"distribution_qc_chr11b",
              #"distribution_qc_chry"
            ],
            :federate => [
              {
                :dataset => imits_mart,
                :filters => {
                  'escell_clone'          => escell_clones,
                  'microinjection_status' => ['Genotype confirmed','Micro-injection in progress']
                },
                :attributes => [
                  'microinjection_status',
                  'marker_symbol',
                  'allele_symbol_superscript',
                  'mouse_allele_symbol_superscript',
                  'escell_clone',
                  'emma',
                  'production_centre',
                  'distribution_centre',
                  'colony_background_strain',
                  'test_cross_strain',
                  'is_active',
                  qc_metrics
                ].flatten
              }
            ]
          )
        end

        results[:data].reject! { |result| result['is_active'] == '0' }

        unless results[:data].empty?
          results[:data].recursively_symbolize_keys!

          mouse_results = { :genotype_confirmed => [], :mi_in_progress => [] }

          results[:data].each do |result|
            # Try and set the allele_name
            unless result[:allele_symbol_superscript].blank?
              result[:allele_name] = "#{result[:marker_symbol]}<sup>#{result[:allele_symbol_superscript]}</sup>"

              # Override the allele_name if we have a corrected one for the mouse...
              unless result[:mouse_allele_symbol_superscript].blank?
                result[:allele_name] = "#{result[:marker_symbol]}<sup>#{result[:mouse_allele_symbol_superscript]}</sup>"
              end

              result[:allele_type] = allele_type(result[:allele_name])
            end

            # Fix the strain names
            [:colony_background_strain, :test_cross_strain, :escell_strain].each do |strain_type|
              result[strain_type] = fix_superscript_text_in_attribute(result[strain_type]) unless result[strain_type].blank?
            end

            result[:genetic_background] = ikmc_imits_set_genetic_background(result)

            # Test for QC data - set each empty qc_metric to '-' or count it
            result[:qc_count] = 0
            qc_metrics.each do |metric|
              if result[metric.to_sym].nil?
                result[metric.to_sym] = '-'
              else
                result[:qc_count] = result[:qc_count] + 1
              end
            end

            # Now push the mouse into the correct category....
            if result[:microinjection_status] == 'Genotype confirmed'
              mouse_results[:genotype_confirmed].push(result)
            else
              mouse_results[:mi_in_progress].push(result)
            end
          end

          # sort the mice (by qc_count > escell_clone)
          [:genotype_confirmed, :mi_in_progress].each do |symbol|
            mouse_results[symbol].sort! do |a, b|
              res = a[:qc_count]     <=> b[:qc_count]
              res = a[:escell_clone] <=> b[:escell_clone] if res == 0
              res
            end
          end

          # Hide all non 'Genotype Confirmed' mice - until an undisclosed point in the future when we're
          # told to show them again...
          # results[:data] = { :mice => [ mouse_results[:genotype_confirmed], mouse_results[:mi_in_progress] ].flatten }
          results[:data] = { :mice => mouse_results[:genotype_confirmed] }
        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_mice - running get_mice( datasources, '#{escell_clones}' ) - DONE")

        return results
      end

      # This function hits the ikmc-idcc_targ_rep mart for data on the vectors and cells.
      #
      # @param [Hash] datasources The hash of prepared datasources from {MartSearch::Controller#datasources}
      # @param [String] project_id The IKMC project ID
      # @return [Hash] The data relating to this project
      def get_vectors_and_cells( datasources, project_id )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_vectors_and_cells - running get_vectors_and_cells( datasources, '#{project_id}' )")

        qc_metrics = [
          'production_qc_five_prime_screen',
          'production_qc_loxp_screen',
          'production_qc_three_prime_screen',
          'production_qc_loss_of_allele',
          'production_qc_vector_integrity',
          'distribution_qc_karyotype_high',
          'distribution_qc_karyotype_low',
          'distribution_qc_copy_number',
          'distribution_qc_five_prime_lr_pcr',
          'distribution_qc_five_prime_sr_pcr',
          'distribution_qc_three_prime_sr_pcr',
          'distribution_qc_thawing',
          'user_qc_southern_blot',
          'user_qc_map_test',
          'user_qc_karyotype',
          'user_qc_tv_backbone_assay',
          'user_qc_five_prime_lr_pcr',
          'user_qc_loss_of_wt_allele',
          'user_qc_neo_count_qpcr',
          'user_qc_lacz_sr_pcr',
          'user_qc_five_prime_cassette_integrity',
          'user_qc_neo_sr_pcr',
          'user_qc_mutant_specific_sr_pcr',
          'user_qc_loxp_confirmation',
          'user_qc_three_prime_lr_pcr',

          "distribution_qc_loa",
          "distribution_qc_loxp",
          "distribution_qc_lacz",
          "distribution_qc_chr1",
          "distribution_qc_chr8a",
          "distribution_qc_chr8b",
          "distribution_qc_chr11a",
          "distribution_qc_chr11b",
          "distribution_qc_chry"
        ]
        targ_rep_mart = datasources[:'ikmc-idcc_targ_rep'].ds
        error_string  = "This data source provides information on Targeting Vectors and ES Cells. As a result this data will not be available on the page."
        results       = handle_biomart_errors( "ikmc-ikmc-targ_rep", error_string ) do
          targ_rep_mart.search({
            :process_results => true,
            :filters         => { 'ikmc_project_id' => project_id },
            :attributes      => [
              'allele_id',
              'design_id',
              'mutation_subtype',
              'mutation_type',
              'mutation_method',
              'cassette',
              'cassette_type',
              'backbone',
              'allele_gb_file',
              'vector_gb_file',
              'intermediate_vector',
              'targeting_vector',
              'allele_symbol_superscript',
              'escell_clone',
              'floxed_start_exon',
              'floxed_end_exon',
              'parental_cell_line',
              'targ_vec_mutation_type',
              qc_metrics
            ].flatten
          })
        end

        data = {
          'intermediate_vectors' => [],
          'targeting_vectors'    => [],
          'es_cells'             => {
            'conditional'              => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil },
            'targeted non-conditional' => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }
          }
        }

        results[:data].each do |result|
          if result['vector_gb_file'] == 'yes'
            data['vector_image'] = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/vector-image"
            data['vector_gb']    = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
          end

          data['floxed_start_exon'] = result['floxed_start_exon']
          data['floxed_end_exon']   = result['floxed_end_exon']

          ##
          ## Intermediate Vectors
          ##

          unless result['targ_vec_mutation_type'] == 'Targeted Non Conditional'
            unless result['intermediate_vector'].nil?
              data['intermediate_vectors'].push(
                'name'              => result['intermediate_vector'],
                'design_id'         => result['design_id'],
                'design_type'       => allele_type( nil, result['targ_vec_mutation_type'] )
              )
            end
          end

          ##
          ## Targeting Vectors
          ##

          unless result['targ_vec_mutation_type'] == 'Targeted Non Conditional'
            unless result['targeting_vector'].nil?
              data['targeting_vectors'].push(
                'name'          => result['targeting_vector'],
                'design_id'     => result['design_id'],
                'design_type'   => allele_type( nil, result['targ_vec_mutation_type'] ),
                'cassette'      => result['cassette'],
                'cassette_type' => result['cassette_type'],
                'backbone'      => result['backbone']
              )
            end
          end

          ##
          ## ES Cells
          ##

          next if result['escell_clone'].nil?

          push_to = 'targeted non-conditional'
          push_to = 'conditional' if result['mutation_type'] == 'Conditional Ready'

          # Prepare the QC data
          qc_data = { 'qc_count' => 0 }
          qc_metrics.each do |metric|
            if result[metric].nil?
              qc_data[metric]     = '-'
            else
              qc_data[metric]     = result[metric]
              qc_data['qc_count'] = qc_data['qc_count'] + 1
            end
          end

          # Genbank files
          if result['allele_gb_file'] == 'yes'
            data['es_cells'][push_to]['allele_img'] = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/allele-image"
            data['es_cells'][push_to]['allele_gb']  = "http://www.knockoutmouse.org/targ_rep/alleles/#{result['allele_id']}/escell-clone-genbank-file"
          end

          data['es_cells'][push_to]['cells'].push(
            {
              'name'                      => result['escell_clone'],
              'allele_symbol_superscript' => result['allele_symbol_superscript'],
              'allele_type'               => allele_type( result['allele_symbol_superscript'], result['mutation_type'] ),
              'parental_cell_line'        => result['parental_cell_line'],
              'targeting_vector'          => result['targeting_vector'],
              'cassette'                  => result['cassette'],
              'cassette_type'             => result['cassette_type'],
              'mouse?'                    => 'no' # default to no
            }.merge(qc_data)
          )
        end

        unless data.empty?
          data['intermediate_vectors'].uniq!
          data['targeting_vectors'].uniq!

          # Uniqify the ES Cells...
          ["conditional", "targeted non-conditional"].each do |cond_vs_non|
            data["es_cells"][cond_vs_non]["cells"].uniq!
          end
        end

        results[:data] = data.recursively_symbolize_keys!

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_vectors_and_cells - running get_vectors_and_cells( datasources, '#{project_id}' ) - DONE")

        return results
      end

      # Helper function to determine how to draw the progress bar at the top of the
      # report page.
      #
      # @param [String] status The current projects status
      # @return [Hash] The configuration needed to draw the progress bar
      def get_pipeline_stage( status )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_pipeline_stage - running get_pipeline_stage( '#{status}' )")

        status_definitions = {
          # KOMP-CSD, EUCOMM, NorCOMM
          "On Hold"                                                 => { :stage => "pre",     :stage_type => "warn"   },
          "Transferred to NorCOMM"                                  => { :stage => "pre",     :stage_type => "error"  },
          "Transferred to KOMP"                                     => { :stage => "pre",     :stage_type => "error"  },
          "Withdrawn From Pipeline"                                 => { :stage => "pre",     :stage_type => "error"  },
          "Design Requested"                                        => { :stage => "designs", :stage_type => "normal" },
          "Alternate Design Requested"                              => { :stage => "designs", :stage_type => "warn"   },
          "VEGA Annotation Requested"                               => { :stage => "designs", :stage_type => "warn"   },
          "Design Not Possible"                                     => { :stage => "designs", :stage_type => "error"  },
          "Design Completed"                                        => { :stage => "designs", :stage_type => "normal" },
          "Vector Construction in Progress"                         => { :stage => "vectors", :stage_type => "normal" },
          "Vector Unsuccessful - Project Terminated"                => { :stage => "vectors", :stage_type => "error"  },
          "Vector Unsuccessful - Alternate Design in Progress"      => { :stage => "vectors", :stage_type => "warn"   },
          "Vector - Initial Attempt Unsuccessful"                   => { :stage => "vectors", :stage_type => "warn"   },
          "Vector Complete"                                         => { :stage => "vectors", :stage_type => "normal" },
          "Vector Complete - Project Terminated"                    => { :stage => "vectors", :stage_type => "error"  },
          "Vector - DNA Not Suitable for Electroporation"           => { :stage => "vectors", :stage_type => "warn"   },
          "ES Cells - Electroporation in Progress"                  => { :stage => "cells",   :stage_type => "normal" },
          "ES Cells - Electroporation Unsuccessful"                 => { :stage => "cells",   :stage_type => "error"  },
          "ES Cells - No QC Positives"                              => { :stage => "cells",   :stage_type => "warn"   },
          "ES Cells - Targeting  Unsuccessful - Project Terminated" => { :stage => "cells",   :stage_type => "error"  },
          "ES Cells - Targeting Confirmed"                          => { :stage => "cells",   :stage_type => "normal" },
          "Mice - Microinjection in progress"                       => { :stage => "mice",    :stage_type => "normal" },
          "Mice - Germline transmission"                            => { :stage => "mice",    :stage_type => "normal" },
          "Mice - Genotype confirmed"                               => { :stage => "mice",    :stage_type => "normal" },
          "Redesign Requested"                                      => { :stage => "designs", :stage_type => "normal" },
          "Mice - Phenotype Data Available"                         => { :stage => "mice",    :stage_type => "normal" },

          # KOMP-Regeneron
          "Regeneron Selected"                                      => { :stage => "pre",     :stage_type => "normal" },
          "Design Finished/Oligos Ordered"                          => { :stage => "designs", :stage_type => "normal" },
          "Parental BAC Obtained"                                   => { :stage => "vectors", :stage_type => "normal" },
          "BAC QC Failure"                                          => { :stage => "vectors", :stage_type => "error"  },
          "Targeting Vector Unsuccessful"                           => { :stage => "vectors", :stage_type => "error"  },
          "Targeting Vector QC Completed"                           => { :stage => "vectors", :stage_type => "normal" },
          "Vector Electroporated into ES Cells"                     => { :stage => "vectors", :stage_type => "normal" },
          "ES cell colonies picked"                                 => { :stage => "cells",   :stage_type => "normal" },
          "ES cell colonies screened / QC no positives"             => { :stage => "cells",   :stage_type => "warn"   },
          "ES cell colonies screened / QC one positive"             => { :stage => "cells",   :stage_type => "warn"   },
          "ES cell colonies screened / QC positives"                => { :stage => "cells",   :stage_type => "normal" },
          "ES Cell Clone Microinjected"                             => { :stage => "cells",   :stage_type => "normal" },
          "Germline Transmission Achieved"                          => { :stage => "mice",    :stage_type => "normal" }
        }

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_pipeline_stage - running get_pipeline_stage( '#{status}' ) - DONE")

        return status_definitions[ status ]
      end

      # Retrieve the mutagenesis predictions for the project_id from HTGT.
      #
      # @param  [String] project_id The IKMC project ID
      # @return [Hash] The output from the HTGT mutagenesis prediction tool
      def get_mutagenesis_predictions( project_id )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_mutagenesis_predictions - running get_mutagenesis_predictions( '#{project_id}' )")

        result  = { :data => {}, :error => {} }
        message = "There was a problem retrieving mutagenesis predictions for this project.  As a result this data will not be available on the page.  Please try refreshing your browser or come back in 10 minutes to obtain this data."
        begin
          uri         = URI.parse( "http://www.sanger.ac.uk/htgt/tools/mutagenesis_prediction/project/#{project_id}/detail" )
          http_client = build_http_client()
          response    = nil

          http_client.start( uri.host, uri.port ) do |http|
            http.read_timeout = 10
            http.open_timeout = 10
            response          = http.request( Net::HTTP::Get.new(uri.request_uri) )
          end

          unless response.code.to_i == 200
            raise Exception.new( "Mutagenesis prediction analysis unavailable." )
          end

          mutagenesis_data            = JSON.parse( response.body ).recursively_symbolize_keys!
          result[:data][:transcripts] = mutagenesis_data
          result[:data][:statistics]  = calculate_mutagenesis_prediction_stats( mutagenesis_data )
        rescue JSON::ParserError => error
          result[:error] = {
            :text  => message,
            :error => "Problem parsing the JSON returned.",
            :type  => error.class
          }
        rescue Exception => error
          result[:error] = {
            :text  => message,
            :error => error.to_s,
            :type  => error.class
          }
        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_mutagenesis_predictions - running get_mutagenesis_predictions( '#{project_id}' ) - DONE")

        return result
      end

      # Small helper function to calculate some top-level statistics for
      # the mutagenesis prediction tool.
      #
      # @param [Hash] transcripts The output from the HTGT mutagenesis prediction tool
      # @return [Hash] The statistics calculated off of the data
      def calculate_mutagenesis_prediction_stats( transcripts )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::calculate_mutagenesis_prediction_stats - running calculate_mutagenesis_prediction_stats()")

        count = {
          :wt_transcripts                 => 0,
          :wt_non_coding_transcripts      => 0,
          :wt_proteien_coding_transcripts => 0,
          :mut_nmd_transcripts            => 0,
          :mut_coding_transcripts         => 0,
          :mut_nmd_rescue_transcripts     => 0
        }

        transcripts.each do |transcript|
          count[:wt_transcripts] += 1
          if transcript[:biotype].eql?('protein_coding')
            count[:wt_proteien_coding_transcripts] += 1
            count[:mut_nmd_transcripts]            += 1 if transcript[:floxed_transcript_description] =~ /^No protein product \(NMD\)/
            count[:mut_coding_transcripts]         += 1 if transcript[:floxed_transcript_description] =~ /^No protein product \(NMD\)/ or transcript[:floxed_transcript_description] !~ /^No protein product^/
            count[:mut_nmd_rescue_transcripts]     += 1 if transcript[:floxed_transcript_description] =~ /^Possible NMD rescue/
          end
        end

        count[:wt_non_coding_transcripts] = count[:wt_transcripts] - count[:wt_proteien_coding_transcripts]

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::calculate_mutagenesis_prediction_stats - running calculate_mutagenesis_prediction_stats() - DONE")

        return count
      end

      # Retrieve the pcr primers for the project_id from HTGT.
      #
      # @param  [String] project_id The IKMC project ID
      # @return [Hash] The pcr primer hash from HTGT
      def get_pcr_primers( project_id, data )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_pcr_primers - running get_pcr_primers( '#{project_id}' )")

        result  = { :data => {}, :error => {} }
        message = "There was a problem retrieving pcr primers for this project.  As a result this data will not be available on the page.  Please try refreshing your browser or come back in 10 minutes to obtain this data."
        begin
          if data[:ikmc_project] == 'mirKO'
            design_id = data[:targeting_vectors][0][:design_id]
            if design_id.nil?
              raise Exception.new("Could not find design_id for project")
            end
            MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] :: get_pcr_primer mirKO sponsor, design = #{design_id} ")
            uri = URI.parse( "http://www.sanger.ac.uk/htgt/tools/genotypingprimers/mirko_primers/#{design_id}" )
          else
            uri = URI.parse( "http://www.sanger.ac.uk/htgt/tools/genotypingprimers/#{project_id}" )
          end
          http_client = build_http_client()
          response    = nil

          http_client.start( uri.host, uri.port ) do |http|
            http.read_timeout = 10
            http.open_timeout = 10
            response          = http.request( Net::HTTP::Get.new(uri.request_uri) )
          end

          raise Exception.new("PCR primer data unavailable.") unless response.code.to_i == 200

          raw_primer_data = JSON.parse( response.body ).recursively_symbolize_keys!
          result[:data]   = process_pcr_primers( raw_primer_data )
        rescue JSON::ParserError => error
          result[:error] = {
            :text  => message,
            :error => "Problem parsing the JSON returned.",
            :type  => error.class
          }
        rescue Exception => error
          result[:error] = {
            :text  => message,
            :error => error.to_s,
            :type  => error.class
          }
        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::get_pcr_primers - running get_pcr_primers( '#{project_id}' ) - DONE")

        return result
      end

      def process_pcr_primers( raw_primer_data )
        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::process_pcr_primers - running process_pcr_primers")

        processed_primers = {}

        raw_primer_data.each do |key,seq|
          case key
          when /^GF/  then processed_primers["5' Gene Specific (#{key})"] = seq
          when /^GR/  then processed_primers["3' Gene Specific (#{key})"] = seq
          when /^LAR/ then processed_primers["5' Universal (#{key})"]     = seq
          when /^RAF/ then processed_primers["3' Universal (#{key})"]     = seq
          when 'PNF'  then processed_primers["3' Universal (#{key})"]     = seq
          when 'R2R'  then processed_primers["3' Universal (#{key})"]     = seq
          end
        end

        MartSearch::Controller.instance().logger.debug("[MartSearch::ProjectUtils] ::process_pcr_primers - running process_pcr_primers - DONE")

        return processed_primers
      end
  end

end
