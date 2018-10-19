#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Archive::Zip;

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
my @columns = (
	'gbifID',              # integer (pk)
	'type',                # text
	'basisOfRecord',       # text (index)
	'eventDate',           # text ISO-8601 date
	'decimalLatitude',     # real
	'decimalLongitude',    # real
	'scientificName',      # text, includes naming authority
	'genus',               # text (index)
	'specificEpithet',     # text (index)
	'taxonRank',           # text (index)
	'datasetKey',          # text (UUID)
	'elevation',           # real
	'hasGeospatialIssues', # boolean (true/false), transform to 0/1
	'taxonKey',            # integer (fk)
);
