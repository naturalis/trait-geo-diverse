#!/usr/bin/env Rscript
library(getopt)
library(rgbif)

# downloads occurrence data from GBIF using the rgbif package
# usage: $ ./get_occurrences.R --root=<root taxon> --taxafile=<taxon outfile> --outfile=<occurrence outfile>

# process command line arguments
opt = getopt(matrix(c(
    'root',     'r', 1, "character",
    'taxafile', 't', 1, "character",
    'outfile',  'o', 1, "character"
), byrow=TRUE, ncol=4))

