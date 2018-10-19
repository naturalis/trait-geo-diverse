#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Scalar::Util 'looks_like_number';

# process command line arguments
my $infile;   # PanTHERIA_1-0_WR05_Aug2008.txt
my $outfile;  # normalized character/state table
my $taxafile; # normalized taxa table
my $charfile; # normalized characters
GetOptions(
	'infile=s'   => \$infile,
	'outfile=s'  => \$outfile,
	'taxafile=s' => \$taxafile,
	'charfile=s' => \$charfile,
);

# start reading
my $binomial_idx = 4;
open my $in,  '<', $infile or die $!;
open my $out, '>', $outfile or die $!;
print $out 'pantheria_tax_id', "\t", 'pantheria_char_id', "\t", 'pantheria_char_value', "\n";
my $flag;
my $taxid;
my %taxa;
while(<$in>) {
	local $/ = "\r\n";
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
		
		# generate taxon ID
		my $binomial = $line[$binomial_idx];
		$taxa{$binomial} = ++$taxid unless $taxa{$binomial};
		
		# write state by state
		for my $i ( $binomial_idx + 1 .. $#line ) {
			if ( $line[$i] =~ /;/ or ( looks_like_number($line[$i]) && $line[$i] != -999.00 ) ) {
				print $out $taxa{$binomial}, "\t", ( $i - $binomial_idx ), "\t", $line[$i], "\n";
			}
		}
	}
}

# write taxa table
open my $tout, '>', $taxafile or die $!;
print $tout 'pantheria_tax_id', "\t", 'pantheria_tax_label', "\n";
for my $binomial ( sort { $taxa{$a} <=> $taxa{$b} } keys %taxa ) {
	print $tout $taxa{$binomial}, "\t", $binomial, "\n";
}