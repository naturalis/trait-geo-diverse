use utf8;
package MY::Schema::Result::State;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::State

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<states>

=cut

__PACKAGE__->table("states");

=head1 ACCESSORS

=head2 state_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 label

  data_type: 'text'
  is_nullable: 1

=head2 character_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 character_value

  data_type: 'text'
  is_nullable: 1

=head2 taxonvariant_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "state_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "label",
  { data_type => "text", is_nullable => 1 },
  "character_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "character_value",
  { data_type => "text", is_nullable => 1 },
  "taxonvariant_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</state_id>

=back

=cut

__PACKAGE__->set_primary_key("state_id");

=head1 RELATIONS

=head2 character

Type: belongs_to

Related object: L<MY::Schema::Result::Character>

=cut

__PACKAGE__->belongs_to(
  "character",
  "MY::Schema::Result::Character",
  { character_id => "character_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 taxonvariant

Type: belongs_to

Related object: L<MY::Schema::Result::Taxonvariant>

=cut

__PACKAGE__->belongs_to(
  "taxonvariant",
  "MY::Schema::Result::Taxonvariant",
  { taxonvariant_id => "taxonvariant_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-27 12:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2v7nkNfjNlJMxPj5ZnC5Gg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
