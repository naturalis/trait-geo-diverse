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

  data_type: 'date'
  is_nullable: 1

=head2 decimal_latitude

  data_type: 'real'
  is_nullable: 1

=head2 decimal_longitude

  data_type: 'real'
  is_nullable: 1

=head2 dataset_key

  data_type: 'text'
  is_nullable: 1

=head2 has_geospatial_issues

  data_type: 'integer'
  is_nullable: 1

=head2 label

  data_type: 'text'
  is_nullable: 1

=head2 taxonvariant_id

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
  { data_type => "date", is_nullable => 1 },
  "decimal_latitude",
  { data_type => "real", is_nullable => 1 },
  "decimal_longitude",
  { data_type => "real", is_nullable => 1 },
  "dataset_key",
  { data_type => "text", is_nullable => 1 },
  "has_geospatial_issues",
  { data_type => "integer", is_nullable => 1 },
  "label",
  { data_type => "text", is_nullable => 1 },
  "taxonvariant_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</occurrence_id>

=back

=cut

__PACKAGE__->set_primary_key("occurrence_id");

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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-30 17:22:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rZ3ZhDwJTM2Q2pie0/ul5A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
