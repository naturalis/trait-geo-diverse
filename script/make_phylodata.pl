#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse_tree';

# process command line arguments
my $infile;   # tree file
my $format;   # newick | nexus | nexml, etc.
my $outfile;  # tab-separated table with tree topology
my $taxafile; # tab separated table with taxon mapping
GetOptions(
	'infile=s'   => \$infile,
	'format=s'   => \$format,
	'outfile=s'  => \$outfile,
	'taxafile=s' => \$taxafile,
);

# read tree object
my $tree = parse_tree(
	'-format' => $format,
	'-file'   => $infile,
);

# create taxon IDs
my %taxa;
my $taxonid;
for my $tip ( @{ $tree->get_terminals } ) {
	my $name = $tip->get_name;
	$name =~ s/_/ /g;
	$taxa{$name} = ++$taxonid;
	$tip->set_name($taxonid);
}

# write taxa table
{
	open my $out, '>', $taxafile or die $!;
	print $out 'taxon_id', "\t", 'taxon_name', "\t", 'tree_name', "\n";
	for my $name ( sort { $taxa{$a} <=> $taxa{$b} } keys %taxa ) {
		print $out $taxa{$name}, "\t", $name, "\t", $infile, "\n";
	}
	close $out;
}

# write tree table
{
	open my $out, '>', $outfile or die $!;
	print $out 'node_id', "\t", 'parent_id', "\t", 'branch_length', "\t", 'taxon_id', "\t", 'tree_name', "\n";
	$tree->visit_depth_first(
		'-pre' => sub {
			my $node = shift;
			
			# node is not root
			my $parent_id = '';
			if ( my $parent = $node->get_parent ) {
				$parent_id = $parent->get_id;
			}
			
			# node is tip
			my $tip_label = '';
			if ( $node->is_terminal ) {
				$tip_label = $node->get_name;
			}
			
			# node has branch length
			my $length = '';
			$length = $node->get_branch_length;
			
			# write output
			print $out $node->get_id, "\t", $parent_id, "\t", $length, "\t", $tip_label, "\t", $infile, "\n";
		}
	);
	close $out;
}