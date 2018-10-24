create table if not exists taxa (
	taxon_id integer constraint taxon_pk primary key asc autoincrement,
	taxon_name text -- index
);

create table if not exists trees (
	branch_id integer constraint branch_pk primary key asc autoincrement,
	node_id integer, -- index
	parent_id integer, -- index
	taxon_id integer constraint taxon_fk references taxa (taxon_id), -- index
	taxon_name text,        
	branch_length real,
	tree_name text -- index
);

create table if not exists occurrences (
	occurrence_id integer constraint occurrence_pk primary key asc autoincrement, -- gbif_id
	occurrence_type text, -- type, index
	basis_of_record text, -- index
	event_date text, -- ISO-8601 date
	decimal_latitude real,
	decimal_longitude real,
	scientific_name text, -- index
	genus text, -- index
	specific_epithet text, -- index
	taxon_rank text, -- index	
	dataset_key text, -- index
	elevation real,
	has_geospatial_issues integer, -- index, boolean (true/false), transform to 0/1
	taxon_key integer,
	taxon_id integer constraint taxon_fk references taxa (taxon_id) -- index
);