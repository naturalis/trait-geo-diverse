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

=head2 taxon_id

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
  "taxon_id",
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
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-25 13:43:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G5QWl6bsa5x/3bx74u5L+Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
