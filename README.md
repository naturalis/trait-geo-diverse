trait-geo-diverse
=================
Repository to collect data sets, notes, and prototypes of integration of phylogeny, trait, and occurrence data.
The general layout is as follows:

- "raw", uncleaned data files are collected in [data](data). Using simple, throwaway, cleaning and conversion scripts,
  these data are processed into tab-separated tables that go in [data/sql](data/sql). Subsequently, these tables are 
  imported in a SQLite database with a to-be-developed schema. The data model (column names, relations between tables)
  should mirror that of Bio::Phylo.
- from the schema of the SQLite database an object-relational mapping is generated with DBIx::Class, and dumped into 
  [lib](lib). Minor additions to these modules should result in opportunistic subclassing of Bio::Phylo functionality
  to make data access richer.
- the code in the [script](script) directory consists of larger scripts that filter and subset the data in the database
  in order to analyze these and/or export them into a file format suitable for analysis by 3rd party tools and R
  packages.
- the [R](R) directory will contain lightweight, re-usable library code in R to be used by some of the scripts. 

The general idea is that this is not a repository for heavy development of reusable libraries, but a place for doing
research and implementing computational workflows. Which are going to use a little bit of library code, as needed.
