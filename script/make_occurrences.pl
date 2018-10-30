#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Data::Dumper;
use Getopt::Long;
use Archive::Zip;
use File::Temp qw(tempfile);

# extracts a DarwinCore archive from GBIF, exports selected columns from 
# the occurrence.txt file as well as a normalized taxa table.
# process command line arguments
my $infile;   # zip file downloaded from GBIF
my $outfile;  # simplified occurrences as TSV
GetOptions(
	'infile=s'   => \$infile,
	'outfile=s'  => \$outfile,
);

# columns to retain
my %columns = (
	'gbifID'              => 'gbif_id', # integer (pk)
	'type'                => 'occurrence_type', # text
	'basisOfRecord'       => 'basis_of_record', # text (index)
	'eventDate'           => 'event_date', # text ISO-8601 date
	'decimalLatitude'     => 'decimal_latitude', # real
	'decimalLongitude'    => 'decimal_longitude', # real
	'datasetKey'          => 'dataset_key', # text (UUID)
	'hasGeospatialIssues' => 'has_geospatial_issues', # boolean (true/false), transform to 0/1
);

# extract occurrences from archive
my $zip = Archive::Zip->new($infile);
my ( $wfh, $tempfile ) = tempfile();
close $wfh;
$zip->extractMember( 'occurrence.txt' => $tempfile );

# start reading occurrences and writing output
open my $in, '<', $tempfile or die $!;
open my $out, '>', $outfile or die $!;
my ( @header, @transformed );
LINE: while(<$in>) {
	chomp;
	my @line = split /\t/, $_;
	
	# process header
	if ( not @header ) {
		@header = @line;
		
		# print header
		my @transformed = map { $columns{$_} } grep { $columns{$_} } @header;
		print $out join("\t", @transformed, 'label'), "\n";
	}
	
	# write record
	else {
		my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
		
		# transform boolean words to 1/0
		$record{'hasGeospatialIssues'} = $record{'hasGeospatialIssues'} eq 'true' ? 1 : 0; 
		
		# create label
		my $rank = $record{'taxonRank'};
		my $label;
		if ( $rank =~ /SPECIES/ ) {
			$label = join ' ', grep { /\S/ } @record{qw(genus specificEpithet infraspecificEpithet)};
		}
		elsif ( $rank eq 'UNRANKED' ) {
			next LINE;
		}
		else {
			$label = $record{lc $rank};
		}
		
		die Dumper(\%record) if not $label;
		
		# write output
		my @values = map { $record{$_} } grep { $columns{$_} } @header;
		print $out join("\t", @values, $label), "\n";
	}
}

unlink $tempfile;