#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Schema;
use MY::Taxize qw[gnr_resolve TRUE FALSE];

# process command line arguments
my $db = '/Users/rutger.vos/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/tgd.db';
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
			
			# do a global names lookup
			my $results = gnr_resolve( 
				'names'           => [ $record{label} ], 
				'data_source_ids' => [ $data_source_id ],
				'canonical'       => TRUE,
				'best_match_only' => TRUE,
				'fields'          => [ "all" ]
			);
			
			# find the ID in the local database and look up the primary key
			if ( $results->[0] ) {
			    my $local_id = $results->[0]->{'local_id'};
			    $record{taxon_id} = $taxon_rs->single({ $colname => $local_id })->taxon_id;
			    warn $record{label}, "\t", $results->[0]->{matched_name2}, "\n";
			}			
		}
		
		# create the branch
		$branch_rs->create(\%record);
	}
}
