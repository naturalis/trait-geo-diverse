#!/usr/bin/perl
package OccurrenceFilter;
use strict;
use warnings;
use MY::Schema;
use Getopt::Long;
use Geo::ShapeFile;
use FindBin qw($Bin);
use GIS::Distance;
use GIS::Distance::Fast;
use Log::Log4perl qw(:easy);
use DateTime::Format::Flexible;

Log::Log4perl->easy_init($INFO);
our $AUTOLOAD;

=begin pod

EXTRACTING AND CLEANING OCCURRENCE DATA

Occurrences as downloaded from GBIF potentially suffer from the following problems that 
preclude them from being used directly in niche modelling:

1. Taxonomic ambiguity, in that multiple synonyms occur in the database, which are 
   reconciled against the GBIF backbone, but not directly against other taxonomies (e.g. 
   Mammal Species of the World, MSW3), which is a challenge when combining niche modeling 
   with data from elsewhere (phylogenies, traits). However, this issue is resolved on an 
   ongoing basis by curating a local database where the taxon labels from the different
   data sources are reconciled with one another. Hence, this is not an issue that is dealt 
   with in this script, except to say that the output records will use the name that is 
   considered canonical by MSW3, regardless what was used in the GBIF record.
2. There are often multiple records with the exact same lat/lon coordinates, being 
   observations of multiple individuals in the same locality, for example. Here, we will 
   resolve this by only retaining distinct records, which in fact can be produced 
   directly using functionality available in SQL databases (i.e. 'SELECT DISTINCT').
3. There are records of a type (i.e. dwc:basisOfRecord) that is unsuitable for our 
   purposes, for example because we might only want PRESERVED_SPECIMEN. Here, we provide 
   the optional possibility of specifying which of the types are acceptable to our 
   analysis.
4. There are records whose age makes them unsuitable for analysis, for example because 
   these are subfossil remains from a time when there was a different climate or different 
   land use. Here, we provide the option of defining an age range (optional min, optional 
   max, in ISO8601 date format) to filter on.   
5. There are sometimes records in localities far outside of the range of a species, e.g. 
   being observations that are annotated with the coordinates of some institution (a 
   botanical garden, a zoo, a natural history collection) that keeps the specimen. We 
   will filter these out by using a shape file provided by IUCN, with the native ranges
   (stacked) for all terrestrial mammals. The taxon labels in this shape file are assumed 
   to have been reconciled with the database, such that any relevant taxa have their used 
   name variants known to the db.
6. There are sometimes records that are within the range map but that are still spurious. 
   Here, we provide for the optional possibility of computing all pairwise distances 
   between occurrences of a species, and then removing all records that are more than 
   n * stdev from the mean (setting n to infinity would retain all).


=cut

sub new {
	my $package = shift;
	my %self = (
		'outdir'   => undef,
	 	'dbfile'   => $Bin . '/../data/sql/tgd.db',
	 	'dbtaxa'   => [ 'PERISSODACTYLA', 'ARTIODACTYLA' ],
		'shpfile'  => undef,	 	
	 	'shptaxa'  => [ 'CETARTIODACTYLA', 'PERISSODACTYLA' ],
	 	'shplevel' => 'order_',
	 	'mindate'  => undef,
	 	'maxdate'  => undef,
	 	'outlier'  => 9**9**9,
	 	'basis'    => [ 
	 		'PRESERVED_SPECIMEN',
			'HUMAN_OBSERVATION',
			'MACHINE_OBSERVATION',
			'FOSSIL_SPECIMEN',
			'OBSERVATION',
			'LITERATURE',
			'MATERIAL_SAMPLE',
		],	 		 	
	);
	my %args = map { $_ . '=s' => ref $self{$_} ? $self{$_} : \$self{$_} } keys %self;
	GetOptions(%args);
	$self{'db'} = MY::Schema->connect( 'dbi:SQLite:' . $self{'dbfile'} );
	
	# parse dates
	if ( $self{'mindate'} ) {
		$self{'mindate'} = DateTime::Format::Flexible->parse_datetime($self{'mindate'});
	}
	if ( $self{'maxdate'} ) {
		$self{'maxdate'} = DateTime::Format::Flexible->parse_datetime($self{'maxdate'});
	}
	
	return bless \%self, $package;
}

sub _recurse {		
	my ( $self, $node, $species ) = @_;
	if ( $node->taxonvariant->taxa->taxon_level eq 'SPECIES' ) {
		push @$species, $node->taxonvariant->taxa;		
	}
	else {
		my $rs = $self->db->resultset('Branch')->search({
			'tree_id'   => $node->tree_id,
			'parent_id' => $node->node_id,
		});
		while( my $n = $rs->next ) {
			_recurse( $self, $n, $species );
		}
	}
}

sub get_species {
	my $self = shift;
	my @species;
	for my $taxon ( @{ $self->dbtaxa } ) {
		INFO "going to collect species belonging to $taxon";
		my $node = $self->db->resultset('Branch')->single({
			'tree_id' => 11,
			'label'   => $taxon,
		});
		_recurse( $self, $node, \@species );
	}
	return @species;
}

# does the database query for a given input species, handles the restrictions of 1-4
sub get_records_for_species {
	my ( $self, $species ) = @_;
	my @occurrences;
	
	# get all taxon variants, including those for subspecies
	for my $tv ( $species->taxonvariants ) {
		push @occurrences, $tv->occurrences;
		for my $n ( $tv->branches ) {
			if ( $n->tree_id == 11 ) {
				my $children = $self->db->resultset('Branch')->search({
					'parent_id' => $n->node_id,
					'tree_id'   => 11,
				});
				while( my $c = $children->next ) {
					push @occurrences, $c->taxonvariant->occurrences;
				}
			}		
		}	
	}
	
	# filter on basis_of_record
	my %bor = map { $_ => 1 } @{ $self->basis };
	my @bor_filter;
	for my $occ ( @occurrences ) {
		my $b = $occ->basis_of_record;
		push @bor_filter, $occ if $bor{$b};
	}
	@occurrences = @bor_filter;
	
	# filter on event_date
	if ( $self->mindate ) {
		my @min_filter;
		for my $occ ( @occurences ) {
			my $date = DateTime::Format::Flexible->parse_datetime($occ->event_date);
			push @min_filter, $occ if $date >= $self->mindate;
		}			
		@occurrences = @min_filter;	
	}
	if ( $self->maxdate ) {
		my @max_filter;
		for my $occ ( @occurences ) {
			my $date = DateTime::Format::Flexible->parse_datetime($occ->event_date);
			push @max_filter, $occ if $date <= $self->maxdate;
		}			
		@occurrences = @max_filter;	
	}	
	
	# keep distinct lat/lon coordinates
}

# filters the records on their presence within a species range, by way of a shape file, restriction 5
sub filter_records_by_range {
	my ( $self, $species, @records ) = @_;
	my $shp = Geo::ShapeFile->new( $self->shpfile, { 'no_cache' => 1 } );
}

# filters the records by throwing out outliers more than n * stdev from the mean pairwise distance, restriction 6
sub filter_records_by_distances {
	my ( $self, @records ) = @_;
}

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+?:://;
	if ( exists $self->{$method} ) {
		return $self->{$method};
	}
	else {
		die "No '$method'";
	}
}

package main;

my $filter = OccurrenceFilter->new;
for my $sp ( $filter->get_species ) {
	my @records = $filter->get_records_for_species($sp);
	@records = $filter->filter_records_by_range( $sp => @records );
	@records = $filter->filter_records_by_distances(@records);
}
