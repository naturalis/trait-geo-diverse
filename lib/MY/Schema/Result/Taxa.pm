use utf8;
package MY::Schema::Result::Taxa;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::Taxa

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxa>

=cut

__PACKAGE__->table("taxa");

=head1 ACCESSORS

=head2 taxon_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 taxon_name

  data_type: 'text'
  is_nullable: 1

=head2 taxon_level

  data_type: 'text'
  is_nullable: 1

=head2 msw_id

  data_type: 'integer'
  is_nullable: 1

=head2 gbif_taxon_key

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "taxon_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "taxon_name",
  { data_type => "text", is_nullable => 1 },
  "taxon_level",
  { data_type => "text", is_nullable => 1 },
  "msw_id",
  { data_type => "integer", is_nullable => 1 },
  "gbif_taxon_key",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</taxon_id>

=back

=cut

__PACKAGE__->set_primary_key("taxon_id");

=head1 RELATIONS

=head2 taxonvariants

Type: has_many

Related object: L<MY::Schema::Result::Taxonvariant>

=cut

__PACKAGE__->has_many(
  "taxonvariants",
  "MY::Schema::Result::Taxonvariant",
  { "foreign.taxon_id" => "self.taxon_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-27 12:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VZJnVXF965q0j9avls17Eg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
