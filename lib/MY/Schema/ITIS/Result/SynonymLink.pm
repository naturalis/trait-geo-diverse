use utf8;
package MY::Schema::ITIS::Result::SynonymLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::ITIS::Result::SynonymLink

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<synonym_links>

=cut

__PACKAGE__->table("synonym_links");

=head1 ACCESSORS

=head2 tsn

  data_type: 'int'
  is_nullable: 0
  size: 11

=head2 tsn_accepted

  data_type: 'int'
  is_nullable: 0
  size: 11

=head2 update_date

  data_type: 'date'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tsn",
  { data_type => "int", is_nullable => 0, size => 11 },
  "tsn_accepted",
  { data_type => "int", is_nullable => 0, size => 11 },
  "update_date",
  { data_type => "date", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tsn>

=item * L</tsn_accepted>

=back

=cut

__PACKAGE__->set_primary_key("tsn", "tsn_accepted");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-27 20:53:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9MApt/IuQHnY+J/wNZvOlA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
