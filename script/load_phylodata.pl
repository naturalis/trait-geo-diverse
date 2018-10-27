#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Schema;
use MY::Schema::ITIS;
use Data::Dumper;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use MY::Taxize qw(gnr_resolve TRUE FALSE);
Log::Log4perl->easy_init($INFO);

# process command line arguments
my $db = $Bin . '/../data/sql/tgd.db';
my $sdb = $ENV{'HOME'} . '/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/itisSqlite092618/ITIS.db';
my $infile;
my $taxonomy;
GetOptions(
	'db=s'       => \$db,
	'sdb=s'      => \$sdb,
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
my $itis      = MY::Schema::ITIS->connect("dbi:SQLite:$sdb");
my $schema    = MY::Schema->connect("dbi:SQLite:$db");
my $names     = $itis->resultset('Longname');
my $links     = $itis->resultset('SynonymLink');
my $branch_rs = $schema->resultset('Branch');
my $taxon_rs  = $schema->resultset('Taxa');
my $taxonv_rs = $schema->resultset('Taxonvariant');
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
		$record{'tree_id'} = $tree_id;
		if ( $taxonomy and $record{'label'} ) {
			$record{'taxonvariant_id'} = get_taxonvariant_id( $record{'label'} );
		}
		
		# create the branch
		$branch_rs->create(\%record);
	}
}

sub get_taxonvariant_id {
	my $label = shift;
	my $taxonvariant_id;
	
	# do local query
	my $tv = $taxonv_rs->search({ 'taxonvariant_name' => $label });
	if ( $tv->count > 0 ) {
		if ( $tv->count == 1 ) {
			$taxonvariant_id = $tv->first->taxonvariant_id;
			DEBUG "Exact match in local database for '$label' => $taxonvariant_id";
		}
		else {
			while( my $t = $tv->next ) {
				ERROR $t->taxonvariant_name;
			}
		}
	}
	
	# look in ITIS for synonyms
	elsif ( my $itis_syn = $names->find({ 'completename' => $label }) ) {
		eval {
			my $tsn_acc  = $links->find({ 'tsn' => $itis_syn->tsn })->tsn_accepted;
			my $name_acc = $names->find({ 'tsn' => $tsn_acc })->completename;
			
			# check if other ITIS name exists
			if ( my $acc_tv = $taxonv_rs->single({ 'taxonvariant_name' => $name_acc }) ) {
				$taxonvariant_id = $taxonv_rs->create({
					'taxonvariant_name'   => $label,
					'taxon_id'            => $acc_tv->taxon_id,
					'taxonvariant_level'  => $acc_tv->taxonvariant_level,
					'taxonvariant_status' => 'synonym',
				})->taxonvariant_id;			
				DEBUG "Exact match in ITIS database for '$label' => '$name_acc' => $taxonvariant_id";
			}
		};
		if ( $@ ) {
			ERROR "ITIS problem with $label";
		}
	}
	
	# return here unless there was an ITIS problem
	return $taxonvariant_id if $taxonvariant_id;
	
	# do tnrs
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
		my $editd = $results->[0]->{'edit_distance'};
		if ( $score >= 0.75 and $value =~ /(?:Fuzzy|Exact) match by canonical form/ and $editd <= 1 ) {
			
			# lookup taxon and link variant to it
			my $taxon = $taxon_rs->single({ $colname => $local });
			$taxonvariant_id = $taxonv_rs->create({
				'taxonvariant_name'   => $label,
				'taxon_id'            => $taxon->taxon_id,
				'taxonvariant_level'  => $taxon->taxon_level,
				'taxonvariant_status' => 'synonym',
			})->taxonvariant_id;
			INFO "TNRS match for '$label' => '$match' (" . $taxon->taxon_id . ")";
		}
		else {
			INFO "TNRS matching score for '$label' => '$match' not high enough ($score)";
			DEBUG Dumper($results->[0]);
		}
	}
	return $taxonvariant_id;
}
