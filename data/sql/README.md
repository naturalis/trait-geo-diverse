Relational data tables
======================

This directory and its subdirectoties holds tabular data with, roughly, the following layout:

- `taxa` holds taxon names, synonyms, and identifiers in order to reconcile GBIF occurrences, traits from various databases
  ([examples](https://github.com/naturalis/mebioda/blob/master/doc/week3/w3d4/lecture3a/databases.Rmd)), and mappings to
  labels in phylogenies (possibly by way of the NCBI taxonomy).
- `occurrences` holds species occurrences, i.e. decimal lat/long coordinates, with sufficient metadata to filter dirty
  records and with a foreign key constraint to the `taxa` table.
- `traits` holds character-like data collected from various databases (or by hand) with a foreign key constraint to the 
  `taxa` table.
- `tree` holds phylogenetic data, probably as adjacency tables. These trees are likely obtained from publications such as
   the mammal supertree, the Zanne plant tree, etc. The tips have a foreign key constraint to the `taxa` table. Perhaps 
   this table also includes higher taxon "trees"/classifications.