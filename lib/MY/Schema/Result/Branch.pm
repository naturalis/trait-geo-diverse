use utf8;
package MY::Schema::Result::Branch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::Branch

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<branches>

=cut

__PACKAGE__->table("branches");

=head1 ACCESSORS

=head2 branch_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 node_id

  data_type: 'integer'
  is_nullable: 1

=head2 parent_id

  data_type: 'integer'
  is_nullable: 1

=head2 taxonvariant_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 label

  data_type: 'text'
  is_nullable: 1

=head2 branch_length

  data_type: 'real'
  is_nullable: 1

=head2 tree_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "branch_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "node_id",
  { data_type => "integer", is_nullable => 1 },
  "parent_id",
  { data_type => "integer", is_nullable => 1 },
  "taxonvariant_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "label",
  { data_type => "text", is_nullable => 1 },
  "branch_length",
  { data_type => "real", is_nullable => 1 },
  "tree_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</branch_id>

=back

=cut

__PACKAGE__->set_primary_key("branch_id");

=head1 RELATIONS

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

=head2 tree

Type: belongs_to

Related object: L<MY::Schema::Result::Tree>

=cut

__PACKAGE__->belongs_to(
  "tree",
  "MY::Schema::Result::Tree",
  { tree_id => "tree_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-27 12:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D1F8b47nSZ2g487pgVA4QQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
