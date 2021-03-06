create table if not exists taxa (
	taxon_id integer constraint taxon_pk primary key asc autoincrement,
	taxon_name text, -- index
	taxon_level text,
	msw_id integer,
	gbif_taxon_key integer
);

create table if not exists taxonvariants (
	taxonvariant_id integer constraint taxonvariant_pk primary key asc autoincrement,
	taxonvariant_name text, -- index
	taxonvariant_level text,
	taxonvariant_status text, -- e.g. synonym, canonical, etc.
	taxon_id integer constraint taxon_fk references taxa (taxon_id) on delete cascade on update cascade
);

create table if not exists trees (
	tree_id integer constraint tree_pk primary key asc autoincrement,
	tree_name text -- index
);

create table if not exists branches (
	branch_id integer constraint branch_pk primary key asc autoincrement,
	node_id integer, -- index
	parent_id integer, -- index
	taxonvariant_id integer constraint taxonvariant_fk references taxonvariants (taxonvariant_id) on delete cascade on update cascade, -- index
	label text, -- could be a biological taxon, a glottocode, a society name, a haplotype, etc.
	branch_length real,
	tree_id integer constraint tree_fk references trees (tree_id) on delete cascade on update cascade -- index
);

create table if not exists occurrences (
	occurrence_id integer constraint occurrence_pk primary key asc autoincrement,
	gbif_id integer,
	occurrence_type text,
	basis_of_record text,
	event_date date,
	decimal_latitude real,
	decimal_longitude real,
	dataset_key text,
	has_geospatial_issues integer,
	label text,
	taxonvariant_id integer constraint taxonvariant_fk references taxonvariants (taxonvariant_id) on delete cascade on update cascade
);

create table if not exists characters (
	character_id integer constraint character_pk primary key asc autoincrement,
	char_id integer, -- retains original display order
	label text, -- index
	data_source text -- index
);

create table if not exists states (
	state_id integer constraint state_pk primary key asc autoincrement,
	label text, -- could be a biological taxon, a glottocode, a society name, a haplotype, etc.
	character_id integer constraint character_fk references characters (character_id) on delete cascade on update cascade, -- index
	character_value text,
	taxonvariant_id integer constraint taxonvariant_fk references taxonvariants (taxonvariant_id) on delete cascade on update cascade -- index
);