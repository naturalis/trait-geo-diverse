create table if not exists longnames ( 
	tsn int(11) not null, 
	completename varchar(164) not null, 
	primary key(tsn) 
);

create table if not exists synonym_links (
	tsn int(11) not null, 
	tsn_accepted int(11) not null, 
	primary key(tsn,tsn_accepted)
);