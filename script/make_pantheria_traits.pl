#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Scalar::Util 'looks_like_number';

# process command line arguments
my $infile;   # PanTHERIA_1-0_WR05_Aug2008.txt
my $outfile;  # normalized character/state table
my $charfile; # normalized characters
GetOptions(
	'infile=s'   => \$infile,
	'outfile=s'  => \$outfile,
	'charfile=s' => \$charfile,
);

# start reading
my $binomial_idx = 4; # first relevant column, with binomial taxon name
open my $in,  '<', $infile or die $!;
open my $out, '>', $outfile or die $!;
print $out 'pantheria_tax_id', "\t", 'pantheria_char_id', "\t", 'pantheria_char_value', "\n";
my $flag;
while(<$in>) {
	local $/ = "\r\n"; # PanTHERIA data dump has MS-DOS line breaks
	chomp;
	my @line = split /\t/, $_;
	
	# write character table
	if ( not $flag ) {
		open my $cout, '>', $charfile or die $!;
		print $cout 'pantheria_char_id', "\t", 'pantheria_char_label', "\n";
		for my $i ( $binomial_idx + 1 .. $#line ) {
			print $cout ( $i - $binomial_idx ), "\t", $line[$i], "\n";
		}
		close $cout;
		$flag++;
	}
	
	# write states
	else {
		
		# write "taxon - character - state" wherever there is a state (magic number -999.0 is NA)
		for my $i ( $binomial_idx + 1 .. $#line ) {
			if ( $line[$i] =~ /;/ or ( looks_like_number($line[$i]) && $line[$i] != -999.00 ) ) {
				print $out $line[$binomial_idx], "\t", ( $i - $binomial_idx ), "\t", $line[$i], "\n";
			}
		}
	}
}