#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse_tree';

# process command line arguments
my $infile;  # tree file
my $format;  # newick | nexus | nexml, etc.
my $outfile; # tab-separated table with tree topology
GetOptions(
	'infile=s'   => \$infile,
	'format=s'   => \$format,
	'outfile=s'  => \$outfile,
);

# read tree object
my $tree = parse_tree(
	'-format' => $format,
	'-file'   => $infile,
);

# remove underscores from taxon labels
$tree->visit(sub{
	my $node = shift;
	my $name = $node->get_name;
	$name =~ s/_/ /g;
	$node->set_name($name);
});

# write tree table
open my $out, '>', $outfile or die $!;
print $out 'node_id', "\t", 'parent_id', "\t", 'branch_length', "\t", 'taxon', "\t", 'tree_name', "\n";
$tree->visit_depth_first(
	'-pre' => sub {
		my $node = shift;
		
		# node is not root
		my $parent_id = '';
		if ( my $parent = $node->get_parent ) {
			$parent_id = $parent->get_id;
		}
			
		# node is tip
		my $name = $node->get_name || '';
			
		# node has branch length
		my $length = $node->get_branch_length || '';
			
		# write output
		print $out $node->get_id, "\t", $parent_id, "\t", $length, "\t", $name, "\t", $infile, "\n";
	}
);