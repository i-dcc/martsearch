# encoding: utf-8

module MartSearch
  module ServerViewHelpers

    # View helpers for creating order buttons for IKMC products.
    #
    # @author Darren Oakley
    module OrderButtons

    extend MartSearch::Utils
    include MartSearch::Utils

    # routine to get order urls from solr

    def get_order_url_from_solr(hash)
      return nil if ! hash[:type] || ! hash[:product_type] || ! hash[:mgi_accession_id]

      http_client = build_http_client()

      type = hash[:type]
      product_type = hash[:product_type]
      mgi_accession_id = hash[:mgi_accession_id].gsub(/MGI:/i, '')

      url = "http://ikmc.vm.bytemark.co.uk:8983/solr/allele/select/?q=type:#{type}%20product_type:#{product_type}%20mgi_accession_id:#{mgi_accession_id}&wt=json"

      res = http_client.get( URI.parse(url) )

      object = JSON.parse(res)

      return nil if object["response"]["numFound"] != 1

      order_from_urls = object['response']['docs'][0]['order_from_urls']
      order_from_names = object['response']['docs'][0]['order_from_names']

      return nil if order_from_urls.size != order_from_names.size

      return order_from_urls[0]
    end

      # Helper function to centralise the logic for producing a button for
      # ordering a mouse.
      #
      # @param [String] mgi_accession_id The MGI accession ID for the gene
      # @param [String] marker_symbol The marker symbol for the gene
      # @param [String] project The IKMC project name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
      # @param [String] project_id The IKMC project ID
      # @param [Boolean] flagged_for_dist Whether the mouse has been flagged as available at the repositories
      # @param [String] mi_centre The microinjection centre for the mouse
      # @param [String] dist_centre The distribution centre for the mouse
      # @return [String] The html markup for a button
      def mouse_order_button( mgi_accession_id, marker_symbol, project, project_id, flagged_for_dist, mi_centre='', dist_centre='' )
        order_url        = ikmc_product_order_url( :mouse, project, project_id, mgi_accession_id, marker_symbol )
        express_interest = false

        hash = {}
        hash[:type] = 'mi_attempt'
        hash[:product_type] = 'Mouse'
        hash[:mgi_accession_id] = mgi_accession_id

        order_url = get_order_url_from_solr(hash)

        button_text = generic_order_button2( project, order_url )

        return button_text
      end

      # Helper function to build an order button Non-IKMC EMMA lines.
      #
      # @param [String] emma_id The EMMA id for this line
      # @return [String] The html markup for a button
      def emma_mouse_order_button( emma_id )
        url         = emma_link_url( emma_id )
        button_text = generic_order_button( 'Non-IKMC', url )
      end

      # Helper function to centralise the logic for producing a button for
      # ordering an ES cell.
      #
      # @param [String] mgi_accession_id The MGI accession ID for the gene
      # @param [String] marker_symbol The marker symbol for the gene
      # @param [String] project The IKMC project name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
      # @param [String] project_id The IKMC project ID
      # @param [String] escell_clone The ES Cell to order
      # @return [String] The html markup for a button
      def escell_order_button( mgi_accession_id, marker_symbol, project, project_id, escell_clone=nil )
        order_url   = ikmc_product_order_url( :escell, project, project_id, mgi_accession_id, marker_symbol )
        order_url   = "#{order_url}&comments1=#{escell_clone}" if project == 'TIGM'
        button_text = generic_order_button( project, order_url )
        return button_text
      end

      # Helper function to centralise the logic for producing a button for
      # ordering a vector.
      #
      # @param [String] mgi_accession_id The MGI accession ID for the gene
      # @param [String] marker_symbol The marker symbol for the gene
      # @param [String] project The IKMC project name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
      # @param [String] project_id The IKMC project ID
      # @return [String] The html markup for a button
      def vector_order_button( mgi_accession_id, marker_symbol, project, project_id )
        order_url   = ikmc_product_order_url( :vector, project, project_id, mgi_accession_id, marker_symbol )
        button_text = generic_order_button( project, order_url )
        return button_text
      end

      private

        # Helper function to centralise the generation of product ordering links.
        #
        # @param [Symbol] product_type The type of product to get a link for [:vector,:es_cell,:mouse]
        # @param [String] pipeline The IKMC pipeline name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
        # @param [String] project_id The IKMC project ID
        # @param [String] mgi_acc_id The MGI accession ID for the gene
        # @param [String] marker_symbol The marker_symbol for the gene
        # @return [Hash] A hash containing all of the relevant urls for this project
        def ikmc_product_order_url( product_type, project=nil, project_id=nil, mgi_accession_id=nil, marker_symbol=nil )
          order_url = case project
          when "KOMP"           then "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
          when "KOMP-CSD"       then "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
          when "KOMP-Regeneron" then "http://www.komp.org/geneinfo.php?project=#{project_id}"
          when "NorCOMM"        then "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
          when "TIGM"           then "http://www.tigm.org/cgi-bin/tigminfo.cgi?survey=IKMC%20Website&mgi1=#{mgi_accession_id}&gene1=#{marker_symbol}"
          when "EUCOMM"
            case product_type
            when :vector  then "http://www.eummcr.org/final_vectors.php?mgi_id=#{mgi_accession_id}"
            when :escell  then "http://www.eummcr.org/es_cells.php?mgi_id=#{mgi_accession_id}"
            when :mouse   then "http://www.emmanet.org/mutant_types.php?keyword=#{marker_symbol}%25EUCOMM&select_by=InternationalStrainName&search=ok"
            else
              "http://www.eummcr.org/order.php"
            end
          when "mirKO" then "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?SourceCollection=Sanger%20MirKO&jboEvent=Search&LowerCaseSymbol=#{marker_symbol}"
          else
            ""
          end

          return order_url
        end

        # Simple helper that produces the HTML text for an order button.
        #
        # @param [String] project The IKMC pipeline name ['KOMP/KOMP-CSD','KOMP-Regeneron','NorCOMM','EUCOMM','mirKO']
        # @param [String] order_url The URL for the button to link to
        # @param [Boolean] express_interest
        # @return The HTML markup for the order button
        def generic_order_button( project, order_url, express_interest=false )
          button_text      = '<span class="order unavailable">currently&nbsp;unavailable</span>'

          text = project == 'mirKO' ? 'order from MMRRC' : 'order'

          if express_interest
            button_text = "<a href=\"#{order_url}\" class=\"order2 express_interest\">express&nbsp;interest</a>"
          elsif !order_url.empty?
            button_text = "<a href=\"#{order_url}\" class=\"order2\" target=\"_blank\">#{text}</a>"
          end

          # blag to add the new order button
          # we just add new text to the original button if we're a mirKO project
          # we just add the new button if we're a mirKO project

          button_text += mirko_order_button(project)

          return button_text
        end

        def generic_order_button2( project, order_url )
          button_text      = '<span class="order unavailable">currently&nbsp;unavailable</span>'

          text = 'contact distributor'

          if ! order_url.empty?
            button_text = "<a href=\"#{order_url}\" class=\"order2\" target=\"_blank\">#{text}</a>"
          end

          # blag to add the new order button
          # we just add new text to the original button if we're a mirKO project
          # we just add the new button if we're a mirKO project

          button_text += mirko_order_button(project)

          return button_text
        end

        # Helper function to centralise the logic for producing a button for mirKO

        def mirko_order_button( project='unknown' )
          return '' if project != 'mirKO'
          order_url = 'http://www.eummcr.org/order.php'
          return "<br/><a href=\"#{order_url}\" class=\"order2\" target=\"_blank\">order from EUMMCR</a>"
        end

    end

  end
end
