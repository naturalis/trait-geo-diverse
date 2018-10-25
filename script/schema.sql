create table if not exists taxa (
	taxon_id integer constraint taxon_pk primary key asc autoincrement,
	taxon_name text, -- index
	taxon_level text,
	msw_id integer,
	tropicos_id integer,
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