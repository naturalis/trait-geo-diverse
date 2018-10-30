package MY::Taxize;
use strict;
use warnings;
use Statistics::R;
use MY::Schema;
use MY::Schema::Synonyms;
use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gnr_resolve get_taxonvariant_id TRUE FALSE);

sub TRUE () { 1 }
sub FALSE () { 0 }

=pod

=over

=item gnr_resolve

Usage:

    use MY::Taxize qw(gnr_resolve TRUE FALSE);
    my $results = gnr_resolve( 
        names                  => [ 'Bos taurus', 'Oryza sativa' ], 
        data_source_ids        => [ 174, 11 ], # MSW3, GBIF, respectively
        resolve_once           => FALSE,
        with_context           => FALSE,
        canonical              => TRUE,
        highestscore           => TRUE,
        best_match_only        => TRUE, 
        preferred_data_sources => NULL,
        with_canonical_ranks   => FALSE, 
        http                   => "get", 
        cap_first              => TRUE,
        fields                 => "all" 
    );

    for my $match ( @{ $results } ) {
        print $match->{'user_supplied_name'};
    }

=cut

sub gnr_resolve {
	my %args = @_;
	
	# instantiate R bridge and load library
	my $R = Statistics::R->new();
	$R->run(q[library(taxize)]);
	
	# set up the defaults for the argument list 
	$R->run(
		'args <- {}',
		'args$data_source_ids <- NULL',
		'args$resolve_once <- FALSE',
		'args$with_context <- FALSE',
		'args$canonical <- FALSE',
		'args$highestscore <- TRUE',
		'args$best_match_only <- FALSE',
		'args$preferred_data_sources <- NULL',
		'args$with_canonical_ranks <- FALSE',
		'args$http <- "get"',
		'args$cap_first <- TRUE',
		'args$fields <- "minimal"',
	);
	
	# set the names as a list and remove from argument list
	my $names = delete $args{'names'};
	$R->set( 'names' => $names );
	
	# copy the supplied arguments over the defaults
	for my $key ( keys %args ) {
	
		# lists and strings
		if ( ref($args{$key}) or ref($args{$key}) =~ /(?:get|post|minimal|all)/ ) {
			$R->set( "args\$$key" => $args{$key} );
		}
		elsif ( $args{$key} == TRUE ) {
			$R->run( "args\$$key <- TRUE" );
		}
		elsif ( $args{$key} == FALSE ) {
			$R->run( "args\$$key <- FALSE" );
		}		
	}
	
	# run gnr_resolve with full argument list
	$R->run('result <- gnr_resolve(names,data_source_ids = args$data_source_ids,resolve_once = args$resolve_once,with_context = args$with_context,canonical = args$canonical,highestscore = args$highestscore,best_match_only = args$best_match_only,preferred_data_sources = args$preferred_data_sources,with_canonical_ranks = args$with_canonical_ranks,http = args$http,cap_first = args$cap_first,fields = args$fields)');
	
	# get dimensions
	$R->run('my_nrow <- nrow(result)');
	$R->run('my_colnames <- colnames(result)');
	my $my_nrow     = $R->get('my_nrow');
	my $my_colnames = $R->get('my_colnames');
	
	# fetch the results
	my @results;
	for my $i ( 1 .. $my_nrow ) {
		my $r = {};
		for my $key ( @{ $my_colnames } ) {
			my $template = 'result$%s[[%d]]';
			my $lookup   = sprintf( $template, $key, $i );
			$R->run("my_value <- $lookup");
			$r->{$key} = $R->get('my_value');
		}
		push @results, $r;
	}
	return \@results;
}

=pod

=over

=item

Usage:

	my $id = get_taxonvariant_id(
		syn   => '/path/to/synonyms.db',
		tgd   => '/path/to/tgd.db',
		label => 'Pan paniscus',
		dsid  => 174, # msw3
		col   => 'msw_id',
	);

=cut

{
	my $itis;   # connection to synonyms database
	my $schema; # connection to trait-geo-diverse database
	my $names;  # result set for synonyms long names
	my $links;  # result set for links between synonyms and canonical names
	my $taxonv_rs; # result set for taxon variants 
	my $taxon_rs;  # result set for taxa

	sub get_taxonvariant_id {
		my %args = @_;
		my $label          = $args{'label'};
		my $data_source_id = $args{'dsid'};
		my $colname        = $args{'col'};
		my $taxonvariant_id;		
		
		# instantiate database connections to synonyms
		if ( $args{'syn'} and not $itis ) {
			$itis  = MY::Schema::Synonyms->connect( 'dbi:SQLite:' . $args{'syn'} );
			$names = $itis->resultset('Longname');
			$links = $itis->resultset('SynonymLink');
		}
		
		# instantiate database connection to TGD
		if ( $args{'tgd'} and not $schema ) {
			$schema    = MY::Schema->connect( 'dbi:SQLite:' . $args{'tgd'} );
			$taxonv_rs = $schema->resultset('Taxonvariant');
			$taxon_rs  = $schema->resultset('Taxa');
		}
	
		# do local query
		my $tv = $taxonv_rs->search({ 'taxonvariant_name' => $label });
		if ( $tv->count > 0 ) {
			if ( $tv->count == 1 ) {
				$taxonvariant_id = $tv->first->taxonvariant_id;
				DEBUG "Exact match in local database for '$label' => $taxonvariant_id";
			}
			else {
				while( my $t = $tv->next ) {
					ERROR $t->taxonvariant_name;
				}
			}
		}
	
		# look for synonyms
		elsif ( my $itis_syn = $names->find({ 'completename' => $label }) ) {
			eval {
				my $tsn_acc  = $links->find({ 'tsn' => $itis_syn->tsn })->tsn_accepted;
				my $name_acc = $names->find({ 'tsn' => $tsn_acc })->completename;
			
				# check if canonical name exists
				if ( my $acc_tv = $taxonv_rs->single({ 'taxonvariant_name' => $name_acc }) ) {
					$taxonvariant_id = $taxonv_rs->create({
						'taxonvariant_name'   => $label,
						'taxon_id'            => $acc_tv->taxon_id,
						'taxonvariant_level'  => $acc_tv->taxonvariant_level,
						'taxonvariant_status' => 'synonym',
					})->taxonvariant_id;			
					DEBUG "Exact match in synonyms database for '$label' => '$name_acc' => $taxonvariant_id";
				}
			};
			if ( $@ ) {
				ERROR "Synonyms problem with $label: $@";
			}
		}
	
		# return here unless there was an synonyms problem
		return $taxonvariant_id if $taxonvariant_id;
	
		# do tnrs
		my $results = gnr_resolve( 
			'names'           => [ $label ], 
			'data_source_ids' => [ $data_source_id ],
			'canonical'       => TRUE,
			'best_match_only' => TRUE,
			'fields'          => [ "all" ]
		);	
		if ( $results->[0] ) {
			my $match = $results->[0]->{'matched_name2'};
			my $score = $results->[0]->{'score'};
			my $local = $results->[0]->{'local_id'};
			my $value = $results->[0]->{'match_value'};
			my $editd = $results->[0]->{'edit_distance'};
			if ( $score >= 0.75 and $value =~ /(?:Fuzzy|Exact) match by canonical form/ and $editd <= 1 ) {
			
				# lookup taxon and link variant to it
				my $taxon = $taxon_rs->single({ $colname => $local });
				$taxonvariant_id = $taxonv_rs->create({
					'taxonvariant_name'   => $label,
					'taxon_id'            => $taxon->taxon_id,
					'taxonvariant_level'  => $taxon->taxon_level,
					'taxonvariant_status' => 'synonym',
				})->taxonvariant_id;
				INFO "TNRS match for '$label' => '$match' (" . $taxon->taxon_id . ")";
			}
			else {
				INFO "TNRS matching score for '$label' => '$match' not high enough ($score)";
				INFO Dumper($results->[0]);
			}
		}
		return $taxonvariant_id;
	}
}

1;