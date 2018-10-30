use utf8;
package MY::Schema::Synonyms::Result::Longname;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Synonyms::Result::Longname

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<longnames>

=cut

__PACKAGE__->table("longnames");

=head1 ACCESSORS

=head2 tsn

  data_type: 'int'
  is_nullable: 0
  size: 11

=head2 completename

  data_type: 'varchar'
  is_nullable: 0
  size: 164

=cut

__PACKAGE__->add_columns(
  "tsn",
  { data_type => "int", is_nullable => 0, size => 11 },
  "completename",
  { data_type => "varchar", is_nullable => 0, size => 164 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tsn>

=back

=cut

__PACKAGE__->set_primary_key("tsn");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-30 13:56:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OhZLQogcpmk2iOrwiZUvRQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
