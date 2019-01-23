#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Geo::ShapeFile;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use MY::Schema;
use MY::Taxize qw(gnr_resolve get_taxonvariant_id TRUE FALSE);
Log::Log4perl->easy_init($INFO);

# process command line arguments
my $db = $Bin . '/../data/sql/tgd.db';
my $sdb = $ENV{'HOME'} . '/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/itisSqlite092618/ITIS.db';
my $infile;
GetOptions(
	'sdb=s'      => \$sdb,
	'db=s'       => \$db,
	'infile=s'   => \$infile,	
);

# make database connections
my $shp = Geo::ShapeFile->new( $infile, { 'no_cache' => 1 } );

# iterate over shape records
my %seen;
for my $id ( 1 .. $shp->shapes() ) {

	# lookup taxon name from DBF record, process once
	my %db = $shp->get_dbf_record($id);
	my $label = $db{'binomial'};
	if ( not $seen{$label}++ ) {

		# find locally, find via tnrs, create new record if need be
		my $tvid = get_taxonvariant_id(
			'syn'   => $sdb,
			'tgd'   => $db,
			'label' => $label,
			'dsid'  => 174, # msw3
			'col'   => 'msw_id',
		);
		
		# report outcome	
		if ( $tvid ) {
			DEBUG "$label => $tvid";
		}
		else {
			WARN "no taxon variant ID for $label";
		}
	}
}