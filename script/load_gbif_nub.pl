#!/usr/bin/perl
use strict;
use warnings;
use MY::Schema;
use Archive::Zip;
use Getopt::Long;
use File::Temp 'tempfile';
use MY::Taxize qw[gnr_resolve TRUE FALSE];

# process command line arguments
my $db = $ENV{'HOME'} . '/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/tgd.db';
my $class = 'Mammalia';
my $infile;
GetOptions(
	'db=s'     => \$db,
	'infile=s' => \$infile,
	'class=s'  => \$class,
);

# instantiate objects
my $schema    = MY::Schema->connect("dbi:SQLite:$db");
my $branch_rs = $schema->resultset('Branch');
my $taxon_rs  = $schema->resultset('Taxa');
my $tree_id   = $schema->resultset('Tree')->create( { tree_name => $infile } )->tree_id;
my $zip       = Archive::Zip->new($infile);

# extract Taxon.tsv table
my ( $wfh, $tempfile ) = tempfile();
close $wfh;
$zip->extractMember( 'Taxon.tsv' => $tempfile );

# start reading the file
my ( @header, %tree );
open my $fh, '<', $tempfile or die $!;
while(<$fh>) {
	chomp;
	my @line = split /\t/, $_;
	
	# read header
	if ( not @header ) {
		@header = @line;
	}
	
	# process record
	else {
		
		# load into hash
		my %record;
		for my $i ( 0 .. $#header ) {
			$record{$header[$i]} = $line[$i];
		}
		
		# check if focal class, skip otherwise
		if ( $record{'class'} and $record{'class'} eq $class ) {
			my $nesting = \%tree;
			my @cols = qw(class order family genericName specificEpithet infraspecificEpithet);

			# traverse classification from higher to lower taxon, growing the data structure
			for my $level ( @cols ) {
				my $name = $record{$level};
				if ( $name and $name =~ /\S/ ) {
					$nesting->{$name} = {} unless $nesting->{$name};
					$nesting = $nesting->{$name};
				}
			}
			
			# traverse classification from lower to higher
			LEVEL: for my $level ( reverse @cols ) {
				my $name = $record{$level};
				if ( $name and $name =~ /\S/ ) {
					$nesting->{'insert_object'} = {
						'gbif_taxon_key' => $record{'taxonID'},
						'query_name'     => $record{'canonicalName'},
						'taxon_level'    => uc($record{'taxonRank'}),
						'taxon_name'     => $name,
					};
					last LEVEL;
				}
			}
		}
	}
}

traverse(\%tree);
sub traverse {
	my ( $hoh, $parent_id ) = @_;
	if ( ref($hoh) ) {
		
		# prepare $insert_object to put it in Taxa table
		my $insert_object = delete $hoh->{'insert_object'};
		my $query_name    = delete $insert_object->{'query_name'};
		
		# attempt to get the taxon via gnr_resolve
		my $taxon;
		if ( $query_name ) {
			my $results = gnr_resolve( 
				'names'           => [ $query_name ], 
				'data_source_ids' => [ 174 ],
				'canonical'       => TRUE,
				'best_match_only' => TRUE,
				'fields'          => [ "all" ]
			);
			
			# find the ID in the local database and look up the primary key
			if ( $results->[0] ) {
				my $msw_id = $results->[0]->{'local_id'};
				$taxon = $taxon_rs->single({ msw_id => $msw_id });
				if ( $taxon->taxon_level eq $insert_object->{'taxon_level'} and $results->[0]->{'score'} >= 0.95 ) {
					$taxon->gbif_taxon_key( $insert_object->{'gbif_taxon_key'} );
				}
				else {
					$taxon = undef;
				}
			}
		}
		
		# no match, create a new taxon, then create a new node
		$taxon = $taxon_rs->create($insert_object) unless $taxon;		
		
		# create branch
		$branch_rs->create({
			'parent_id' => $parent_id,
			'node_id'   => $insert_object->{'gbif_taxon_key'},
			'taxon_id'  => $taxon->taxon_id,
			'tree_id'   => $tree_id,
			'label'     => $query_name,
		});
		warn $query_name;
		
		# traverse deeper
		traverse( $_, $insert_object->{'gbif_taxon_key'} ) for values %$hoh;
	}
}

unlink $tempfile;
