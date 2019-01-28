package MY::OccurrenceFilter;
use strict;
use warnings;
use MY::Schema;
use GIS::Distance;
use Geo::ShapeFile;
use Geo::ShapeFile::Point;
use FindBin qw($Bin);
use List::Util qw(sum);
use Log::Log4perl qw(:easy);
use Statistics::Descriptive;

our $AUTOLOAD;

=begin pod

=head1 SYNOPSIS

    use MY::OccurrenceFilter;
    my $f = MY::OccurrenceFilter->new(
    	'dbfile'  => '/path/to/sqlite.db',
    	'shpfile' => '/path/to/IUCN_shapefile_stem', # i.e., without extension
    	'subsp'   => 1, # include occurrences from subspecies
    	'mindate' => '1970-01-01', # only occurrences from this eventDate onwards, inclusive
    	'maxdate' => '2018-12-31', # only occurrences up till this eventDate, inclusive
    	'thresh'  => 2, # reject occurrences with mean pairwise dist > 2 * stdev
    	'basis'   => [ 'PRESERVED_SPECIMEN' ], # only use this basisOfRecord
    );
    
    # iterate over taxa records from database
	for my $sp ( @species ) {
		my @occ = $filter->get_occurrences_for_species($sp);
		@occ = $filter->filter_occurrences_by_shapes( $sp => @occ );
		@occ = $filter->filter_occurrences_by_distances(@occ);
	}

=head1 EXTRACTING AND CLEANING OCCURRENCE DATA

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
	my ( $package, %args ) = @_;
	
	# setup defaults
	my %self = (
	 	'dbfile'   => undef,
		'shpfile'  => undef,	 	
		'subsp'    => 1,
	 	'mindate'  => undef,
	 	'maxdate'  => undef,
	 	'thresh'   => 9**9**9,
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
	
	# overwrite defaults with constructor args
	$self{$_} = $args{$_} for keys %args;
	
	# insantiate database connection
	$self{'db'} = MY::Schema->connect( 'dbi:SQLite:' . $self{'dbfile'} );
	
	# parse dates
	if ( $self{'mindate'} ) {
		$self{'mindate'} =~ s/-//g;
	}
	if ( $self{'maxdate'} ) {
		$self{'maxdate'} =~ s/-//g;
	}
	
	return bless \%self, $package;
}

# does the database query for a given input species, handles the restrictions of 1-4
sub get_occurrences_for_species {
	my ( $self, $species ) = @_;
	my @occurrences;
	INFO "going to get occurrences for ".$species->taxon_name;
	
	# get all taxon variants, optionally including those for subspecies
	for my $tv ( $species->taxonvariants ) {
		push @occurrences, $tv->occurrences;
		if ( $self->subsp ) {
			DEBUG "\tincluding occurrences for subspecies";
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
	}
	INFO "\tfetched ".scalar(@occurrences)." unfiltered occurrences from database";	
	
	# filter on basis_of_record
	my %bor = map { $_ => 1 } @{ $self->basis };
	my @bor_filter;
	for my $occ ( @occurrences ) {
		my $b = $occ->basis_of_record;
		push @bor_filter, $occ if $bor{$b};
	}
	@occurrences = @bor_filter;
	INFO "\thave ".scalar(@occurrences)." after filtering on basis_of_record";
	
	# filter on event_date
	if ( $self->mindate ) {
		my @min_filter;
		OCC: for my $occ ( @occurrences ) {
			my $date = substr $occ->event_date, 0, 10;
			$date =~ s/-//g;
			next OCC if $date !~ /^\d{8}$/;
			push @min_filter, $occ if $date >= $self->mindate;
		}			
		@occurrences = @min_filter;	
		INFO "\thave ".scalar(@occurrences)." after filtering on mindate ".$self->mindate;
	}
	if ( $self->maxdate ) {
		my @max_filter;
		OCC: for my $occ ( @occurrences ) {
			my $date = substr $occ->event_date, 0, 10;
			$date =~ s/-//g;		
			next OCC if $date !~ /^\d{8}$/;				
			push @max_filter, $occ if $date <= $self->maxdate;
		}			
		@occurrences = @max_filter;	
		INFO "\thave ".scalar(@occurrences)." after filtering on maxdate ".$self->maxdate;		
	}	
	
	# keep distinct lat/lon coordinates
	my %occ;
	for my $occ ( @occurrences ) {
		my $lat = $occ->decimal_latitude;
		$occ{$lat} = {} if not $occ{$lat};
		my $lon = $occ->decimal_longitude;
		$occ{$lat}->{$lon} = $occ if not $occ{$lat}->{$lon};
	}
	@occurrences = ();
	for my $lat ( keys %occ ) {
		push @occurrences, values %{ $occ{$lat} };
	}
	INFO "\thave ".scalar(@occurrences)." after retaining distinct coordinates";		
	return @occurrences;
}

# filters the records on their presence within a species range, by way of a shape file, restriction 5
sub filter_occurrences_by_shapes {
	my ( $self, $species, @records ) = @_;
	INFO "filtering ".scalar(@records)." occurrences by shapes for species ".$species->taxon_name;
	
	# expand the species to all its taxonvariant labels, optionally do the same for all subspecies labels
	my %labels;
	for my $tv ( $species->taxonvariants ) {
		my $name = $tv->taxonvariant_name;
		$labels{$name} = 1;
		if ( $self->subsp ) {
			for my $node ( $tv->branches ) {
				my $children = $self->db->resultset('Branch')->search({
					'parent_id' => $node->node_id,
					'tree_id'   => 11,
				});
				while( my $c = $children->next ) {
					my $subname = $c->taxonvariant->taxonvariant_name;
					$labels{$subname} = 1;
				}
			}
		}
	}
	INFO "\thave ".scalar(keys(%labels))." taxon variant names";

	# result list
	my @filtered;
	
	# create a hash keyed on record IDs, where the value is a tuple consisting of occurrence record 
	# and shapefile point
	my %records = map { 
		$_->occurrence_id => [ 
			$_, 
			Geo::ShapeFile::Point->new( 'X' => $_->decimal_longitude, 'Y' => $_->decimal_latitude ) 
		] 
	} @records;
	
	# open shapefile, iterate over shapes
	my $shp = Geo::ShapeFile->new( $self->shpfile, { 'no_cache' => 0 } );
	my $has_shape;
	SHAPE: for my $id ( 1 .. $shp->shapes ) { # 1-based IDs

		# check if focal shape matches any of the taxonvariant labels
		my %db = $shp->get_dbf_record($id);
		my $name = $db{'binomial'};
		if ( $labels{$name} ) {
			$has_shape++;
			INFO "\thave shape for label $name";
		
			# check all remaining occurrence records to see if they're in this shape
			my $shape = $shp->get_shp_record($id);
			$shape->build_spatial_index(0);
			my @r = keys %records;
			last SHAPE if @r == 0;
			for my $r ( @r ) {								
				if ( $shape->contains_point( $records{$r}->[1] => 1 ) ) {
					DEBUG "\t\tpoint $r is inside shape";
					push @filtered, $records{$r}->[0];
					delete $records{$r};
				}
			}
		}
	}	
	if ( not $has_shape ) {
		WARN "\t**** no shape for species ".$species->taxon_name;
		return @records;
	}
	else {
		INFO "\tretaining ".scalar(@filtered)." occurrences after filtering by shape";
		return @filtered;
	}
}

# filters the records by throwing out outliers more than n * stdev from the mean pairwise distance, restriction 6
sub filter_occurrences_by_distances {
	my ( $self, @records ) = @_;
	INFO "filtering ".scalar(@records)." occurrences on outliers by mean pairwise distance";
	
	# instantiate object to compute all Great Circle distances
	my $gis = GIS::Distance->new;
	$gis->formula('GreatCircle');
	
	# all vs all
	my ( %dist, @means );
	for my $i ( 0 .. $#records ) {
		
		# lookup and cache values for the inner loop
		my $src_lat = $records[$i]->decimal_latitude;
		my $src_lon = $records[$i]->decimal_longitude;
		my $src_id  = $records[$i]->occurrence_id;
		my @dists;
		INNER: for my $j ( 0 .. $#records ) {
			next INNER if $i == $j;
		
			# calculate distance
			my $trgt_lat = $records[$j]->decimal_latitude;
			my $trgt_lon = $records[$j]->decimal_longitude;
			push @dists, $gis->distance( $src_lat,$src_lon => $trgt_lat,$trgt_lon )->value;
		}
		$dist{$src_id} = sum(@dists)/scalar(@dists);
		push @means, $dist{$src_id};
	}
	INFO "\tcomputed all pairwise great circle distances";
	
	# compute mean distance for each occurrence, stdev, and threshold
	my $stat = Statistics::Descriptive::Sparse->new;
	$stat->add_data(\@means);
	my $stdev = $stat->standard_deviation();
	my $mom   = $stat->mean(); # mean of means
	my $threshold = $stdev * $self->thresh;
	INFO "\tthreshold is ".$self->thresh." * stdev ($stdev) = ".$threshold;
	
	# filter by ids
	my @filtered = map { $_->[1] } 
	              grep { abs( $dist{$_->[0]} - $mom ) <= $threshold } 
	               map { [ $_->occurrence_id => $_ ] } @records;
	INFO "\tretaining ".scalar(@filtered)." records";
	return @filtered;
}

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+:://;
	if ( exists $self->{$method} ) {
		return $self->{$method};
	}
	elsif ( $method =~ /^[A-Z]+$/ ) {
		return;
	}
	else {
		die "No '$method'";
	}
}

1;