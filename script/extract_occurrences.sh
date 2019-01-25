#!/bin/bash

# this script demonstrates how to extract filtered occurrences:

perl -I../lib extract_occurrences.pl \
	--outdir=../../trait-geo-diverse-ungulates/data \
	--dbfile=../data/sql/tgd.db \
	--subsp=1 \
	--taxa=PERISSODACTYLA \
	--taxa=ARTIODACTYLA \
	--thresh=2 \
#	--mindate=1970-01-01 \
#	--maxdate=2018-12-31 \
	--basis=PRESERVED_SPECIMEN \
	--basis=HUMAN_OBSERVATION \
	--basis=MACHINE_OBSERVATION \
	--basis=FOSSIL_SPECIMEN \
	--basis=OBSERVATION \
	--basis=LITERATURE \
	--basis=MATERIAL_SAMPLE

# explanation of options and arguments:
# --outdir  - where to write CSV files with filtered occurrences
# --dbfile  - location of the database file
# --subsp   - whether to include occurrences of subspecies
# --taxa    - which higher taxa (sensu MSW3) to expand to species level
# --thresh  - multiplier of the stdev, for filtering outlying occurrences
# --mindate - occurrences onwards from this date are included
# --maxdate - occurrences up till this date are included
# --basis   - occurrences with this basis_of_record are included

