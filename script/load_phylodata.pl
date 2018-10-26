#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Schema;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use MY::Taxize qw[gnr_resolve TRUE FALSE];
Log::Log4perl->easy_init($DEBUG);

# process command line arguments
my $db = $ENV{'HOME'} . '/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/tgd.db';
my $infile;
my $taxonomy;
GetOptions(
	'db=s'       => \$db,
	'infile=s'   => \$infile,
	'taxonomy=s' => \$taxonomy,
);

# either MSW or GBIF
my ( $colname, $data_source_id );
if ( $taxonomy =~ /^m/i ) {
	$colname = 'msw_id';
	$data_source_id = 174;
}
else {
	$colname = 'gbif_taxon_key';
	$data_source_id = 11;
}

# instantiate objects
my $schema    = MY::Schema->connect("dbi:SQLite:$db");
my $branch_rs = $schema->resultset('Branch');
my $taxon_rs  = $schema->resultset('Taxa');
my $tree_id   = $schema->resultset('Tree')->create( { tree_name => $infile } )->tree_id;

# start reading tree table
my @header;
open my $fh, '<', $infile or die $!;
while(<$fh>) {
	chomp;
	my @line = split /\t/, $_;
	if ( not @header ) {
		
		# read header
		@header = @line;
	}
	else {
		
		# create record
		my %record;
		for my $i ( 0 .. $#header ) {
			$record{$header[$i]} = $line[$i];
		}
		
		# update fields
		$record{tree_id} = $tree_id;
		if ( $taxonomy and $record{label} ) {
			$record{taxon_id} = get_taxon_id( $record{label} );
		}
		
		# create the branch
		$branch_rs->create(\%record);
	}
}

sub get_taxon_id {
	my $label = shift;
	my $taxon_id;
	
	# do local query
	if ( my $taxon = $taxon_rs->single({ 'taxon_name' => $label }) ) {
		$taxon_id = $taxon->taxon_id;
		DEBUG "Exact match in local database for '$label' => $taxon_id";
	}
	
	# do tnrs
	else {
		my $results = gnr_resolve( 
			'names'           => [ $label ], 
			'data_source_ids' => [ $data_source_id ],
			'canonical'       => TRUE,
			'best_match_only' => TRUE,
			'fields'          => [ "all" ]
		);	
		if ( $results->[0] ) {
			my $match = $results->[0]->{'matched_name2'};
			my $score = $results->[0]->{'score'};
			my $local = $results->[0]->{'local_id'};
			my $value = $results->[0]->{'match_value'};
			if ( $score >= 0.75 and $value eq 'Fuzzy match by canonical form' ) {
				$taxon_id = $taxon_rs->single({ $colname => $local })->taxon_id;
				DEBUG "TNRS match for '$label' => '$match' ($taxon_id)";
			}
			else {
				DEBUG "TNRS matching score for '$label' => '$match' not high enough ($score)";
				DEBUG Dumper($results->[0]);
			}
		}		
	}
	return $taxon_id;
}
