#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Schema;
use MY::OccurrenceFilter;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);

# these are the constructor arguments for the occurrence filter
my %cargs = (
	'outdir'   => undef,                        # where to write occurrences, per species, as CSV
	'dbfile'   => $Bin . '/../data/sql/tgd.db', # location of the sqlite database
	'shpfile'  => undef,                        # location of the shape file
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

# additional command line arguments
my @taxa;      # top-level taxa to expand
my $outdir;    # where to write CSV files
my $overwrite; # whether to overwrite
my $verbosity = 3;
my $verbose   = 0;
GetOptions(
	%args, 
	'taxa=s'    => \@taxa, 
	'outdir=s'  => \$outdir, 
	'verbose+'  => \$verbose,
	'overwrite' => \$overwrite,
);

# instantiate logger
Log::Log4perl->easy_init( ($verbosity-$verbose) * 10_000 );

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
	_recurse( $node, \@species );
}
sub _recurse {		
	my ( $node, $species ) = @_;
	if ( $node->taxonvariant->taxon->taxon_level eq 'SPECIES' ) {
		push @$species, $node->taxonvariant->taxon;		
	}
	else {
		my $rs = $db->resultset('Branch')->search({
			'tree_id'   => $node->tree_id,
			'parent_id' => $node->node_id,
		});
		while( my $n = $rs->next ) {
			_recurse( $n, $species );
		}
	}
}
INFO "Expanded @taxa into ".scalar(@species)." species: [".join(', ',map{$_->taxon_name}@species).']';

# iterate over species
SPECIES: for my $sp ( @species ) {

	# generate output file name, skip if exists and not --overwrite
	my $taxon_name = $sp->taxon_name;
 	my $filename = $taxon_name . '.csv';
 	$filename =~ s/ /_/g;
 	$filename = $outdir . '/' . $filename;
 	if ( -e $filename and not $overwrite ) {
 		INFO "Species $taxon_name already has data (file: $filename). Skipping because --overwrite wasn't used";
	 	next SPECIES;
 	}

	# start filtering
 	my @records = $filter->get_occurrences_for_species($sp);
 	next SPECIES if scalar(@records) < 10;
 	@records = $filter->filter_occurrences_by_shapes( $sp => @records );
 	next SPECIES if scalar(@records) < 10;
 	@records = $filter->filter_occurrences_by_distances(@records);
 	next SPECIES if scalar(@records) < 10;

	# write CSV
	open my $fh, '>', $filename or die $!;
	print $fh join(",", qw(gbif_id taxon_name decimal_latitude decimal_longitude)), "\n";
	for my $r ( @records ) {
		my @values = (
			$r->gbif_id,
			$taxon_name,
			$r->decimal_latitude,
			$r->decimal_longitude
		);
		print $fh join(",", @values), "\n";
	}
}
