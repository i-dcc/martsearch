# encoding: utf-8

require "test_helper"

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
        :status           => "Mice - Phenotype Data Available",
        :mouse_available  => "1",
        :escell_available => "1",
        :vector_available => "1"
      }
      assert_equal( expected, get_top_level_project_info( @datasources, @project_id )[:data][0] )
    end

    should "have the expected results" do
      expected_int_vectors = [
        {
          :name               => "PCS00019_A_B11",
          :design_id          => "39792",
          :design_type        => "Knockout First, Reporter-tagged insertion with conditional potential"
        }
      ]
      expected_targ_vectors = [
        {
          :name           => "PG00019_A_1_B11",
          :design_id      => "39792",
          :design_type    => "Knockout First, Reporter-tagged insertion with conditional potential",
          :cassette       => "L1L2_gt2",
          :cassette_type  => "Promotorless",
          :backbone       => "L3L4_pZero_kan",
        },
        {
          :name           => "PG00019_A_2_B11",
          :design_id      => "39792",
          :design_type    => "Knockout First, Reporter-tagged insertion with conditional potential",
          :cassette       => "L1L2_gt2",
          :cassette_type  => "Promotorless",
          :backbone       => "L3L4_pZero_kan"
        },
        {
          :name           => "PG00019_A_3_B11",
          :design_id      => "39792",
          :design_type    => "Knockout First, Reporter-tagged insertion with conditional potential",
          :cassette       => "L1L2_gt2",
          :cassette_type  => "Promotorless",
          :backbone       => "L3L4_pZero_kan"
        },
        {
          :name           => "PG00019_A_4_B11",
          :design_id      => "39792",
          :design_type    => "Knockout First, Reporter-tagged insertion with conditional potential",
          :cassette       => "L1L2_gt2",
          :cassette_type  => "Promotorless",
          :backbone       => "L3L4_pZero_kan"
        },
        {
          :name           => "PGS00019_A_B11",
          :design_id      => "39792",
          :design_type    => "Knockout First, Reporter-tagged insertion with conditional potential",
          :cassette       => "L1L2_gt2",
          :cassette_type  => "Promotorless",
          :backbone       => "L3L4_pZero_kan"
        }
      ]
      expected_cells = {
        :conditional => {
          :cells => [
            {
              :name                                  => "EPD0027_2_B01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_A02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_B03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_C01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_C03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_E01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_E02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_F01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_F02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_F03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_A01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_H01",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_H02",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_H03",
              :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
              :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            }
          ],
          :allele_img  => "http://www.knockoutmouse.org/targ_rep/alleles/902/allele-image",
          :allele_gb   => "http://www.knockoutmouse.org/targ_rep/alleles/902/escell-clone-genbank-file",
        },
        :"targeted non-conditional" => {
          :cells => [
            {
              :name                                  => "EPD0027_2_A03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_B02",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_D01",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
              :production_qc_three_prime_screen      => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_D02",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
              :production_qc_three_prime_screen      => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_D03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
              :production_qc_three_prime_screen      => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_E03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_G01",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_G02",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            },
            {
              :name                                  => "EPD0027_2_G03",
              :allele_symbol_superscript             => "tm1e(EUCOMM)Wtsi",
              :allele_type                           => "Targeted Non-Conditional",
              :parental_cell_line                    => "JM8.N4",
              :targeting_vector                      => "PGS00019_A_B11",
              :cassette                              => "L1L2_gt2",
              :cassette_type                         => "Promotorless",
              :"mouse?"                              => "no",
              :qc_count                              => 3,
              :production_qc_five_prime_screen       => "pass",
              :production_qc_loxp_screen             => "not confirmed",
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
              :user_qc_three_prime_lr_pcr            => "-",
              :distribution_qc_chr1                  => "-",
              :distribution_qc_chr11a                => "-",
              :distribution_qc_chr11b                => "-",
              :distribution_qc_chr8a                 => "-",
              :distribution_qc_chr8b                 => "-",
              :distribution_qc_chry                  => "-",
              :distribution_qc_lacz                  => "-",
              :distribution_qc_loa                   => "-",
              :distribution_qc_loxp                  => "-"
            }
          ],
          :allele_img  => "http://www.knockoutmouse.org/targ_rep/alleles/903/allele-image",
          :allele_gb   => "http://www.knockoutmouse.org/targ_rep/alleles/903/escell-clone-genbank-file",
        }
      }
      expected_mice = [
        {
          :allele_name                           => "Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>",
          :allele_symbol_superscript             => "tm1a(EUCOMM)Wtsi",
          :allele_type                           => "Knockout First, Reporter-tagged insertion with conditional potential",
          :cassette                              => "L1L2_gt2",
          :cassette_type                         => "Promotorless",
          :colony_background_strain              => "C57BL/6Dnk",
          :distribution_centre                   => "Harwell",
          :emma                                  => "1",
          :escell_clone                          => "EPD0027_2_B01",
          :escell_strain                         => "C57BL/6N",
          :genetic_background                    => "C57BL/6Dnk;C57BL/6Brd-Tyr<sup>c-Brd</sup>;C57BL/6N",
          :is_active                             => "1",
          :marker_symbol                         => "Cbx1",
          :microinjection_status                 => "Genotype confirmed",
          :mouse_allele_symbol_superscript       => nil,
          :production_centre                     => "WTSI",
          :qc_count                              => 11,
          :qc_five_prime_cassette_integrity      => "pass",
          :qc_five_prime_lr_pcr                  => "na",
          :qc_homozygous_loa_sr_pcr              => "pass",
          :qc_lacz_sr_pcr                        => "pass",
          :qc_loa_qpcr                           => "pass",
          :qc_loxp_confirmation                  => "pass",
          :qc_mutant_specific_sr_pcr             => "pass",
          :qc_neo_count_qpcr                     => "pass",
          :qc_neo_sr_pcr                         => "na",
          :qc_southern_blot                      => "na",
          #:qc_three_prime_lr_pcr                 => nil,
          :qc_tv_backbone_assay                  => "pass",
          :test_cross_strain                     => "C57BL/6Brd-Tyr<sup>c-Brd</sup>",
          #:distribution_qc_chr1                  => nil,
          #:distribution_qc_chr11a                => nil,
          #:distribution_qc_chr11b                => nil,
          #:distribution_qc_chr8a                 => nil,
          #:distribution_qc_chr8b                 => nil,
          #:distribution_qc_chry                  => nil,
          #:distribution_qc_lacz                  => nil,
          #:distribution_qc_loa                   => nil,
          #:distribution_qc_loxp                  => nil,
          :genotyping_comment                    => "-"
        }
      ]

      #Started
      #.....mice: testing [:mice][0][:colony_background_strain] - exp: '' vs obs: 'C57BL/6Dnk'
      #mice: testing [:mice][0][:test_cross_strain] - exp: 'C57BL/6J-Tyr<sup>c-Brd</sup>' vs obs: 'C57BL/6Brd-Tyr<sup>c-Brd</sup>'
      #mice: testing [:mice][0][:genetic_background] - exp: 'C57BL/6J-Tyr<sup>c-Brd</sup>;C57BL/6N' vs obs: 'C57BL/6Dnk;C57BL/6Brd-Tyr<sup>c-Brd</sup>;C57BL/6N'

      # sort the es cells ...
      [ ':targeted non-conditional', :conditional ].each do |symbol|
        unless expected_cells[symbol].nil?
          expected_cells[symbol][:cells].sort! { |x,y| x[:name] <=> y[:name] }
        end
      end

      actual_targeting_vectors = get_ikmc_project_page_data( @project_id )[:data][:targeting_vectors]

      expected_targ_vectors.sort_by! { |hsh| hsh[:name] }
      actual_targeting_vectors.sort_by! { |hsh| hsh[:name] }

      assert_equal( expected_targ_vectors, actual_targeting_vectors )

      # sort the es cells here as well ...
      observed_cells = get_ikmc_project_page_data( @project_id )[:data][:es_cells]
      [ ':targeted non-conditional', :conditional ].each do |symbol|
        unless expected_cells[symbol].nil?
          observed_cells[symbol][:cells].sort! { |x,y| x[:name] <=> y[:name] }
        end
      end

      assert_equal expected_cells[:conditional][:cells].size, observed_cells[:conditional][:cells].size
      assert_equal expected_cells[:"targeted non-conditional"][:cells].size, observed_cells[:"targeted non-conditional"][:cells].size

      for i in (0..expected_cells[:conditional][:cells].size-1)
        observed_cells[:conditional][:cells][i].keys.each do |key|
          warn "conditional: #{i}: #{key}: #{expected_cells[:conditional][:cells][i][key]}/#{observed_cells[:conditional][:cells][i][key]}" if expected_cells[:conditional][:cells][i][key] != observed_cells[:conditional][:cells][i][key]
        end
      end

      for i in (0..expected_cells[:"targeted non-conditional"][:cells].size-1)
        observed_cells[:"targeted non-conditional"][:cells][i].keys.each do |key|
          warn "targeted non-conditional: #{i}: #{key}: #{expected_cells[:"targeted non-conditional"][:cells][i][key]}/#{observed_cells[:"targeted non-conditional"][:cells][i][key]}" if expected_cells[:"targeted non-conditional"][:cells][i][key] != observed_cells[:"targeted non-conditional"][:cells][i][key]
        end
      end

      assert_equal( expected_cells.size, observed_cells.size )

      assert_equal( expected_cells[:conditional][:cells].size, observed_cells[:conditional][:cells].size )

      for i in 0..expected_cells[:conditional][:cells].size
        assert_equal( expected_cells[:conditional][:cells][i], observed_cells[:conditional][:cells][i] )
      end

      for i in 0..expected_cells[:"targeted non-conditional"][:cells].size
        assert_equal( expected_cells[:"targeted non-conditional"][:cells][i], observed_cells[:"targeted non-conditional"][:cells][i] )
      end

      #expected_cells[:conditional][:cells] = []
      #observed_cells[:conditional][:cells] = []
      #expected_cells[:"targeted non-conditional"][:cells] = []
      #observed_cells[:"targeted non-conditional"][:cells] = []

      #counter = 0
      #expected_cells[:conditional][:cells].each do |cell|
      #  cell.keys.each do |key|
      #    puts "#### #{key}: exp: #{cell[key]}, obs: #{observed_cells[:conditional][:cells][counter][key]}" if cell[key] != observed_cells[:conditional][:cells][counter][key]
      #    #assert_equal cell[key], observed_cells[:conditional][:cells][counter][key]
      # end
      #  #assert_equal cell, observed_cells[:conditional][:cells][counter]
      #  counter += 1
      #end
      #
      #assert_equal( expected_cells[:conditional][:allele_gb], observed_cells[:conditional][:allele_gb] )
      #assert_equal( expected_cells[:conditional][:allele_img], observed_cells[:conditional][:allele_img] )
      #
      #assert_equal( expected_cells[:"targeted non-conditional"][:allele_gb], observed_cells[:"targeted non-conditional"][:allele_gb] )
      #assert_equal( expected_cells[:"targeted non-conditional"][:allele_img], observed_cells[:"targeted non-conditional"][:allele_img] )
      #
      #counter = 0
      #expected_cells[:"targeted non-conditional"][:cells].each do |cell|
      #  cell.keys.each do |key|
      #    puts "#### #{key}: exp: #{cell[key]}, obs: #{observed_cells[:"targeted non-conditional"][:cells][counter][key]}" if cell[key] != observed_cells[:"targeted non-conditional"][:cells][counter][key]
      #    #assert_equal cell[key], observed_cells[:conditional][:cells][counter][key]
      #  end
      #  #assert_equal cell, observed_cells[:conditional][:cells][counter]
      #  counter += 1
      #end
      #
      #expected_cells[:conditional][:cells] = nil
      #observed_cells[:conditional][:cells] = nil
      #expected_cells[:"targeted non-conditional"][:cells] = nil
      #observed_cells[:"targeted non-conditional"][:cells] = nil

      assert_equal( expected_cells, observed_cells )

      observed = get_ikmc_project_page_data( @project_id )[:data][:mice]

      assert_equal expected_mice.size, observed.size

      expected_mice[0].keys.each do |key|
        warn "#{i}: #{key}: #{expected_mice[0][key]}/#{observed[0][key]}" if expected_mice[0][key] != observed[0][key]
      end

      assert_equal( expected_mice, observed )
    end

    should "have mutagenesis predictions" do
      assert_nothing_raised do
        get_mutagenesis_predictions @project_id
      end
    end

    should "not throw any exceptions with no mice" do
      project_id = 42474
      data = nil
      assert_nothing_raised { data = get_ikmc_project_page_data( project_id ) }
      assert( !data.nil? )
      assert( data[:mice].nil?, "We're trying to test for exception handling for projects with no mice - but this project 'project_id' has mouse data!")
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

      expected_data[:mice].sort! do |a, b|
        res = a[:qc_count]     <=> b[:qc_count]
        res = a[:escell_clone] <=> b[:escell_clone] if res == 0
        res
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
         # :intermediate_vectors,
          :targeting_vectors,
          :vector_image,
          :vector_gb,
          :stage,
          :stage_type
      ]


      expected_data[:targeting_vectors].sort_by! { |hsh| hsh[:name] }
      observed_data[:targeting_vectors].sort_by! { |hsh| hsh[:name] }

      top_level_keys.each do |key|
        # puts "testing '#{key}' - exp: '#{expected_data[key]}' vs obs: '#{observed_data[key]}'" if expected_data[key] != observed_data[key]
        assert_equal expected_data[key], observed_data[key]
      end

      # Now mice...
      expected_data[:mice][0].keys.each do |key|
        expected_data[:mice].each_index do |index|
          puts "mice: testing [:mice][#{index}][:#{key}] - exp: '#{expected_data[:mice][index][key]}' vs obs: '#{observed_data[:mice][index][key]}'" if expected_data[:mice][index][key] != observed_data[:mice][index][key]
          assert_equal( expected_data[:mice][index][key], observed_data[:mice][index][key], "Mouse data has changed... We're now getting: \n\n #{observed_data[:mice].to_json}" )
        end
      end

      # And cells...
      [ :conditional, :"targeted non-conditional" ].each do |status|
        expected_data[:es_cells][status][:cells][0].keys.each do |key|
          expected_data[:es_cells][status][:cells].each_index do |index|
            #puts "cells: testing [:es_cells][:#{status}][:cells][#{index}][:#{key}] - exp: '#{expected_data[:es_cells][status][:cells][index][key]}' vs obs: '#{observed_data[:es_cells][status][:cells][index][key]}'"
            #puts "cells: testing [:es_cells][:#{status}][:cells][#{index}][:#{key}] - exp: '#{expected_data[:es_cells][status][:cells][index][key]}' vs obs: '#{observed_data[:es_cells][status][:cells][index][key]}'" if expected_data[:es_cells][status][:cells][index][key] != observed_data[:es_cells][status][:cells][index][key]
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
