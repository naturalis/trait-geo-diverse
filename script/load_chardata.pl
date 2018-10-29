#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use MY::Schema;
use MY::Schema::ITIS;
use MY::Taxize qw(get_taxonvariant_id);
Log::Log4perl->easy_init($INFO);

# process command line arguments
my $db  = $Bin . '/../data/sql/tgd.db';
my $sdb = $ENV{'HOME'} . '/Dropbox/documents/projects/dropbox-projects/trait-geo-diverse/itisSqlite092618/ITIS.db';
my $infile;
my $taxonomy;
my $charfile;
GetOptions(
	'db=s'       => \$db,
	'sdb=s'      => \$sdb,
	'infile=s'   => \$infile,
	'taxonomy=s' => \$taxonomy,
	'charfile=s' => \$charfile,
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
my $schema = MY::Schema->connect( "dbi:SQLite:$db" );

# read characters file, persist character definitions, cache primary keys
my %char_id;
{
	my @header;
	open my $fh, '<', $charfile or die $!;
	while(<$fh>) {
		chomp;
		my @line = split /\t/, $_;
		
		# read header
		if ( not @header ) {
			@header = @line;
		}
		
		# read record
		else {
			my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
			$char_id{ $record{'char_id'} } = $schema->resultset('Character')->create(\%record)->character_id;
		}
	}
}

# read states file, persist character state values
{
	my @header;
	open my $fh, '<', $infile or die $!;
	while(<$fh>) {
		chomp;
		my @line = split /\t/, $_;
		
		# read header
		if ( not @header ) {
			@header = @line;
		}
		
		# read record
		else {
			my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
			
			# update values
			my $local_id = $record{'character_id'};
			$record{'character_id'} = $char_id{$local_id};
			if ( $taxonomy ) {
				$record{'taxonvariant_id'} = get_taxonvariant_id(
					'itis'  => $sdb,
					'tgd'   => $db,
					'label' => $record{'label'},
					'dsid'  => $data_source_id, # msw3
					'col'   => $colname,
				);
			}
			
			# persist record
			$schema->resultset('State')->create(\%record);
		}
	}
}