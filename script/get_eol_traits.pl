#!/usr/bin/perl
use strict;
use warnings;
use URI;
use JSON;
use Data::Dumper;
use Getopt::Long;
use HTTP::Headers;
use LWP::UserAgent;
use Log::Log4perl qw(:easy);

# global, hard-coded API token, can override as command line argument
my $token = do{ local $/; <DATA> };

# Workflow steps:
# 1. find root(s) for Ungulates (Perissodactyla: 1667; Cetartiodactyla: 46559234)
# 2. get all species tips
# 3. get literal trait triples for each tip
# 4. get object trait triples for each tip
# 5. write to CSV
{
	my @names;
	my $verbosity = 0;	
	GetOptions(
		'name=s'   => \@names,
		'verbose+' => \$verbosity,
		'token=s'  => \$token,
	);
	Log::Log4perl->easy_init( ( 5 - $verbosity ) * 10_000 );
	for my $name ( @names ) {
		my %roots = find_roots($name);
		for my $pid ( keys %roots ) {
			my %tips = get_descendants($pid);
			for my $tid ( keys %tips ) {
				my $taxon = $tips{$tid};
				for my $lit ( get_literals($tid) ) {
					print join("\t", $taxon, @$lit), "\n";
				}
				for my $obj ( get_objects($tid) ) {
					print join("\t", $taxon, @$obj), "\n";
				}
			}		
		}
	}
}

sub find_roots {
	my $name = shift;
	INFO "Finding page ID for $name";
	my $query = <<'QUERY';
MATCH (p:Page {canonical: "%s"})
RETURN p.canonical, p.page_id
LIMIT 100  
QUERY

	my $result = do_query( sprintf( $query, $name ) );
	return map { $_->[1] => $_->[0] } @{ $result->{'data'} };
}

sub get_descendants {
	my $pid = shift;
	INFO "Getting descendants for page_id $pid";
	my $query = <<'DESC';
MATCH (species:Page)-[:parent*]->(ancestor:Page {page_id: %d})
RETURN species.canonical, species.page_id
LIMIT 10000
DESC

	my $result = do_query( sprintf( $query, $pid ) );
	return map { $_->[1] => $_->[0] } grep { $_->[0] =~ /\s/ } @{ $result->{'data'} };
}

sub get_literals {
	my $pid = shift;
	DEBUG "Getting literal trait values for page_id $pid";
	my $query = <<'LITERALS';
MATCH (t:Trait)<-[:trait]-(p:Page),
(t)-[:predicate]->(pred:Term),
(t)-[:units_term]->(units:Term)
WHERE p.page_id = %d
RETURN pred.name, units.name, t.measurement 
LIMIT 10000
LITERALS

	my $result = do_query( sprintf( $query, $pid ) );
	return map { [ $_->[0] . ' (' . $_->[1] . ')' => $_->[2] ] } @{ $result->{'data'} };
}

sub get_objects {
	my $pid = shift;
	DEBUG "Getting object trait values for page_id $pid";
	my $query = <<'OBJECTS';
MATCH (t:Trait)<-[:trait]-(p:Page),
(t)-[:predicate]->(pred:Term),
(t)-[:object_term]->(obj:Term)
WHERE p.page_id = %d
RETURN DISTINCT pred.name, obj.name
LIMIT 1000
OBJECTS

	my $result = do_query( sprintf( $query, $pid ) );
	return @{ $result->{'data'} };
}

sub do_query {
	my $query = shift;

	# create authentication header
	my $h   = HTTP::Headers->new( Authorization => "JWT $token" );
	my $lwp = LWP::UserAgent->new( default_headers => $h );

	# build URI
	my $uri = URI->new( 'https://eol.org/service/cypher', 'https' );
	$uri->query_form( 'query' => $query );

	# do the request, print result to STDOUT
	my $res = $lwp->get($uri);
	if ( $res->is_success ) {
		return decode_json $res->decoded_content;
	}
	die $res->status_line;
}

__DATA__
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoicnV0Z2VyYWxkb0BnbWFpbC5jb20iLCJlbmNyeXB0ZWRfcGFzc3dvcmQiOiIkMmEkMTEkaG5NTzRtVG1sbUxWUUwuZDljZ09OdVFXanhuc0MuRWdrOVBVcmY0Y1YyQmFETjhRcHV3Q3UifQ.-4dh3Cf-NFYOcAtcYRTMhbq2Un3s-RILxSfZCJXDwRg