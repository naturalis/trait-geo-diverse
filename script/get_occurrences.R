#!/usr/bin/env Rscript
library(getopt)
library(rgbif)

# downloads occurrence data from GBIF using the rgbif package
# usage: $ ./get_occurrences.R --root=<root taxon> --outfile=<occurrence outfile>

# process command line arguments
opt = getopt(matrix(c(
    'root',     'r', 1, "character",
    'outfile',  'o', 1, "character"
), byrow=TRUE, ncol=4))

# get data:
data <- occ_search(scientificName = opt$root)

# page through records
endOfRecords <- FALSE
start <- 500
columns <- c("name", "key", "decimalLatitude", "decimalLongitude", "basisOfRecord", "taxonKey")
cat(paste(columns, collapse="	"), '\n',  file = opt$outfile) # write header
while ( !endOfRecords ) {
    subset <- data$data[columns] # retain selected columns
    write.table(subset, file=opt$outfile, append=T, sep="	", row.names=F, col.names=F, quote=F) # write TSV
    data <- occ_search(scientificName = opt$root, start = start) # rerun request
    endOfRecords <- data$meta$endOfRecords # update flag
    start <- start + 500 # update page
}