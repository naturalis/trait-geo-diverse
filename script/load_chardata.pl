#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use MY::Schema;
use MY::Schema::Synonyms;
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
	my %taxonvariant_id;
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
			
			# update character id from local to global
			my $local_id = $record{'character_id'};
			$record{'character_id'} = $char_id{$local_id};
			
			# lookup taxon variant ID if a reference taxonomy was provided
			if ( $taxonomy ) {
				
				# do the lookup once and cache it for subsequent states
				if ( not $taxonvariant_id{ $record{'label'} } ) {
					$taxonvariant_id{ $record{'label'} } = get_taxonvariant_id(
						'syn'   => $sdb,
						'tgd'   => $db,
						'label' => $record{'label'},
						'dsid'  => $data_source_id, # msw3
						'col'   => $colname,
					);
				}
				$record{'taxonvariant_id'} = $taxonvariant_id{ $record{'label'} };
			}
			
			# persist record
			$schema->resultset('State')->create(\%record);
		}
	}
}