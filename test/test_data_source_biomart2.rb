# encoding: utf-8

#require 'pp'
require 'test_helper'

class MartSearchBiomartDataSourceTest2 < Test::Unit::TestCase

  context 'A MartSearch::BiomartDataSource object' do

    def build_datasources( config_dir )
      datasources     = {}
      datasource_conf = JSON.load( File.new( "#{config_dir}/datasources.json", 'r' ) )
      datasource_conf.recursively_symbolize_keys!
      datasource_conf.each do |ds_name,ds_conf|
        ds_conf[:internal_name] = ds_name
        datasources[ ds_name ]  = MartSearch.const_get("#{ds_conf[:type]}DataSource").new( ds_conf )
      end

      return datasources
    end

    def process_dataviews_conf( config_dir, dataviews_conf )
      dataviews         = []
      dataviews_by_name = {}

      dataviews_conf.each do |dv_name|
        dv_location = "#{config_dir}/dataviews/#{dv_name}"
        dv_conf     = JSON.load( File.new( "#{dv_location}/config.json", 'r' ) )

        dv_conf.recursively_symbolize_keys!

        if dv_conf[:enabled]
          dv_conf[:internal_name] = dv_name
          dataview                = MartSearch::DataView.new( dv_conf )

          dataview.stylesheet      = File.read("#{dv_location}/stylesheet.css")     if dv_conf[:custom_css]
          dataview.javascript_head = File.read("#{dv_location}/javascript_head.js") if dv_conf[:custom_head_js]
          dataview.javascript_base = File.read("#{dv_location}/javascript_base.js") if dv_conf[:custom_base_js]

          dataviews.push( dataview )
          dataviews_by_name[dv_name] = dataview
        end
      end

      { :dataviews => dataviews, :dataviews_by_name => dataviews_by_name }
    end

    should 'test all datasources' do
      config_dir = 'config'
      datasources = build_datasources( config_dir )

      filters = {
        'idcc_targ_rep' => { 'mgi_accession_id' => "MGI:2443076" },
        'genes_targ_rep' => { 'mgi_accession_id' => "MGI:2443076" },
        'imits' => { 'mgi_accession_id' => "MGI:2443076" },
        'imits2' => { 'mgi_accession_id' => "MGI:2443076" },
        'omim' => { 'mgi_accession_id' => "MGI:3648653" },
        'bacs' => { 'marker_symbol' => "cbx1" },
      }

      biomart_count = 0

      include = %W{genes_targ_rep imits2}

      datasources.keys.each do |key|

        conf = datasources[key].instance_variable_get("@conf")
        next if ! include.include? conf[:dataset]

        next if conf[:type] != 'Biomart'

        internal_name = conf[:internal_name]

        next if conf[:url] !~ /knockoutmouse|sanger/

        if ! File.exists? "config/server/datasets/#{internal_name}/config.json"
          puts "### warning: cannot find config file for dataset #{conf[:dataset]}"
          next
        end

        if ! filters.has_key?(conf[:dataset])
          puts "### warning: cannot find filter for dataset #{conf[:dataset]}"
          next
        end

      #  puts "#### running #{conf[:internal_name]}"

        ds_conf = JSON.load( File.new( "config/server/datasets/#{conf[:internal_name]}/config.json", 'r' ) )

        results = datasources[key].ds.search({
          :process_results => true,
          :filters         => filters[conf[:dataset]],
          :attributes      => ds_conf['searching']["attributes"].flatten
        })

        assert( results && results.size > 0 )

        failures = []
        ds_conf['searching']["attributes"].each do |key|
          failures.push(key) if ! results[0].has_key?(key)
        end

        assert( failures.size == 0, "Failed to find following attributes: #{failures.join(', ')}" )

        biomart_count += 1

      end

   #   puts "#### biomart_count: #{biomart_count}"
    end

  end

end
