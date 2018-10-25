use utf8;
package MY::Schema::Result::Tree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::Tree

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<trees>

=cut

__PACKAGE__->table("trees");

=head1 ACCESSORS

=head2 tree_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 tree_name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tree_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "tree_name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tree_id>

=back

=cut

__PACKAGE__->set_primary_key("tree_id");

=head1 RELATIONS

=head2 branches

Type: has_many

Related object: L<MY::Schema::Result::Branch>

=cut

__PACKAGE__->has_many(
  "branches",
  "MY::Schema::Result::Branch",
  { "foreign.tree_id" => "self.tree_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-25 13:43:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uPsmSBKgqnbUvfDhak6fyw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
