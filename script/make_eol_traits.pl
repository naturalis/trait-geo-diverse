#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Scalar::Util 'looks_like_number';

# process command line arguments
my $data_dir = $ENV{'HOME'} . '/Documents/local-projects/trait-geo-diverse/data/traits/';
my $infile   = $data_dir . 'eol.tsv';
my $outfile  = $data_dir . 'eol_states.tsv';  # normalized character/state table
my $charfile = $data_dir . 'eol_characters.tsv'; # normalized characters
GetOptions(
	'infile=s'   => \$infile,
	'outfile=s'  => \$outfile,
	'charfile=s' => \$charfile,
);

# start reading
open my $in,  '<', $infile  or die "Error opening $infile: $!";
open my $out, '>', $outfile or die "Error opening $outfile: $!";
print $out 'label', "\t", 'character_id', "\t", 'character_value', "\n";
my @header;
while(<$in>) {
	chomp;
	my @line = split /\t/, $_;
	
	# write character table
	if ( not @header ) {
		@header = @line;
		open my $cout, '>', $charfile or die $!;
		print $cout 'char_id', "\t", 'label', "\t", 'data_source', "\n";
		for my $i ( 1 .. $#line ) {
			print $cout $i, "\t", $line[$i], "\t", 'EoL_2018_11_13', "\n";
		}
		close $cout;
	}
	
	# write states
	else {
		
		# write "taxon - character - state" wherever there is a state
		for my $i ( 1 .. $#line ) {
			if ( $line[$i] ne '' ) {
				print $out $line[0], "\t", $i, "\t", $line[$i], "\n";
			}
		}
	}
}