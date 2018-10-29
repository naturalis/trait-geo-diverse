#!/usr/bin/perl
use strict;
use warnings;
use MY::Schema;
use Archive::Zip;
use Getopt::Long;
use Data::Dumper;
use File::Temp 'tempfile';
use Log::Log4perl qw(:easy);
use MY::Taxize qw[gnr_resolve TRUE FALSE];
Log::Log4perl->easy_init($DEBUG);

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
my $taxon_rs  = $schema->resultset('Taxa');
my $zip       = Archive::Zip->new($infile);

# extract Taxon.tsv table
my ( $wfh, $tempfile ) = tempfile();
close $wfh;
$zip->extractMember( 'Taxon.tsv' => $tempfile );

# start reading the file
my @header;
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
		my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
		
		# check if focal class, skip otherwise
		if ( $record{'class'} and $record{'class'} eq $class ) {
			$taxon_rs->create({
				'taxon_name'     => $record{'canonicalName'},						
				'gbif_taxon_key' => $record{'taxonID'},
				'taxon_level'    => uc($record{'taxonRank'}),				
			});
		}
	}
}

unlink $tempfile;
