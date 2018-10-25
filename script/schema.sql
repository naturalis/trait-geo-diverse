create table if not exists taxa (
	taxon_id integer constraint taxon_pk primary key asc autoincrement,
	taxon_name text, -- index
	taxon_level text,
	msw_id integer,
	gbif_taxon_key integer
);

create table if not exists trees (
	tree_id integer constraint tree_pk primary key asc autoincrement,
	tree_name text -- index
);

create table if not exists branches (
	branch_id integer constraint branch_pk primary key asc autoincrement,
	node_id integer, -- index
	parent_id integer, -- index
	taxon_id integer constraint taxon_fk references taxa (taxon_id), -- index
	label text, -- could be a biological taxon, a glottocode, a society name, a haplotype, etc.
	branch_length real,
	tree_id integer constraint tree_fk references trees (tree_id) -- index
);

create table if not exists occurrences (
	occurrence_id integer constraint occurrence_pk primary key asc autoincrement,
	gbif_id integer, -- index
	occurrence_type text, -- type, index
	basis_of_record text, -- index
	event_date text, -- ISO-8601 date
	decimal_latitude real,
	decimal_longitude real,
	scientific_name text, -- index
	dataset_key text, -- index
	elevation real,
	has_geospatial_issues integer, -- index, boolean 0/1
	taxon_key integer,
	taxon_id integer constraint taxon_fk references taxa (taxon_id) -- index
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
	character_id integer constraint character_fk references characters (character_id), -- index
	character_value text,
	taxon_id integer constraint taxon_fk references taxa (taxon_id) -- index
);