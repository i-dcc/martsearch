
# Read in the MP configuration file...
unless Module.const_defined?(:EUROPHENOME_MP_CONF)
  mp_conf_file = "#{MARTSEARCH_PATH}/config/server/dataviews/europhenome/mp_conf.json"
  EUROPHENOME_MP_CONF = JSON.load( File.open( mp_conf_file, 'r' ) ).recursively_symbolize_keys!
end