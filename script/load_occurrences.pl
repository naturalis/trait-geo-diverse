#!/usr/bin/perl
use strict;
use warnings;
use MY::Schema;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

# process command line arguments
my $db  = $Bin . '/../data/sql/tgd.db';
my $infile;
GetOptions(
	'db=s'       => \$db,
	'infile=s'   => \$infile,
);

# instantiate objects
my $schema = MY::Schema->connect( "dbi:SQLite:$db" );
my $rs = $schema->resultset('Occurrence');

# read the gzipped infile
my @header;
my $counter;
open my $fh, "gunzip -c $infile |" or die $!;
LINE: while(<$fh>) {
	chomp;
	my @line = split /\t/, $_;
	
	# read header
	if ( not @header ) {
		@header = @line;
	}
	
	# read record
	else {
		my %record = map { $header[$_] => $line[$_] } 0 .. $#header;
		
		# these fields cannot be empty
		for my $field ( qw(decimal_longitude decimal_latitude event_date) ) {
			next LINE if not $record{$field};
		}
		
		# this field must be 0
		next LINE if $record{'has_geospatial_issues'} != 0;
		
		# this field must not be unknown
		next LINE if $record{'basis_of_record'} =~ /UNKNOWN/;
		
		# now persist the record
		$rs->create(\%record);
		DEBUG $counter . ': ' . Dumper(\%record) unless ++$counter % 10_000;
	}
}