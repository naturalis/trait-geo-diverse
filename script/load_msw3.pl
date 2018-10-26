#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use Getopt::Long;
use MY::Schema;

# process command line arguments
my $db = $ENV{'HOME'} . '/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/tgd.db';
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
open my $fh, '<', $infile or die $!;
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
		my @indices = ( 1 .. 11 );
		my %record  = map { $header[$_] => $row->[$_] } @indices;
		my ( $taxon_name, $parent_id );
		for my $level ( @header[@indices] ) {
			if ( $record{$level} ne "" ) {
				
				# compose species name
				if ( $level eq 'Species' ) {
					$taxon_name = join ' ', @record{'Genus', 'Species'};
				}
				elsif ( $level eq 'Subspecies' ) {
					$taxon_name = join ' ', @record{'Genus', 'Species', 'Subspecies'};
				}
				else {
					$taxon_name = $record{$level};
				}
				
				# expand or traverse nestings
				if ( not $nesting->{$taxon_name} ) {
					$nesting->{$taxon_name} = { 'msw_id' => $msw_id };
				}
				else {
					$parent_id = $nesting->{$taxon_name}->{'msw_id'};
				}
				
				# store current level
				$nesting = $nesting->{$taxon_name};
			}	
		}
		
		# insert taxon
		my $taxon_id = $taxon_rs->create({
			'taxon_name'  => $taxon_name,
			'taxon_level' => $taxon_level,
			'msw_id'      => $msw_id,
		})->taxon_id;
		
		# insert branch
		$branch_rs->create({
			'node_id'    => $msw_id,
			'parent_id'  => $parent_id,
			'taxon_id'   => $taxon_id,
			'label'      => $taxon_name,
			'tree_id'    => $tree_id,
		});
	}
}