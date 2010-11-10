#!/usr/bin/env ruby

$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../../../../lib" )
require 'martsearch'

ontology_cache = MartSearch::Controller.instance().ontology_cache

config = {}
setup  = {
  'Brain'                      => [ 7469 ],
  'Spinal Cord'                => [ 7671, 8404 ],
  'CNS Nerves'                 => [ 7650 ],
  'Peripheral Nervous System'  => [ 7690, 8406 ],
  'Ganglia'                    => [ 7637, 7692 ],
  'Ear'                        => [ 7729 ],
  'Eye'                        => [ 7786 ],
  'Nose'                       => [ 7828 ],
  'Alimentary System'          => [ 7437 ],
  'Salivary Gland'             => [ 7440 ],
  'Stomach and Gut'            => [ 7450 ],
  'Liver'                      => [ 8191 ],
  'Pancreas'                   => [ 7453 ],
  'Respiratory System'         => [ 8276 ],
  'Cardiovascular System'      => [ 7851 ],
  'Heart'                      => [ 7907 ],
  'Renal/Urinary System'       => [ 8217 ],
  'Reproductive System'        => [ 8244 ],
  'Adrenal Gland'              => [ 7430 ],
  'Haemolymphoid System'       => [ 7433, 12664 ],
  'Skeleton'                   => [ 8338, 8410 ],
  'Skeletal Muscles'           => [ 12646, 12664, 7384, 8050, 7796 ],
  'Limb'                       => [ 7177 ],
  'Skin'                       => [ 7184, 7192, 7199, 7206, 7220, 7227, 7234, 7241, 7248, 7253, 7258, 7263, 7268, 7273, 7283, 7290, 7297, 7304, 7311, 7316, 7321, 7326, 7331, 7339, 7348, 7358, 7366, 7377, 7496 ],
  'Cavities and their Linings' => [ 7149 ]
}

setup.each do |title,emap_terms|
  puts "Checking #{title}"
  terms_to_look_for = []
  terms_and_counts  = {}
  
  emap_terms.each do |term|
    terms_to_look_for << "EMAP:#{term}"
    terms_to_look_for << ontology_cache.fetch("EMAP:#{term}").all_child_terms
  end
  
  terms_to_look_for.flatten!.uniq!
  
  terms_to_look_for.each do |term|
    terms_and_counts[term] = ontology_cache.fetch(term).all_child_terms.size + 1
  end
  
  config[title] = {
    'all_terms' => terms_to_look_for,
    'counts'    => terms_and_counts
  }
end

File.open('eurexpress_chart_conf.json','w') do |file|
  file.write config.to_json
end
