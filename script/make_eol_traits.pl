#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin '$Bin';

# process command line arguments
my $infile    = $Bin . '/../data/traits/eol/eol.tsv';
my $charfile  = $Bin . '/../data/traits/eol/eol_characters.tsv';
my $statefile = $Bin . '/../data/traits/eol/eol_states.tsv';
GetOptions(
	'infile=s'    => \$infile,
	'charfile=s'  => \$charfile,
	'statefile=s' => \$statefile,
);

# read data file /../data/traits/eol/eol.tsv
my %data;
open my $fh, '<', $infile or die $!;
while(<$fh>) {
	chomp;
	my ( $taxon, $character, $state ) = split /\t/, $_;
	$data{$taxon} = {} if not $data{$taxon};
	$data{$taxon}->{$character} = [] if not $data{$taxon}->{$character};
	push @{ $data{$taxon}->{$character} }, $state;
}

# make characters file /../data/traits/eol/eol_characters.tsv
open my $cfh, '>', $charfile  or die $!;
print $cfh join("\t", qw(char_id label data_source)), "\n";

# make states file /../data/traits/eol/eol_states.tsv
open my $sfh, '>', $statefile or die $!;
print $sfh join("\t", qw(label character_id character_value)), "\n";

# write data
my %character;
my $char_id = 1;
for my $taxon ( sort { $a cmp $b } keys %data ) {

	# only include extant taxa
	if ( $data{$taxon}->{'extinction status'} and $data{$taxon}->{'extinction status'}->[0] eq 'extant' ) {
		for my $char ( keys %{ $data{$taxon} } ) {
			
			# generate character id
			my $id = $character{$char};
			if ( not $character{$char} ) {
				$id = $char_id++;
				$character{$char} = $id;
				print $cfh join("\t", $id, $char, 'EoL-2019-01-08'), "\n";
			}
			
			# write states
			for my $state ( @{ $data{$taxon}->{$char} } ) {
				print $sfh join("\t", $taxon, $id, $state), "\n";
			}		
		}		
	}
}