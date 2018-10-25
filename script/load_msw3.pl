#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use Getopt::Long;
use MY::Schema;

# process command line arguments
my $db = '/Users/rutger.vos/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/tgd.db';
my $infile;
GetOptions(
	'db=s'     => \$db,
	'infile=s' => \$infile,
);

# instantiate objects
my $schema    = MY::Schema->connect("dbi:SQLite:$db");
my $csv       = Text::CSV->new( { binary => 1 } );
my $branch_rs = $schema->resultset('Branch');
my $taxon_rs  = $schema->resultset('Taxa');
my $tree_id   = $schema->resultset('Tree')->create( { tree_name => $infile } )->tree_id;

# start reading file
my $msw_id_idx = 0;
my $taxon_level_idx = 12;
my ( @header, %tree );
open my $fh, "<:encoding(utf8)", $infile or die $!;
while( my $row = $csv->getline($fh) ) {
	
	# store header
	if ( not @header ) {
		@header = @{ $row };
	}
	else {
		
		# store taxa record values
		my $taxon_level = $row->[$taxon_level_idx];
		my $msw_id      = $row->[$msw_id_idx];
		
		# traverse the classification fields
		my $nesting = \%tree;
		my ( $taxon_name, $parent_id );
		for my $i ( 1 .. 11 ) {
			if ( $row->[$i] ne "" ) {
				$taxon_name = $row->[$i];
				if ( not $nesting->{$taxon_name} ) {
					
					# create a new nesting level
					$nesting->{$taxon_name} = { msw_id => $msw_id };
				}
				else {
					
					# nesting level exists, store id of this ancestor
					$parent_id = $nesting->{$taxon_name}->{msw_id};
				}
				$nesting = $nesting->{$taxon_name};
			}	
		}
		
		# insert taxon
		my $taxon_id = $taxon_rs->create({
			taxon_name  => $taxon_name,
			taxon_level => $taxon_level,
			msw_id      => $msw_id,
		})->taxon_id;
		
		# insert branch
		$branch_rs->create({
			node_id   => $msw_id,
			parent_id => $parent_id,
			taxon_id  => $taxon_id,
			label     => $taxon_name,
			tree_id   => $tree_id,
		});
	}
}