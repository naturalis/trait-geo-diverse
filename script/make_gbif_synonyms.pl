#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

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
LINE: while(<$in>) {
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
		
		# create label
		my $rank = $record{'taxonRank'};
		my $label;
		if ( $rank =~ /(?:species|variety)/ ) {
			$label = join ' ', grep { $_ } @record{qw(genus specificEpithet infraspecificEpithet)};
		}
		elsif ( $rank =~ /UNRANKED/i ) {
			next LINE;
		}
		else {
			$label = $record{lc $rank};
		}		
		
		if ( not $label ) {
			warn Dumper(\%record);
			next LINE;
		}
		
		# print fields for $longnames
		print $lfh $record{'taxonID'}, "\t", $label, "\n";
		
		# make synonym link if focal name is not 'accepted'
		if ( $record{'taxonomicStatus'} ne 'accepted' ) {
			print $sfh $record{'taxonID'}, "\t", $record{'acceptedNameUsageID'}, "\n";
		}
	}
}