use utf8;
package MY::Schema::Result::Taxonvariant;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::Taxonvariant

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<taxonvariants>

=cut

__PACKAGE__->table("taxonvariants");

=head1 ACCESSORS

=head2 taxonvariant_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 taxonvariant_name

  data_type: 'text'
  is_nullable: 1

=head2 taxonvariant_level

  data_type: 'text'
  is_nullable: 1

=head2 taxonvariant_status

  data_type: 'text'
  is_nullable: 1

=head2 taxon_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "taxonvariant_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "taxonvariant_name",
  { data_type => "text", is_nullable => 1 },
  "taxonvariant_level",
  { data_type => "text", is_nullable => 1 },
  "taxonvariant_status",
  { data_type => "text", is_nullable => 1 },
  "taxon_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</taxonvariant_id>

=back

=cut

__PACKAGE__->set_primary_key("taxonvariant_id");

=head1 RELATIONS

=head2 branches

Type: has_many

Related object: L<MY::Schema::Result::Branch>

=cut

__PACKAGE__->has_many(
  "branches",
  "MY::Schema::Result::Branch",
  { "foreign.taxonvariant_id" => "self.taxonvariant_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 occurrences

Type: has_many

Related object: L<MY::Schema::Result::Occurrence>

=cut

__PACKAGE__->has_many(
  "occurrences",
  "MY::Schema::Result::Occurrence",
  { "foreign.taxonvariant_id" => "self.taxonvariant_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 states

Type: has_many

Related object: L<MY::Schema::Result::State>

=cut

__PACKAGE__->has_many(
  "states",
  "MY::Schema::Result::State",
  { "foreign.taxonvariant_id" => "self.taxonvariant_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 taxon

Type: belongs_to

Related object: L<MY::Schema::Result::Taxa>

=cut

__PACKAGE__->belongs_to(
  "taxon",
  "MY::Schema::Result::Taxa",
  { taxon_id => "taxon_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-27 12:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:REVqAHafpOCI3hYbJqcFxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
