#!/usr/bin/env ruby

##
## This script is for re-generating the 'wt_expression_background_staining' 
## data in the config.json file.  There's no point grabbing this data 
## dynamically as it never changes (unless Jacqui or Jeanne tell us to...)
##

$:.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../../../../lib" )
require 'martsearch'

ms                  = MartSearch::Controller.instance()
images_mart         = ms.datasources[:'wtsi-phenotyping'].ds

background_images   = []
mouse_ids           = {}
selected_images_csv = DATA.read

parsed_csv = []
if CSV.const_defined? :Reader
  parsed_csv = CSV.parse( selected_images_csv, "," ) # Ruby < 1.9 CSV code
else
  parsed_csv = CSV.parse( selected_images_csv, { :col_sep => "," } ) # Ruby >= 1.9 CSV code
end

parsed_csv.shift
parsed_csv.each do |image_info|
  mouse_ids[ image_info[2] ] = [] if mouse_ids[ image_info[2] ].nil?
  mouse_ids[ image_info[2] ].push({ "order" => image_info[0], "image_id" => image_info[3]})
end

image_data = images_mart.search(
  :process_results => true,
  :filters => {
    "published_images_image_type" => "Wildtype Expression",
    "published_images_mouse_id"   => mouse_ids.keys
  },
  :attributes => [
    "published_images_colony_prefix",
    "published_images_mouse_id",
    "published_images_gender",
    "published_images_genotype",
    "published_images_age_at_death",
    "published_images_tissue",
    "published_images_image_type",
    "published_images_description",
    "published_images_annotations",
    "published_images_comments",
    "published_images_url"
  ]
)

# remove the 'published_images_' prefix from the attributes
prefix            = /^published\_images\_/
processed_results = []
image_data.each do |result|
  processed_result = {}
  result.each do |key,value|
    processed_result[ key.gsub(prefix,'') ] = value
  end
  processed_results.push(processed_result)
end
image_data = processed_results

image_data.each do |result|
  save_this_img = false
  
  mouse_ids[ result["mouse_id"] ].each do |img_conf|
    if result["url"].match( img_conf["image_id"] )
      save_this_img           = true
      result["thumbnail_url"] = result["url"].sub("\.(\w+)$","thumb.\1")
      result["order"]         = img_conf["order"]
    end
  end
  
  background_images[ result["order"].to_i - 1 ] = result if save_this_img
end

puts background_images.to_json

__END__
Picture number,Intensity,ID Mouse,ID picture,gene,organ
1,High,M00271301,7700,Cds2,Nasal cavity
2,Low,M00271153,7638,Btbd12,Nasal cavity
3,High,M00271301,7685,Cds2,Thyroid trachea
4,Low,M00271153,7629,Btbd12,Thyroid trachea
5,High,M00271301,7687,Cds2,Stomach
6,Low,M00271153,7631,Btbd12,Stomach
7,High,M00338500,9682,Ndufs3,Kidney
8,Low,M00271153,7632,Btbd12,Kidney
9,Overview,M00271301,7692,Cds2,urinary system
10,Close up,M00271301,7694,Cds2,close up of testis
11,Consistent,M00271153,7630,Btbd12,rib cage
12,Consistent,M00338500,9676,Ndufs3,Thymus
13,Consistent,M00338500,9678,Ndufs3,Mesenteric LN
14,High,M00338500,9685,Ndufs3,ovary
15,Low,M00271155,7613,Btbd12,ovary
