#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Schema;
use MY::Schema::Synonyms;
use Data::Dumper;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use MY::Taxize qw(get_taxonvariant_id);
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
my $schema    = MY::Schema->connect("dbi:SQLite:$db");
my $branch_rs = $schema->resultset('Branch');
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
		my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
		
		# update fields
		$record{'tree_id'} = $tree_id;
		if ( $taxonomy and $record{'label'} ) {
			$record{'taxonvariant_id'} = get_taxonvariant_id( 
				'label' => $record{'label'},
				'syn'   => $sdb,
				'tgd'   => $db,
				'dsid'  => $data_source_id,
				'col'   => $colname,
			);
		}
		
		# create the branch
		$branch_rs->create(\%record);
	}
}
