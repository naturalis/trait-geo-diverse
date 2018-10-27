#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use Getopt::Long;
use MY::Schema;
use FindBin qw( $Bin );

# process command line arguments
my $db = $Bin . '/../data/sql/tgd.db';
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
my $taxonv_rs = $schema->resultset('Taxonvariant');
my $tree_id   = $schema->resultset('Tree')->create( { tree_name => $infile } )->tree_id;

# start reading file
my ( @header, %tree );
open my $fh, '<', $infile or die $!;
while( my $row = $csv->getline($fh) ) {
	
	# store header
	if ( not @header ) {
		@header = @{ $row };
	}
	else {
		
		# create record hash
		my %record  = map { $header[$_] => $row->[$_] } 0 .. $#header;
		
		# traverse the classification fields
		my $nesting = \%tree;
		my ( $taxon_name, $parent_id );
		for my $level ( @header[1..11] ) {
			if ( $record{$level} ne "" ) {
				
				# compose species name
				$taxon_name = make_label( $level, %record );
				
				# expand or traverse nestings
				if ( not $nesting->{$taxon_name} ) {
					$nesting->{$taxon_name} = { 'ID' => $record{'ID'} };
				}
				else {
					$parent_id = $nesting->{$taxon_name}->{'ID'};
				}
				
				# store current level
				$nesting = $nesting->{$taxon_name};
			}	
		}
		
		# taxon, taxonvariant, synonyms and taxonomy tree node in database
		insert_data(
			'TaxonName' => $taxon_name,
			'ParentID'  => $parent_id,
			%record,
		);
	}
}

sub insert_data {
	my ( %args ) = @_;
	
	# insert taxon
	my $taxon_id = $taxon_rs->create({
		'taxon_name'  => $args{'TaxonName'},
		'taxon_level' => $args{'TaxonLevel'},
		'msw_id'      => $args{'ID'},
	})->taxon_id;
		
	# insert taxon as canonical, accepted taxonvariant
	my $taxonv_id = $taxonv_rs->create({
		'taxonvariant_name'   => $args{'TaxonName'},
		'taxonvariant_level'  => $args{'TaxonLevel'},
		'taxon_id'            => $taxon_id,		
		'taxonvariant_status' => 'accepted',
	})->taxonvariant_id;
	
	# synonym is in italics (genus, (sub)specific epithet)
	if ( my $line = $args{'Synonyms'} ) {
		$line =~ s/\.$//;
		my $level = ucfirst(lc($args{'TaxonLevel'}));
		my $insert = sub {
			my $synonym = shift;
			$taxonv_rs->create({
				'taxonvariant_status' => 'synonym',			
				'taxonvariant_level'  => $args{'TaxonLevel'},
				'taxon_id'            => $taxon_id,		
				'taxonvariant_name'   => make_label( $level, %args, $level => $synonym ),
			});
		};
		
		# synonym is first match in italics
		if ( $line =~ m|<i>([A-Za-z]+)</i>| ) {
			my $synonym = $1;
			$insert->($synonym);
		}
		
		# line is a list of just single ucfirst words
		elsif ( not grep { $_ !~ /^[A-Z][a-z]+$/ } split /, /, $line ) {
			for my $synonym ( split /, /, $line ) {
				$insert->($synonym);
			}
		}
		
		# ucfirst first word
		elsif ( $line =~ /^([A-Z][a-z]+)/ ) {
			my $synonym = $1;
			$insert->($synonym);			
		}
	}
		
	# insert branch
	$branch_rs->create({
		'taxonvariant_id' => $taxonv_id,		
		'node_id'    => $args{'ID'},
		'parent_id'  => $args{'ParentID'},
		'label'      => $args{'TaxonName'},
		'tree_id'    => $tree_id,
	});	
}

sub make_label {
	my ( $level, %record ) = @_;
	
	# concatenate and return genus and species epithet
	if ( $level eq 'Species' ) {
		return join ' ', @record{'Genus', 'Species'};
	}
	
	# concatenate and return genus, species, and subspecific epithets
	elsif ( $level eq 'Subspecies' ) {
		return join ' ', @record{'Genus', 'Species', 'Subspecies'};
	}
	
	# just use the current, higher level, label as is
	else {
		return $record{$level};
	}	
}