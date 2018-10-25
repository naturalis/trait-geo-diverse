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
my $branch_rs = $schema->resultset('Branch');
my $taxon_rs  = $schema->resultset('Taxa');
my $tree_id   = $schema->resultset('Tree')->create( { tree_name => $infile } )->tree_id;
my $zip       = Archive::Zip->new($infile);

# extract Taxon.tsv table
my ( $wfh, $tempfile ) = tempfile();
close $wfh;
$zip->extractMember( 'Taxon.tsv' => $tempfile );

# start reading the file
my ( @header, %tree );
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
		my %record;
		for my $i ( 0 .. $#header ) {
			$record{$header[$i]} = $line[$i];
		}
		
		# check if focal class, skip otherwise
		if ( $record{'class'} and $record{'class'} eq $class ) {
			my $nesting = \%tree;
			my @cols = qw(class order family genericName specificEpithet infraspecificEpithet);

			# traverse classification from higher to lower taxon, growing the data structure
			for my $level ( @cols ) {
				my $name = $record{$level};
				if ( $name and $name =~ /\S/ ) {
					$nesting->{$name} = {} unless $nesting->{$name};
					$nesting = $nesting->{$name};
				}
			}
			
			# traverse classification from lower to higher
			LEVEL: for my $level ( reverse @cols ) {
				my $name = $record{$level};
				if ( $name and $name =~ /\S/ ) {
					$nesting->{'insert_object'} = {
						'taxon_name'     => $record{'canonicalName'},						
						'gbif_taxon_key' => $record{'taxonID'},
						'taxon_level'    => uc($record{'taxonRank'}),
					};
					last LEVEL;
				}
			}
		}
	}
}
print Dumper(\%tree);
traverse(\%tree);
sub traverse {
	my ( $hoh, $parent_id ) = @_;
	if ( ref($hoh) ) {
		
		# prepare $insert_object to put it in Taxa table
		my $insert_object = delete $hoh->{'insert_object'};
		my $taxon = $taxon_rs->create($insert_object);
		
		# create branch
		$branch_rs->create({
			'tree_id'   => $tree_id,			
			'parent_id' => $parent_id,
			'taxon_id'  => $taxon->taxon_id,			
			'node_id'   => $insert_object->{'gbif_taxon_key'},
			'label'     => $insert_object->{'taxon_name'},
		});
		warn Dumper($insert_object);
		
		# traverse deeper
		traverse( $_, $insert_object->{'gbif_taxon_key'} ) for values %$hoh;
	}
}

unlink $tempfile;
