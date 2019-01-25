#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Schema;
use MY::OccurrenceFilter;
use FindBin qw($Bin);

# these are the constructor arguments for the occurrence filter
my %cargs = (
	'outdir'   => undef,                        # where to write occurrences, per species, as CSV
	'dbfile'   => $Bin . '/../data/sql/tgd.db', # location of the sqlite database
	'mindate'  => undef,                        # minimum eventDate, in ISO8601 format
	'maxdate'  => undef,                        # maximum ...
	'subsp'    => 1,                            # whether to expand subspecies
	'thresh'   => 9**9**9,                      # multiplier of stdev of average pairwise dist, threshold for outliers
	'basis'    => [                             # basisOfRecord to include
		'PRESERVED_SPECIMEN',
		'HUMAN_OBSERVATION',
		'MACHINE_OBSERVATION',
		'FOSSIL_SPECIMEN',
		'OBSERVATION',
		'LITERATURE',
		'MATERIAL_SAMPLE', 
	],	 		 	
);

# here we map the above arguments to a hash in Getopt::Long format so we can modify 
# the constructor arguments on the command line
my %args = map { $_ . '=s' => ref($cargs{$_}) ? $cargs{$_} : \$cargs{$_} } keys %cargs;

# the top level taxa that we will expand to species level
my @taxa = qw(PERISSODACTYLA ARTIODACTYLA);

# where to write CSV files
my $outdir;

# process command line arguments
GetOptions(%args, 'taxa=s' => \@taxa, 'outdir=s' => \$outdir);

# instantiate objects
my $db     = MY::Schema->connect( 'dbi:SQLite:' . $cargs{'dbfile'} );
my $filter = MY::OccurrenceFilter->new(%cargs);

# build species list by expanding the @taxa to species level
my @species;
for my $taxon ( @taxa ) {
	my $node = $db->resultset('Branch')->single({
		'tree_id' => 11,
		'label'   => $taxon,
	});
	_recurse( $self, $node, \@species );
}
sub _recurse {		
	my ( $self, $node, $species ) = @_;
	if ( $node->taxonvariant->taxa->taxon_level eq 'SPECIES' ) {
		push @$species, $node->taxonvariant->taxa;		
	}
	else {
		my $rs = $db->resultset('Branch')->search({
			'tree_id'   => $node->tree_id,
			'parent_id' => $node->node_id,
		});
		while( my $n = $rs->next ) {
			_recurse( $self, $n, $species );
		}
	}
}

# iterate over species
for my $sp ( @species ) {
	my @records = $filter->get_occurrences_for_species($sp);
	@records = $filter->filter_occurrences_by_shapes( $sp => @records );
	@records = $filter->filter_occurrences_by_distances(@records);
}
