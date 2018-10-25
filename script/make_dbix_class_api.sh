perl -MDBIx::Class::Schema::Loader=make_schema_at,dump_to_dir:../lib -e 'make_schema_at("MY::Schema", { debug => 1 }, [ "dbi:SQLite:dbname=../data/sql/tgd.db","sqlite" ])'
