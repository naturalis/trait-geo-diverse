#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use MY::Schema;
use MY::Schema::Synonyms;
use MY::Taxize qw(gnr_resolve get_taxonvariant_id TRUE FALSE);
Log::Log4perl->easy_init($DEBUG);

# process command line arguments
my $db = $Bin . '/../data/sql/tgd.db';
my $sdb;
GetOptions(
	'db=s'  => \$db,
	'sdb=s' => \$sdb,
);

# make database connections
my $tgd = MY::Schema->connect( "dbi:SQLite:$db" );
my $syn = MY::Schema::Synonyms->connect( "dbi:SQLite:$sdb" );

# select distinct labels
my $labels = $tgd->resultset('Occurrence')->search({}, {
	'select'   => [ { distinct => 'label' } ],
    'as'       => [ 'label' ],
    'order_by' => [ 'label' ],
});

my @labels;
while( my $l = $labels->next ) {
	push @labels, $l->label;
}

for my $label ( @labels ) {
	DEBUG 'LABEL ' . $label;
	
	# lookup the name from the GBIF backbone
	my $name = $syn->resultset('Longname')->single( { 'completename' => $label } );
	
	# name is either accepted or there is a synonym link
	my $tsn_accepted = $name->tsn;
	if ( my $link = $syn->resultset('SynonymLink')->single( { 'tsn' => $tsn_accepted } ) ) {
		$tsn_accepted = $link->tsn_accepted;
	}
	
	# now we have the canonical name sensu GBIF
	my $accepted_name = $syn->resultset('Longname')->find($tsn_accepted);
	my $completename = $accepted_name->completename;
	DEBUG 'ACCEPTED NAME ' . $completename;
	
	# lookup or create 
	my $taxonvariant = $tgd->resultset('Taxonvariant')->single( { 'taxonvariant_name' => $completename } );
	if ( not $taxonvariant ) {
		
		# lookup or create
		my $taxon = $tgd->resultset('Taxa')->single( { 'taxon_name' => $completename } );
		if ( not $taxon ) {
			$taxon = $tgd->resultset('Taxa')->create( {
				'taxon_name'     => $completename,	
				'gbif_taxon_key' => $tsn_accepted,
			} );
		}
		$taxonvariant = $tgd->resultset('Taxonvariant')->create( {
			'taxonvariant_name'   => $label,
			'taxonvariant_status' => ( $label eq $completename ? 'accepted' : 'synonym' ),
			'taxon_id'            => $taxon->taxon_id,
		} );
		DEBUG "CREATED NEW TAXON ($completename) AND NEW TAXON VARIANT ($label)";
	}
	my $taxonvariant_id = $taxonvariant->taxonvariant_id;
	$taxonvariant->taxon->update( { 'gbif_taxon_key' => $tsn_accepted } );
	
	# update records
	my $occurrences = $tgd->resultset('Occurrence')->search({ 'label' => $label });
	while( my $o = $occurrences->next ) {
		$o->update( { 'taxonvariant_id' => $taxonvariant_id } );
	}
}