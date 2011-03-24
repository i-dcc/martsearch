#! /usr/bin/env perl

use strict;
use warnings FATAL => "all";
use JSON;
use Spreadsheet::WriteExcel;
use Getopt::Long;

##
## Runtime options...
##

my $PORTAL_URL          = 'http://www.sanger.ac.uk/mouseportal';
my $XLS_NAME            = 'pheno_overview.xls';
my $HEATMAP_DATA_FILE   = '';
my $SHOW_SORTABLE_SHEET = '';

GetOptions(
  'data_file=s'     => \$HEATMAP_DATA_FILE,
  'portal_url:s'    => \$PORTAL_URL,
  'xls_name:s'      => \$XLS_NAME,
  'sortable_sheet!' => \$SHOW_SORTABLE_SHEET
) or die;

##
## Read in the data file...
##

my $data_json = "";
open( DATAFILE, $HEATMAP_DATA_FILE );
while (<DATAFILE>) { $data_json .= $_; }
close(DATAFILE);

my $DATA = JSON->new->decode($data_json) or die "Unable to read data file '$HEATMAP_DATA_FILE'";

##
## Get on with it...
##

# Use this variable to set the number of columns of data we have 
# per-row before we print out the test results...
my $no_of_leading_text_entries = 3;

# Set up the spreadsheet and apply some formatting...
my $workbook = Spreadsheet::WriteExcel->new( $XLS_NAME );

# Cell formatting...
my $formats = {
  general        => $workbook->add_format( bg_color => 'white', border => 1, border_color => 'gray' ),
  unlinked_tests => _xls_setup_result_formats( $workbook, { border => 1, border_color => 'gray', align => 'center', valign => 'vcenter' } ),
  linked_tests   => _xls_setup_result_formats( $workbook, { border => 1, border_color => 'gray', align => 'center', valign => 'vcenter', bold => 1, underline => 1 } ),
  title          => $workbook->add_format( bold => 1, size => 10, bg_color => 'white', border => 1, border_color => 'gray' ),
  test_title     => $workbook->add_format( bold => 1, size => 10, bg_color => 'white', align => 'center', border => 1, border_color => 'gray', rotation => 90 )
};

# Add our worksheets and set them up
my $unsorted_worksheet = $workbook->add_worksheet('Overview');
_xls_setup_worksheet( $unsorted_worksheet, $no_of_leading_text_entries, scalar( @{$DATA->{data}} ) );
_xls_print_headers( $unsorted_worksheet, $DATA->{headers}, $no_of_leading_text_entries, $formats );

my $sorted_worksheet = $workbook->add_worksheet('Overview (Sortable)') if $SHOW_SORTABLE_SHEET;
if ($SHOW_SORTABLE_SHEET) {
  _xls_setup_worksheet( $sorted_worksheet, $no_of_leading_text_entries, scalar( @{$DATA->{data}} ) );
  _xls_print_headers( $sorted_worksheet, $DATA->{headers}, $no_of_leading_text_entries, $formats );
}

# Now print the data and legends...
write_data( $unsorted_worksheet, $DATA, $no_of_leading_text_entries, $formats );
write_unsorted_legend( $unsorted_worksheet, scalar( @{$DATA->{columns}} ), $formats );

if ($SHOW_SORTABLE_SHEET) {
  write_data( $sorted_worksheet, $DATA, $no_of_leading_text_entries, $formats );
  write_sorted_legend( $sorted_worksheet, scalar( @{$DATA->{columns}} ), $formats );
}

exit;

##
## Subroutines
##

# Helper function to setup a worksheet for the heatmap, i.e. set
# the row/column height/width parameters, and freeze panes.
sub _xls_setup_worksheet {
  my ( $worksheet, $no_of_leading_text_entries, $no_of_rows ) = @_;
  
  # Column width formatting...
  my %alpha_nums;
  my $number = 1;
  foreach ('A'..'Z') { $alpha_nums{$number} = $_; $number++; }
  $worksheet->set_column( 'A:'.$alpha_nums{$no_of_leading_text_entries}, 20 );
  $worksheet->set_column( $alpha_nums{$no_of_leading_text_entries+1}.':IV', 3 );
  
  # Row height formatting...
  for (my $n = 1; $n < $no_of_rows+1; $n++) { $worksheet->set_row( $n, 15 ); }

  # Freeze panes...
  $worksheet->freeze_panes(1, 0);
}

# Helper function to print the header row for a heatmap worksheet.
sub _xls_print_headers {
  my ( $worksheet, $header_data, $no_of_leading_text_entries, $formats ) = @_;
  
  my $title_format      = $formats->{title};
  my $test_title_format = $formats->{test_title};
  my $col               = 0;
  
  foreach my $header ( @{ $header_data } ) {
    if ( $col < $no_of_leading_text_entries ) { $worksheet->write( 0, $col, $header, $title_format ); }
    else                                      { $worksheet->write( 0, $col, $header, $test_title_format ); }
    $col++;
  }
}

# Helper function to set-up all of the formatting options for the
# different test results possible.
sub _xls_setup_result_formats {
  my ( $workbook, $default_props ) = @_;

  my $xls_formats = {
    completed_data_available  => { bg => 'navy', col => 'white' },
    significant_difference    => { bg => 'red' },
    early_indication          => { bg => 'yellow' },
    no_significant_difference => { bg => 44 }, # light blue
    not_applicable            => { bg => 'silver' },
    test_pending              => { bg => 'white' },
    test_abandoned            => { bg => 'white', fg => 'silver', pattern => 14 }
  };
  
  foreach my $result ( keys %{$xls_formats} ) {
    my $format = $workbook->add_format( %{$default_props} );
    if ( defined $xls_formats->{$result}->{bg} )        { $format->set_bg_color( $xls_formats->{$result}->{bg} ); }
    if ( defined $xls_formats->{$result}->{fg} )        { $format->set_fg_color( $xls_formats->{$result}->{fg} ); }
    if ( defined $xls_formats->{$result}->{pattern} )   { $format->set_pattern( $xls_formats->{$result}->{pattern} ); }
    if ( defined $xls_formats->{$result}->{col} )       { $format->set_color( $xls_formats->{$result}->{col} ); }
    
    $xls_formats->{$result} = $format;
  }
  
  return $xls_formats;
}

# Helper function to choose which cell format should be used for a 
# given phenotyping test result.
sub _xls_test_result_format {
  my ( $tf, $result ) = @_;
  my $form;
  
  if    ( $result eq "CompleteDataAvailable" )   { $form = $tf->{completed_data_available}; }
  elsif ( $result eq "CompleteInteresting" )     { $form = $tf->{significant_difference}; }
  elsif ( $result eq "CompleteNotInteresting" )  { $form = $tf->{no_significant_difference}; }
  elsif ( $result eq "EarlyIndicator" )          { $form = $tf->{early_indication}; }
  elsif ( $result eq "NotPerformedApplicable" )  { $form = $tf->{not_applicable}; }
  elsif ( $result eq "Abandoned" )               { $form = $tf->{test_abandoned}; }
  else                                           { $form = $tf->{test_pending}; }
  
  return $form;
}

# Preset map of test results to integers.
sub sorted_results_test_codes {
  my $test_mapping = {
    completed_data_available  => 1,
    significant_difference    => 2,
    early_indication          => 3,
    no_significant_difference => 4,
    not_applicable            => 5,
    test_pending              => 6,
    test_abandoned            => 7
  };
  return $test_mapping;
}

# Helper function to write the legend for the unsortable heatmap.
sub write_unsorted_legend {
  my ( $worksheet, $number_of_columns, $formats ) = @_;
  
  my $unlinked_formats = $formats->{unlinked_tests};
  my $linked_formats   = $formats->{linked_tests};
  
  $worksheet->write( 2, $number_of_columns+2, "LEGEND" );
  $worksheet->write( 4, $number_of_columns+3, "Test complete and data/resources are available" );
  $worksheet->write( 4, $number_of_columns+2, "", $unlinked_formats->{completed_data_available} );
  $worksheet->write( 5, $number_of_columns+3, "Test is complete and the data are considered interesting" );
  $worksheet->write( 5, $number_of_columns+2, "", $unlinked_formats->{significant_difference} );
  $worksheet->write( 6, $number_of_columns+3, "Preliminary indication of an interesting phenotype" );
  $worksheet->write( 6, $number_of_columns+2, "", $unlinked_formats->{early_indication} );
  $worksheet->write( 7, $number_of_columns+3, "Test is complete but the data are not considered interesting" );
  $worksheet->write( 7, $number_of_columns+2, "", $unlinked_formats->{no_significant_difference} );
  $worksheet->write( 8, $number_of_columns+3, "Test not performed or applicable e.g. no lacZ reporter therefore no expression" );
  $worksheet->write( 8, $number_of_columns+2, "", $unlinked_formats->{not_applicable} );
  $worksheet->write( 9, $number_of_columns+3, "Test abandoned" );
  $worksheet->write( 9, $number_of_columns+2, "", $unlinked_formats->{test_abandoned} );
  $worksheet->write( 10, $number_of_columns+3, "Test pending" );
  $worksheet->write( 10, $number_of_columns+2, "", $unlinked_formats->{test_pending} );
  $worksheet->write( 11, $number_of_columns+3, "Link to a phenotyping test report page" );
  $worksheet->write( 11, $number_of_columns+2, ">", $linked_formats->{test_pending} );
}

# Helper function to write the cells for the sortable heatmap.
sub write_sorted_legend {
  my ( $worksheet, $number_of_columns, $formats ) = @_;
  
  my $test_formats   = $formats->{unlinked_tests};
  my $linked_formats = $formats->{linked_tests};
  my $test_code      = sorted_results_test_codes();
  
  $worksheet->write( 2, $number_of_columns+2, "LEGEND" );
  $worksheet->write( 4, $number_of_columns+3, "Test complete and data/resources are available" );
  $worksheet->write( 4, $number_of_columns+2, $test_code->{completed_data_available}, $test_formats->{completed_data_available} );
  $worksheet->write( 5, $number_of_columns+3, "Test is complete and the data are considered interesting" );
  $worksheet->write( 5, $number_of_columns+2, $test_code->{significant_difference}, $test_formats->{significant_difference} );
  $worksheet->write( 6, $number_of_columns+3, "Preliminary indication of an interesting phenotype" );
  $worksheet->write( 6, $number_of_columns+2, $test_code->{early_indication}, $test_formats->{early_indication} );
  $worksheet->write( 7, $number_of_columns+3, "Test is complete but the data are not considered interesting" );
  $worksheet->write( 7, $number_of_columns+2, $test_code->{no_significant_difference}, $test_formats->{no_significant_difference} );
  $worksheet->write( 8, $number_of_columns+3, "Test not performed or applicable e.g. no lacZ reporter therefore no expression" );
  $worksheet->write( 8, $number_of_columns+2, $test_code->{not_applicable}, $test_formats->{not_applicable} );
  $worksheet->write( 9, $number_of_columns+3, "Test abandoned" );
  $worksheet->write( 9, $number_of_columns+2, $test_code->{test_abandoned}, $test_formats->{test_abandoned} );
  $worksheet->write( 10, $number_of_columns+3, "Test pending" );
  $worksheet->write( 10, $number_of_columns+2, $test_code->{test_pending}, $test_formats->{test_pending} );
  $worksheet->write( 11, $number_of_columns+3, "Link to a phenotyping test report page" );
  $worksheet->write( 11, $number_of_columns+2, "  ", $linked_formats->{test_pending} );
  
}

# Helper function to write the data onto a worksheet.
sub write_data {
  my ( $worksheet, $data, $no_of_leading_text_entries, $formats ) = @_;
  
  for ( my $row = 0 ; $row < scalar( @{ $data->{data} } ) ; $row++ ) {
    my $row_data = $data->{data}->[$row];
    
    for ( my $col = 0 ; $col < scalar( @{ $data->{columns} } ) ; $col++ ) {
      my $column_key = $data->{columns}->[$col];
      
      if ( $col < $no_of_leading_text_entries ) {
        # plain text
        $worksheet->write( $row + 1, $col, $row_data->{$column_key}, $formats->{general} );
      }
      else {
        # test info
        write_test_results( $worksheet, $row + 1, $col, $row_data, $column_key, $formats );
      }
    }
  }
  
}

# Helper function to write the data cells for the heatmap.
sub write_test_results {
  my ( $worksheet, $row, $col, $row_data, $column_key, $formats ) = @_;
  
  my $colony_prefix       = $row_data->{colony_prefix};
  my $result              = $row_data->{$column_key} ? $row_data->{$column_key} : '';
  my $comment             = $row_data->{$column_key.'_comments'};
  my $data                = $row_data->{$column_key.'_data'};
  my $sorted_test_mapping = sorted_results_test_codes();
  
  # write the comments if we have any
  if ( defined $comment && !( $comment =~ /^$/ ) ) {
    $worksheet->write_comment( $row, $col, $comment );
  }
  
  if ( defined $data ) {
    # if we have a test details page to link to...
    my $test_name = $column_key; $test_name =~ s/\_/\-/g;
    my $pheno_details_url = "$PORTAL_URL/phenotyping/$colony_prefix/$test_name/";
    if ( $test_name eq 'eye-histopathology' ) { $pheno_details_url = $data->[0]->{url}; }
    
    if ( $worksheet->get_name() =~ /Sort/ ) {
      $worksheet->write_url( $row, $col, $pheno_details_url, _xls_test_result_format( $sorted_test_mapping, $result ), _xls_test_result_format( $formats->{linked_tests}, $result ) );
    } else {
      $worksheet->write_url( $row, $col, $pheno_details_url, ">", _xls_test_result_format( $formats->{linked_tests}, $result ) );
    }
  }
  else {
    # or just a plain results cell...
    if ( $worksheet->get_name() =~ /Sort/ ) {
      $worksheet->write( $row, $col, _xls_test_result_format( $sorted_test_mapping, $result ), _xls_test_result_format( $formats->{unlinked_tests}, $result ) );
    } else {
      $worksheet->write( $row, $col, "", _xls_test_result_format( $formats->{unlinked_tests}, $result ) );
    }
  }
  
}
