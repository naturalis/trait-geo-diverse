#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use MY::Taxize;
use MY::Schema;
use FindBin '$Bin';
use Scalar::Util 'looks_like_number';
use Bio::Phylo::Factory;
use Bio::Phylo::Util::Logger ':levels';

# constants
my $msw_name       = '../data/taxa/msw3-all.csv';
my $pantheria_name = 'PanTHERIA_1-0_WR05_Aug2008';
my $bininda_name   = '../data/phylogeny/Bininda-emonds_2007_mammals.tsv';

# process command line arguments
my $db = $Bin . '/../data/sql/tgd.db';
GetOptions( 'db=s' => \$db, );

# instantiate objects
my $fac        = Bio::Phylo::Factory->new;
my $log        = Bio::Phylo::Util::Logger->new( '-level' => INFO, '-class' => 'main' );
my $schema     = MY::Schema->connect("dbi:SQLite:$db");
my $branch_rs  = $schema->resultset('Branch');
my $tree_rs    = $schema->resultset('Tree');
my $variant_rs = $schema->resultset('Taxonvariant');
my $state_rs   = $schema->resultset('State');
my $char_rs    = $schema->resultset('Character');
my $proj       = $fac->create_project( '-namespaces' => { 'tgd' => 'https://github.com/naturalis/trait-geo-diverse/blob/master/doc/terms.md#' } );

# get IDs of MSW3 and Bininda tree
my $msw3      = $tree_rs->single({ 'tree_name' => $msw_name })->tree_id;
my $bininda   = $tree_rs->single({ 'tree_name' => $bininda_name })->tree_id;

# get node ID of Perissodactyla
my $perissodactyla = $branch_rs->single({
	'tree_id' => $msw3,
	'label'   => uc('Perissodactyla'),
})->node_id;

# get node ID of Artiodactyla
my $artiodactyla = $branch_rs->single({
	'tree_id' => $msw3,
	'label'   => uc('Artiodactyla'),
})->node_id;

# do the expansion to tip level for both
my @tips;
for ( $perissodactyla, $artiodactyla ) {
	expand( $_, $msw3, \@tips )
}

# iterate over the tips in the MSW3 taxonomy, make taxa block
my $taxa = $fac->create_taxa;
my ( @nodes, %matrix );
my %standard = (
	'1-1_ActivityCycle'   => 1,
	'6-1_DietBreadth'     => 1,
	'12-1_HabitatBreadth' => 1,
	'12-2_Terrestriality' => 1,
	'6-2_TrophicLevel'    => 1,
);
my %continuous = (
	'5-1_AdultBodyMass_g'          => 1,
	'8-1_AdultForearmLen_mm'       => 1,
	'13-1_AdultHeadBodyLen_mm'     => 1,
	'2-1_AgeatEyeOpening_d'        => 1,
	'3-1_AgeatFirstBirth_d'        => 1,
	'18-1_BasalMetRate_mLO2hr'     => 1,
	'5-2_BasalMetRateMass_g'       => 1,
	'7-1_DispersalAge_d'           => 1,
	'9-1_GestationLen_d'           => 1,
	'22-1_HomeRange_km2'           => 1,
	'22-2_HomeRange_Indiv_km2'     => 1,
	'14-1_InterbirthInterval_d'    => 1,
	'15-1_LitterSize'              => 1,
	'16-1_LittersPerYear'          => 1,
	'17-1_MaxLongevity_m'          => 1,
	'5-3_NeonateBodyMass_g'        => 1,
	'13-2_NeonateHeadBodyLen_mm'   => 1,
	'21-1_PopulationDensity_n/km2' => 1,
	'10-1_PopulationGrpSize'       => 1,
	'23-1_SexualMaturityAge_d'     => 1,
	'10-2_SocialGrpSize'           => 1,
	'24-1_TeatNumber'              => 1,
	'25-1_WeaningAge_d'            => 1,
	'5-4_WeaningBodyMass_g'        => 1,
	'13-3_WeaningHeadBodyLen_mm'   => 1,
	'5-5_AdultBodyMass_g_EXT'      => 1,
	'16-2_LittersPerYear_EXT'      => 1,
	'5-6_NeonateBodyMass_g_EXT'    => 1,
	'5-7_WeaningBodyMass_g_EXT'    => 1,
	'26-1_GR_Area_km2'             => 1,
	'26-2_GR_MaxLat_dd'            => 1,
	'26-3_GR_MinLat_dd'            => 1,
	'26-4_GR_MidRangeLat_dd'       => 1,
	'26-5_GR_MaxLong_dd'           => 1,
	'26-6_GR_MinLong_dd'           => 1,
	'26-7_GR_MidRangeLong_dd'      => 1,
	'27-1_HuPopDen_Min_n/km2'      => 1,
	'27-2_HuPopDen_Mean_n/km2'     => 1,
	'27-3_HuPopDen_5p_n/km2'       => 1,
	'27-4_HuPopDen_Change'         => 1,
	'28-1_Precip_Mean_mm'          => 1,
	'28-2_Temp_Mean_01degC'        => 1,
	'30-1_AET_Mean_mm'             => 1,
	'30-2_PET_Mean_mm'             => 1,
);
for my $tip ( @tips ) {
	
	# store MSW3 metadata
	my %meta = (
		'tgd:msw_taxonvariant_id'    => $tip->taxonvariant_id,
		'tgd:msw_taxonvariant_label' => $tip->label,	
		'tgd:msw_taxonvariant_level' => $tip->taxonvariant->taxonvariant_level,
	);
	
	# get canonical taxon, store its metadata
	my $dbtaxon = $tip->taxonvariant->taxon;
	$meta{'tgd:taxon_id'}    = $dbtaxon->taxon_id;
	$meta{'tgd:taxon_level'} = $dbtaxon->taxon_level;
	$meta{'tgd:msw_id'}      = $dbtaxon->msw_id;
	
	# iterate over all taxon variants that point to the canonical taxon
	my @branches;
	for my $tv ( $dbtaxon->taxonvariants ) {
		for my $branch ( $tv->branches ) {
			if ( $branch->tree_id == $bininda ) {
				push @branches, $branch;
			}
		}
		STATE: for my $state ( $tv->states ) {
			if ( $state->character->data_source eq $pantheria_name ) {
				my $value = $state->character_value;
				my $charname = $state->character->label;
				next STATE if not $standard{$charname} and not $continuous{$charname};
				$matrix{$charname} = {} if not $matrix{$charname};
				my $tvid = $tip->taxonvariant_id;
				$matrix{$charname}->{$tvid} = {
					'value' => $value,
					'tgd:pantheria_taxonvariant_id'   => $tv->taxonvariant_id,
					'tgd:pantheria_taxonvariant_name' => $tv->taxonvariant_name,
				};
			}
		}
	}
	
	# filter branches: only keep accepted names
	if ( my ($accepted) = grep { $_->taxonvariant->taxonvariant_status eq 'accepted' } @branches ) {
		@branches = ( $accepted );
	}
	
	# all is well: there is exactly one node in the Bininda tree
	if ( @branches == 1 ) {
		push @nodes, $fac->create_node(
			'-name'          => $branches[0]->label,
			'-branch_length' => $branches[0]->branch_length,
			'-generic'       => { 'tip' => $branches[0] },
			'-meta' => {
				'tgd:branch_id'               => $branches[0]->branch_id,
				'tgd:bininda_taxonvariant_id' => $branches[0]->taxonvariant_id,
			}
		);
	}
	
	# more than one node: Bininda has tips that are synonyms according to MSW
	# XXX this seems highly unlikely because the tree was anchored on MSW
	elsif ( @branches > 1 ) {
		die "multiple branches for taxon ".$dbtaxon->taxon_name;
	}
	
	# create the taxon
	$taxa->insert( $fac->create_taxon( 
		'-name'  => $dbtaxon->taxon_name,
		'-meta'  => \%meta,
		'-nodes' => [ $nodes[-1] ],
	) );
	$log->info("creating taxon ".$dbtaxon->taxon_name());
}
$proj->insert($taxa);

# populate the matrices
my $cmatrix = $fac->create_matrix( '-type' => 'continuous', '-taxa' => $taxa );
my $smatrix = $fac->create_matrix( '-type' => 'standard',   '-taxa' => $taxa );
my @tvids = keys %{{ map { $_ => 1 } map { keys %{ $_ } } values %matrix }};
my @chars = sort { $a cmp $b } keys %matrix;
for my $char ( @chars ) {
	
	# these are continuous @values with a decimal point
	if ( $continuous{$char} ) {
		
		# insert the character name in the continuous matrix
		$cmatrix->get_characters->insert( $fac->create_character( '-name' => $char ) );
		$log->info("Added continuous character: $char");
	}
	elsif ( $standard{$char} ) {
		
		# insert the character name in the discrete/standard matrix
		$smatrix->get_characters->insert( $fac->create_character( '-name' => $char ) );
		$log->info("Added discrete character: $char");
	}
}
for my $tvid ( @tvids ) {
	my ($taxon) = grep { $_->get_meta_object('tgd:msw_taxonvariant_id') == $tvid } @{ $taxa->get_entities };
	
	# make continuous character array
	my @cchar;
	my %cmeta = ( 'tgd:msw_taxonvariant_id' => $tvid );
	for my $char ( map { $_->get_name } @{ $cmatrix->get_characters->get_entities } ) {
		my $value = $matrix{$char}->{$tvid}->{'value'};
		if ( defined($value) ) {
			push @cchar, $value;
			$cmeta{'tgd:pantheria_taxonvariant_id'}   = $matrix{$char}->{$tvid}->{'tgd:pantheria_taxonvariant_id'};
			$cmeta{'tgd:pantheria_taxonvariant_name'} = $matrix{$char}->{$tvid}->{'tgd:pantheria_taxonvariant_name'};
		}
		else {
			push @cchar, '?';
		}
	}
	$cmatrix->insert( $fac->create_datum(
		'-type'  => 'continuous',
		'-meta'  => \%cmeta,
		'-char'  => \@cchar,
		'-taxon' => $taxon,
		'-name'  => $taxon->get_name,
	) );
	
	# make standard character array
	my @schar;
	my %smeta = ( 'tgd:msw_taxonvariant_id' => $tvid );
	for my $char ( map { $_->get_name } @{ $smatrix->get_characters->get_entities } ) {
		my $value = $matrix{$char}->{$tvid}->{'value'};
		if ( defined($value) ) {
			push @schar, int($value);
			$smeta{'tgd:pantheria_taxonvariant_id'}   = $matrix{$char}->{$tvid}->{'tgd:pantheria_taxonvariant_id'};
			$smeta{'tgd:pantheria_taxonvariant_name'} = $matrix{$char}->{$tvid}->{'tgd:pantheria_taxonvariant_name'};			
		}
		else {
			push @schar, '?';
		}
	}
	$smatrix->insert( $fac->create_datum(
		'-type'  => 'standard',
		'-meta'  => \%smeta,
		'-char'  => \@schar,
		'-taxon' => $taxon,
		'-name'  => $taxon->get_name,
	) );
	$log->info("Inserted matrix rows for $tvid");
}
$proj->insert($cmatrix);
$proj->insert($smatrix);

# populate the tree
my $forest = $fac->create_forest( '-taxa' => $taxa );
my $tree = $fac->create_tree( '-name' => $bininda_name, '-meta' => { 'tgd:tree_id' => $bininda } );
$forest->insert($tree);
$proj->insert($forest);
$tree->insert($_) for @nodes;
my @orphans = grep { ! $_->get_generic('root') } grep { ! $_->get_parent } @{ $tree->get_entities };
while( @orphans > 1 ) {
	contract($tree, @orphans);
	@orphans = grep { ! $_->get_generic('root') } grep { ! $_->get_parent } @{ $tree->get_entities };
}

print $proj->to_nexus( '-charlabels' => 1 );

# contracts a tip set to a tree topology
sub contract {
	my ( $tree, @orphans ) = @_;
	$log->info("finding parents for ".scalar(@orphans)." nodes");
		
	# store the currently known nodes by their database ID, and store the tree ID
	my %seen = map { $_->get_generic('tip')->node_id => $_ } @{ $tree->get_entities };
	my $tree_id = $tree->get_meta_object('tgd:tree_id');		
		
	# iterate over the orphans
	for my $o ( @orphans ) {
		my $tip = $o->get_generic('tip');
		my $node_id = $tip->node_id;
			
		# node has a parent in the database
		if ( my $parent_id = $tip->parent_id ) {
				
			# that node was already in the tree
			if ( my $parent = $seen{$parent_id} ) {
				$o->set_parent($parent);
				$log->debug("branch node:$node_id => parent:$parent_id drawn between nodes already in tree");
			}
			else {
				if ( my $b = $branch_rs->single({ 'tree_id' => $tree_id, 'node_id' => $parent_id }) ) {
					my $parent = $fac->create_node(
						'-branch_length' => $b->branch_length,
						'-generic'       => { 'tip' => $b },
					);
					$log->debug("branch node:$node_id => parent:$parent_id created by fetching parent from database");
					$o->set_parent($parent);
					$tree->insert($parent);
					$seen{$parent_id} = $parent;
				}
				else {
					$log->warn("no parent $parent_id in database");
				}
			}
		}
		else {
			$log->info("no parent in database, focal node is root");
			$o->set_generic( 'root' => 1 );
		}			
	}
}

# expands the MSW3 tree recursively
sub expand {
	my ( $node_id, $tree_id, $tips ) = @_;
	my $children = $branch_rs->search({ 'tree_id' => $tree_id, 'parent_id' => $node_id });
	while( my $child = $children->next ) {
		if ( $child->taxonvariant->taxonvariant_level eq 'SPECIES' ) {
			push @{ $tips }, $child;
		}
		else {
			expand( $child->node_id, $tree_id, $tips );
		}
	}
}