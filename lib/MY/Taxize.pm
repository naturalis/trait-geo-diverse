package MY::Taxize;
use strict;
use warnings;
use Statistics::R;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gnr_resolve classification TRUE FALSE);

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

1;