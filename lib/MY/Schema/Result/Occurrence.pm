use utf8;
package MY::Schema::Result::Occurrence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MY::Schema::Result::Occurrence

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<occurrences>

=cut

__PACKAGE__->table("occurrences");

=head1 ACCESSORS

=head2 occurrence_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gbif_id

  data_type: 'integer'
  is_nullable: 1

=head2 occurrence_type

  data_type: 'text'
  is_nullable: 1

=head2 basis_of_record

  data_type: 'text'
  is_nullable: 1

=head2 event_date

  data_type: 'text'
  is_nullable: 1

=head2 decimal_latitude

  data_type: 'real'
  is_nullable: 1

=head2 decimal_longitude

  data_type: 'real'
  is_nullable: 1

=head2 scientific_name

  data_type: 'text'
  is_nullable: 1

=head2 dataset_key

  data_type: 'text'
  is_nullable: 1

=head2 elevation

  data_type: 'real'
  is_nullable: 1

=head2 has_geospatial_issues

  data_type: 'integer'
  is_nullable: 1

=head2 taxon_key

  data_type: 'integer'
  is_nullable: 1

=head2 taxon_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "occurrence_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "gbif_id",
  { data_type => "integer", is_nullable => 1 },
  "occurrence_type",
  { data_type => "text", is_nullable => 1 },
  "basis_of_record",
  { data_type => "text", is_nullable => 1 },
  "event_date",
  { data_type => "text", is_nullable => 1 },
  "decimal_latitude",
  { data_type => "real", is_nullable => 1 },
  "decimal_longitude",
  { data_type => "real", is_nullable => 1 },
  "scientific_name",
  { data_type => "text", is_nullable => 1 },
  "dataset_key",
  { data_type => "text", is_nullable => 1 },
  "elevation",
  { data_type => "real", is_nullable => 1 },
  "has_geospatial_issues",
  { data_type => "integer", is_nullable => 1 },
  "taxon_key",
  { data_type => "integer", is_nullable => 1 },
  "taxon_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</occurrence_id>

=back

=cut

__PACKAGE__->set_primary_key("occurrence_id");

=head1 RELATIONS

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C3jJRWx37JlXvksFwsxPeA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
