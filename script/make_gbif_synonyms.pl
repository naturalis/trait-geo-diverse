#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# process command line arguments
my $infile;        # Taxon.tsv from GBIF's backbone-current.zip
my $longnames;     # outfile: tsn "\t" completename
my $synonym_links; # outfile: tsn "\t" tsn_accepted
my $class = 'Mammalia';
GetOptions(
	'infile=s'        => \$infile,
	'longnames=s'     => \$longnames,
	'synonym_links=s' => \$synonym_links,
	'class=s'         => \$class,
);

# open output handles
open my $lfh, '>', $longnames or die $!;
open my $sfh, '>', $synonym_links or die $!;
print $lfh 'tsn', "\t", 'completename', "\n";
print $sfh 'tsn', "\t", 'tsn_accepted', "\n";

# start reading input
my @header;
open my $in, '<', $infile or die $!;
while(<$in>) {
	chomp;
	my @line = split /\t/, $_;
	
	# read header
	if ( not @header ) {
		@header = @line;
	}
	
	# read record
	else {
		my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
		next if not $record{'class'} or $record{'class'} ne $class;
		
		# fields for $longnames
		my $completename = $record{'scientificName'};
		my $tsn = $record{'taxonID'};
		print $lfh $tsn, "\t", $completename, "\n";
		
		# make synonym link if focal name is not 'accepted'
		if ( $record{'taxonomicStatus'} ne 'accepted' ) {
			my $tsn_accepted = $record{'acceptedNameUsageID'};
			print $sfh $tsn, "\t", $tsn_accepted, "\n";
		}
	}
}