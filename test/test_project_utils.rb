require "test_helper"
require "json"

class TestMartSearchProjectUtils < Test::Unit::TestCase
  include MartSearch::ProjectUtils
  public  :get_top_level_project_info, :get_human_orthalog, :get_mice, :get_mutagenesis_predictions
  
  context "A valid MartSearch Project" do
    setup do
      VCR.insert_cassette( "test_project_utils" )
      @datasources = MartSearch::Controller.instance().datasources
      @project_id  = 35505
    end

    should "have top level information" do
      expected = {
        :marker_symbol    => "Cbx1",
        :mgi_accession_id => "MGI:105369",
        :ensembl_gene_id  => "ENSMUSG00000018666",
        :vega_gene_id     => "OTTMUSG00000001636",
        :ikmc_project     => "EUCOMM",
        :status           => "Mice - Genotype confirmed",
        :mouse_available  => "1",
        :escell_available => "1",
        :vector_available => "1"
      }
      assert_equal( expected, get_top_level_project_info( @datasources, @project_id )[:data][0] )
    end

    should "have the correct human orthalog" do
      expected = { :human_ensembl_gene => "ENSG00000108468" }
      assert_equal( expected, get_human_orthalog( @datasources, "ENSMUSG00000018666" )[:data][0] )
    end

    should "have the expected results" do
      expected_int_vectors = [
        {
          :name        => "PCS00019_A_B11",
          :design_id   => "39792",
          :design_type => "Conditional (Frameshift)",
          :floxed_exon => "ENSMUSE00000110990"
        }
      ]
      expected_targ_vectors = [
        {
          :name        => "PG00019_A_1_B11",
          :design_id   => "39792",
          :design_type => "Conditional (Frameshift)",
          :cassette    => "L1L2_gt2",
          :backbone    => "L3L4_pZero_kan",
          :floxed_exon => "ENSMUSE00000110990"
        },
        {
          :name        => "PG00019_A_2_B11",
          :design_id   => "39792",
          :design_type => "Conditional (Frameshift)",
          :cassette    => "L1L2_gt2",
          :backbone    => "L3L4_pZero_kan",
          :floxed_exon => "ENSMUSE00000110990"
        },
        {
          :name        => "PG00019_A_3_B11",
          :design_id   => "39792",
          :design_type => "Conditional (Frameshift)",
          :cassette    => "L1L2_gt2",
          :backbone    => "L3L4_pZero_kan",
          :floxed_exon => "ENSMUSE00000110990"
        },
        {
          :name        => "PG00019_A_4_B11",
          :design_id   => "39792",
          :design_type => "Conditional (Frameshift)",
          :cassette    => "L1L2_gt2",
          :backbone    => "L3L4_pZero_kan",
          :floxed_exon => "ENSMUSE00000110990"
        },
        {
          :name        => "PGS00019_A_B11",
          :design_id   => "39792",
          :design_type => "Conditional (Frameshift)",
          :cassette    => "L1L2_gt2",
          :backbone    => "L3L4_pZero_kan",
          :floxed_exon => "ENSMUSE00000110990"
        }
      ]
      expected_cells = {
        :conditional => {
          :cells => [
            {
              :name                                  => "EPD0027_2_B01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "yes",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_A02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_B03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_C01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_C03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_E01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_E02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_F01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_F02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_F03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_A01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 4,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "fail",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_H01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 5,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "pass",
              :distribution_qc_three_prime_sr_pcr    => "pass",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_H02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 5,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "pass",
              :distribution_qc_three_prime_sr_pcr    => "pass",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_H03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 5,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "pass",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "pass",
              :distribution_qc_three_prime_sr_pcr    => "pass",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            }
          ],
          :allele_img  => "http://www.knockoutmouse.org/targ_rep/alleles/902/allele-image",
          :allele_gb   => "http://www.knockoutmouse.org/targ_rep/alleles/902/escell-clone-genbank-file",
          :design_type => "Conditional (Frameshift)"
        },
        :"targeted non-conditional" => {
          :cells => [
            {
              :name                                  => "EPD0027_2_A03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_B02",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_D01",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "fail",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_D02",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "fail",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_D03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "fail",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_E03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_G01",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_G02",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            },
            {
              :name                                  => "EPD0027_2_G03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "fail",
              :production_qc_three_prime_screen      => "pass",
              :production_qc_loss_of_allele          => "-",
              :production_qc_vector_integrity        => "-",
              :distribution_qc_karyotype_high        => "-",
              :distribution_qc_karyotype_low         => "-",
              :distribution_qc_copy_number           => "-",
              :distribution_qc_five_prime_lr_pcr     => "-",
              :distribution_qc_five_prime_sr_pcr     => "-",
              :distribution_qc_three_prime_sr_pcr    => "-",
              :distribution_qc_thawing               => "-",
              :user_qc_southern_blot                 => "-",
              :user_qc_map_test                      => "-",
              :user_qc_karyotype                     => "-",
              :user_qc_tv_backbone_assay             => "-",
              :user_qc_five_prime_lr_pcr             => "-",
              :user_qc_loss_of_wt_allele             => "-",
              :user_qc_neo_count_qpcr                => "-",
              :user_qc_lacz_sr_pcr                   => "-",
              :user_qc_five_prime_cassette_integrity => "-",
              :user_qc_neo_sr_pcr                    => "-",
              :user_qc_mutant_specific_sr_pcr        => "-",
              :user_qc_loxp_confirmation             => "-",
              :user_qc_three_prime_lr_pcr            => "-"
            }
          ],
          :allele_img  => "http://www.knockoutmouse.org/targ_rep/alleles/903/allele-image",
          :allele_gb   => "http://www.knockoutmouse.org/targ_rep/alleles/903/escell-clone-genbank-file",
          :design_type => "Targeted, Non-Conditional"
        }
      }
      expected_mice = {
        :genotype_confirmed => [
          {
            :status                        => "Genotype Confirmed",
            :allele_name                   => "Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>",
            :escell_clone                  => "EPD0027_2_B01",
            :emma                          => "1",
            :escell_strain                 => "C57BL/6N",
            :escell_line                   => "JM8.N4 (p10)",
            :mi_centre                     => "WTSI",
            :distribution_centre           => "WTSI",
            :qc_southern_blot              => "-",
            :qc_tv_backbone_assay          => "pass",
            :qc_five_prime_lr_pcr          => "na",
            :qc_loa_qpcr                   => "na",
            :qc_homozygous_loa_sr_pcr      => "pass",
            :qc_neo_count_qpcr             => "pass",
            :qc_lacz_sr_pcr                => "pass",
            :qc_five_prime_cass_integrity  => "pass",
            :qc_neo_sr_pcr                 => "na",
            :qc_mutant_specific_sr_pcr     => "pass",
            :qc_loxp_confirmation          => "pass",
            :qc_three_prime_lr_pcr         => "na",
            :qc_count                      => 11
          }
        ],
        :mi_in_progress => []
      }

      # sort the es cells ...
      [ ':targeted non-conditional', :conditional ].each do |symbol|
        unless expected_cells[symbol].nil?
          expected_cells[symbol][:cells].sort! { |x,y| x[:name] <=> y[:name] }
        end
      end

      assert_equal( expected_int_vectors, get_ikmc_project_page_data( @project_id )[:data][:intermediate_vectors] )
      assert_equal( expected_targ_vectors, get_ikmc_project_page_data( @project_id )[:data][:targeting_vectors] )

      # sort the es cells here as well ...
      observed_cells = get_ikmc_project_page_data( @project_id )[:data][:es_cells]
      [ ':targeted non-conditional', :conditional ].each do |symbol|
        unless expected_cells[symbol].nil?
          observed_cells[symbol][:cells].sort! { |x,y| x[:name] <=> y[:name] }
        end
      end

      assert_equal( expected_cells, observed_cells )
      assert_equal( expected_mice, get_ikmc_project_page_data( @project_id )[:data][:mice] )
    end

    should "have mutagenesis predictions" do
      assert_nothing_raised do
        get_mutagenesis_predictions @project_id
      end
    end

    should "not throw any exceptions with no mice" do
      assert_nothing_raised do
        get_ikmc_project_page_data( 42474 )
      end
    end

    should "return the correct data with more than one mouse" do
      project_id    = 40343
      expected_data = JSON.parse( File.read( File.dirname( __FILE__ ) + "/fixtures/test_project_utils-project_id_#{project_id}.json" ) )
      expected_data.recursively_symbolize_keys!()
      observed_data = get_ikmc_project_page_data( project_id )[:data]
      
      ##
      ## Sort the relevant bits of data
      ##
      
      [ :conditional, :"targeted non-conditional" ].each do |symbol|
        expected_data[:es_cells][symbol][:cells].uniq!
        expected_data[:es_cells][symbol][:cells].sort! do |a, b|
          res = b[:"mouse?"] <=> a[:"mouse?"]
          res = b[:qc_count] <=> a[:qc_count] if res == 0
          res = a[:name]     <=> b[:name]     if res == 0
          res
        end
      end
      
      [ :genotype_confirmed, :mi_in_progress ].each do |symbol|
        expected_data[:mice][symbol].sort! do |a, b|
          res = a[:qc_count]     <=> b[:qc_count]
          res = a[:escell_clone] <=> b[:escell_clone] if res == 0
          res
        end
      end
      
      # So... test top-level data first
      top_level_keys = [
          :project_id,
          :marker_symbol,
          :mgi_accession_id,
          :ensembl_gene_id,
          :vega_gene_id,
          :ikmc_project,
          :status,
          :mouse_available,
          :escell_available,
          :vector_available,
          :human_ensembl_gene,
          :intermediate_vectors,
          :targeting_vectors,
          :vector_image,
          :vector_gb,
          :stage,
          :stage_type
      ]
      top_level_keys.each do |key|
        # puts "testing '#{key}' - exp: '#{expected_data[key]}' vs obs: '#{observed_data[key]}'"
        assert_equal expected_data[key], observed_data[key]
      end
      
      # Now mice...
      [ :genotype_confirmed, :mi_in_progress ].each do |status|
        expected_data[:mice][status][0].keys.each do |key|
          expected_data[:mice][status].each_index do |index|
            # puts "mice: testing [:mice][:#{status}][#{index}][:#{key}] - exp: '#{expected_data[:mice][status][index][key]}' vs obs: '#{observed_data[:mice][status][index][key]}'"
            assert_equal( expected_data[:mice][status][index][key], observed_data[:mice][status][index][key], "Mouse data has changed... We're now getting: \n\n #{observed_data[:mice].to_json}" )
          end
        end
      end
      
      # And cells...
      [ :conditional, :"targeted non-conditional" ].each do |status|
        expected_data[:es_cells][status][:cells][0].keys.each do |key|
          expected_data[:es_cells][status][:cells].each_index do |index|
            # puts "cells: testing [:es_cells][:#{status}][:cells][#{index}][:#{key}] - exp: '#{expected_data[:es_cells][status][:cells][index][key]}' vs obs: '#{observed_data[:es_cells][status][:cells][index][key]}'"
            assert_equal( expected_data[:es_cells][status][:cells][index][key], observed_data[:es_cells][status][:cells][index][key], "Cell data has changed... We're now getting: \n\n #{observed_data[:es_cells].to_json}" )
          end
        end
      end
    end
    
    should "not crash with *NoMethodError* when data is requested for projects in status *Redesign Requested*" do
      project_ids = [ 80797, 92475 ]
      project_ids.each do |project_id|
        assert_nothing_raised do
          get_ikmc_project_page_data( project_id )
        end
      end
    end

    teardown do
      VCR.eject_cassette
    end
  end
end
