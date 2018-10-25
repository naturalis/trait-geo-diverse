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
GetOptions(
	'infile=s'   => \$infile,
	'outfile=s'  => \$outfile,
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
my @cols; # indexes of all columns of interest
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
		
		# write filtered header in snake case
		print $out join( "\t", map { decamelize($_) } sort { $columns{$a} <=> $columns{$b} } keys %columns ), "\n";
	}
	
	# write record
	else {
		my $i = $columns{'hasGeospatialIssues'};
		$line[$i] eq 'true' ? $line[$i] = 1 : $line[$i] = 0;
		print $out join( "\t", @line[@cols] ), "\n";
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