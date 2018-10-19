#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Archive::Zip;
use File::Temp qw(tempfile);

# process command line arguments
my $infile;   # zip file downloaded from GBIF
my $outfile;  # simplified occurrences as TSV
my $taxafile; # table of taxon to taxonKey mappings
GetOptions(
	'infile=s'   => \$infile,
	'outfile=s'  => \$outfile,
	'taxafile=s' => \$taxafile,
);

# columns to retain
my %columns = (
	'gbifID'              => undef, # integer (pk)
	'type'                => undef, # text
	'basisOfRecord'       => undef, # text (index)
	'eventDate'           => undef, # text ISO-8601 date
	'decimalLatitude'     => undef, # real
	'decimalLongitude'    => undef, # real
	'scientificName'      => undef, # text, includes naming authority
	'genus'               => undef, # text (index)
	'specificEpithet'     => undef, # text (index)
	'taxonRank'           => undef, # text (index)
	'datasetKey'          => undef, # text (UUID)
	'elevation'           => undef, # real
	'hasGeospatialIssues' => undef, # boolean (true/false), transform to 0/1
	'taxonKey'            => undef, # integer (fk)
);

# extract occurrences from archive
my $zip = Archive::Zip->new($infile);
my ( $wfh, $tempfile ) = tempfile();
close $wfh;
$zip->extractMember( 'occurrence.txt' => $tempfile );

# start reading occurrences and writing output
open my $in, '<', $tempfile or die $!;
open my $out, '>', $outfile or die $!;
my %taxa;
my @cols;
while(<in>) {
	chomp;
	my @line = split /\t/, $_;
	
	# read header
	if ( not @cols ) {
		for my $i ( 0 .. $#line ) {
			if ( exists $columns{$line[$i]} ) {
				$columns{$line[$i]} = $i;
				push @cols, $i;
			}
		}
		
		# write filtered header in snake case
		print $out join( "\t", map { decamelize($_) } sort { $columns{$a} <=> $columns{$b} } keys %columns ), "\n";
	}
	
	else {
		
	}
	
	
	
}