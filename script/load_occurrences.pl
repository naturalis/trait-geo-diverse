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
		
		# rename this field because 'type' is reserved word in SQL
		$record{'occurrence_type'} = delete $record{'type'};
		
		# persist record - XXX at this point it does NOT have a taxon variant ID
		if ( $record{'decimal_longitude'} ne '' and $record{'decimal_latitude'} ne '' and $record{'basis_of_record'} !~ /UNKNOWN/ ) {
			$rs->create(\%record);
			DEBUG $counter . ': ' . Dumper(\%record) unless ++$counter % 10_000;
		}
	}
}