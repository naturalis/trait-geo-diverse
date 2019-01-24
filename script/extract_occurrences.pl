#!/usr/bin/perl
use strict;
use warnings;
use MY::Schema;
use Getopt::Long;
use GIS::Distance;
use GIS::Distance::Fast;
use Geo::ShapeFile;
use Geo::Shapefile::Writer;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use Data::Dumper;
Log::Log4perl->easy_init($INFO);

=begin pod

EXTRACTING AND CLEANING OCCURRENCE DATA

Occurrences as downloaded from GBIF potentially suffer from the following problems that preclude them
from being used directly in niche modelling:

- Taxonomic ambiguity, in that multiple synonyms occur in the database, which are reconciled against the
  GBIF backbone, but not directly against other taxonomies (e.g. Mammal Species of the World, MSW3), which is a 
  challenge when combining niche modeling with data from elsewhere (phylogenies, traits). However, this 
  issue is resolved on an ongoing basis by curating a local database where the taxon labels from the different
  data sources are reconciled with one another. Hence, this is not an issue that is dealt with in this script,
  except to say that the output records will use the name that is considered canonical by MSW3, regardless what
  was used in the GBIF record.
- There are often multiple records with the exact same lat/lon coordinates, being observations of multiple
  individuals in the same locality, for example. Here, we will resolve this by only retaining distinct records,
  which in fact can be produced directly using functionality available in SQL databases (i.e. 'SELECT DISTINCT').
- There are sometimes records in localities far outside of the range of a species, e.g. being observations that are
  annotated with the coordinates of some institution (a botanical garden, a zoo, a natural history collection) that
  keeps the specimen. We will filter these out by using a shape file provided by IUCN, with the native ranges
  (stacked) for all terrestrial mammals. The taxon labels in this shape file are assumed to have been reconciled
  with the database, such that any relevant taxa have their used name variants known to the db.
- There are sometimes records that are within the range map but that are still spurious. Here, we provide
  for the optional possibility of computing all pairwise distances between occurrences of a species, and then
  removing all records that are more than n * stdev from the mean (setting n to infinity would retain all).
- There are records of a type (i.e. dwc:basisOfRecord) that is unsuitable for our purposes, for example because 
  we might only want PRESERVED_SPECIMEN. Here, we provide the optional possibility of specifying which of the
  types are acceptable to our analysis.
- There are records whose age makes them unsuitable for analysis, for example because these are subfossil 
  remains from a time when there was a different climate or different land use. Here, we provide the option of 
  defining an age range (optional min, optional max, in ISO8601 date format) to filter on.

=cut

# process command line arguments
my $outdir;
my $shpfile;
my $db    = $Bin . '/../data/sql/tgd.db';
my @taxa  = qw(CETARTIODACTYLA PERISSODACTYLA);
my $level = 'order_';
GetOptions(
	'outdir=s'  => \$outdir,
	'shpfile=s' => \$shpfile,
	'db=s'      => \$db,
	'taxa=s'    => \@taxa,
	'level=s'   => \$level,
);

# - For each record in the shape file, check to see if the $level is one of the names in @taxa.
# - If so, take the value in the 'binomial' column.
# - This value should be in the taxonvariants table.
# - From the taxonvariants record, take the taxon_id, join it with the taxa table to get the taxon_name.
# - Write a shp file with the taxon_name to $outdir.

# open data sources
my $shp = Geo::ShapeFile->new( $shpfile, { 'no_cache' => 1 } );
my $dbh = MY::Schema->connect( "dbi:SQLite:$db" );

# iterate over shape records
my %seen;
my ( %shapes, %attributes );
my %clade = map { $_ => 1 } @taxa;
SHAPE: for my $id ( 1 .. $shp->shapes() ) {

	# check to see this record is in @taxa
	my %db = $shp->get_dbf_record($id);
	my $shp_clade_name = $db{$level};	
	if ( exists $clade{$shp_clade_name} ) {
	
		# lookup canonical name, process once
		my $shp_label = $db{'binomial'};		
		if ( not $seen{$shp_label} ) {		
			my %names;	
			my $rs = $dbh->resultset('Taxonvariant')->search({ 'taxonvariant_name' => $shp_label });
			while( my $tv = $rs->next ) {
				if ( my $taxon = $tv->taxon ) {
					my $taxon_name = $taxon->taxon_name;
					$names{$taxon_name}++;
				}
			}
			if ( scalar(keys(%names)) != 1 ) {
				ERROR "number of canonical names for $shp_label != 1";
				ERROR join ", ", keys(%names);
				next SHAPE;
			}
			else {
				($seen{$shp_label}) = keys(%names);
				INFO "$shp_label => " . $seen{$shp_label};
			}
		}
		
		# instantiate shape and attribute store, process once
		my $taxon_name = $seen{$shp_label};
		if ( not $shapes{$taxon_name} ) {
			$shapes{$taxon_name}     = [];
			$attributes{$taxon_name} = [];
		}
		push @{ $shapes{$taxon_name} }, $shp->get_shp_record($id);
		push @{ $attributes{$taxon_name} }, \%db;		
	}
}

# iterate over taxa
for my $taxon_name ( sort { $a cmp $b } keys %shapes ) {

	# instantiate writer
# 	my $writer = Geo::Shapefile::Writer->new(
# 		$outdir . '/' . $taxon_name,
# 		'POLYGON',
# 		$attributes{$taxon_name}
# 	);
	
	# iterate over shapes, parts, and segments
	INFO $taxon_name;
	for my $shape ( @{ $shapes{$taxon_name} } ) {
		INFO "\tparts: ".$shape->num_parts();
		for my $i ( 1 .. $shape->num_parts ) {
			my $part = $shape->get_part($i);
			my $segments = $shape->get_segments($i);
			die Dumper($segments);
		}
	} 
#	$writer->finalize();
}

