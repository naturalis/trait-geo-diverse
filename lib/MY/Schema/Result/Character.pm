use utf8;
package MY::Schema::Result::Character;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::Character

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<characters>

=cut

__PACKAGE__->table("characters");

=head1 ACCESSORS

=head2 character_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 char_id

  data_type: 'integer'
  is_nullable: 1

=head2 label

  data_type: 'text'
  is_nullable: 1

=head2 data_source

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "character_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "char_id",
  { data_type => "integer", is_nullable => 1 },
  "label",
  { data_type => "text", is_nullable => 1 },
  "data_source",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</character_id>

=back

=cut

__PACKAGE__->set_primary_key("character_id");

=head1 RELATIONS

=head2 states

Type: has_many

Related object: L<MY::Schema::Result::State>

=cut

__PACKAGE__->has_many(
  "states",
  "MY::Schema::Result::State",
  { "foreign.character_id" => "self.character_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-25 13:43:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N3P18E1FBPL2oEngzRw9ZQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
