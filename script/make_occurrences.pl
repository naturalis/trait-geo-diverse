#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Getopt::Long;
use Archive::Zip;
use File::Temp qw(tempfile);

# extracts a DarwinCore archive from GBIF, exports selected columns from 
# the occurrence.txt file as well as a normalized taxa table.
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
my %taxa; # normalized mapping for taxon table
my @cols; # indexes of all columns of interest
my ( $idx, $binomialx, $genusx, $speciesx, $rankx ); # indexes of taxon columns
my @taxon_cols = qw(taxonKey scientificName genus specificEpithet taxonRank); # labels of taxon columns
while(<$in>) {
	chomp;
	my @line = split /\t/, $_;
	
	# process header
	if ( not @cols ) {
		
		# collect all column indexes of interest
		for my $i ( 0 .. $#line ) {
			if ( exists $columns{$line[$i]} ) {
				$columns{$line[$i]} = $i;
				push @cols, $i;
			}
		}
		
		# lookup taxon column indexes
		( $idx, $binomialx, $genusx, $speciesx, $rankx ) = @columns{@taxon_cols};
		
		# write filtered header in snake case
		print $out join( "\t", map { decamelize($_) } sort { $columns{$a} <=> $columns{$b} } keys %columns ), "\n";
	}
	
	# write record, store taxon
	else {
		print $out join( "\t", @line[@cols] ), "\n";
		
		# lookup values
		my ( $id, $binomial, $genus, $species, $rank ) = @line[$idx, $binomialx, $genusx, $speciesx, $rankx];
		
		# populate data structure
		$taxa{$id} = {} unless $taxa{$id};
		$taxa{$id}->{$binomial} = {} unless $taxa{$id}->{$binomial};
		$taxa{$id}->{$binomial}->{$genus} = {} unless $taxa{$id}->{$binomial}->{$genus};
		$taxa{$id}->{$binomial}->{$genus}->{$species} = $rank;
	}
}

# write normalized taxa table
open my $tout, '>', $taxafile or die $!;
print $tout join( "\t", map { decamelize($_) } @taxon_cols ), "\n";
for my $id ( sort { $a <=> $b } keys %taxa ) {
	for my $binomial ( sort { $a cmp $b } keys %{ $taxa{$id} } ) {
		for my $genus ( sort { $a cmp $b }  keys %{ $taxa{$id}->{$binomial} } ) {
			for my $species ( sort { $a cmp $b } keys %{ $taxa{$id}->{$binomial}->{$genus} } ) {
				my $rank = $taxa{$id}->{$binomial}->{$genus}->{$species};
				print $tout join("\t", $id, $binomial, $genus, $species, $rank), "\n";
			}
		}
	}
}

# converts DarwinCore CamelCase into SQLite-happy snake_case
sub decamelize {
    my ($s) = @_;
    $s =~ s{(\w+)}{
        ($a = $1) =~ s<(^[A-Z]|(?![a-z])[A-Z])><
            "_" . lc $1
        >eg;
        substr $a, 0;
    }eg;
    $s =~ s/gbif_i_d/gbif_id/;
    $s;
}