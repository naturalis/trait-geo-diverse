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

# define columns to retain and write as header
columns <- c("key", "decimalLatitude", "decimalLongitude", "basisOfRecord", "name", "taxonKey")
cat(paste(columns, collapse='\t'), '\n',  file=opt$outfile)

# get data, starting at first record, fetch 500 records
start <- 0
data <- occ_search(scientificName=opt$root, start=start, hasGeospatialIssue=F)

# page in steps of 500
endOfRecords <- FALSE
while ( !endOfRecords ) {
	
	# append current page to TSV
    write.table(
    	data$data[columns], 
    	file=opt$outfile, 
    	sep='\t',
    	append=T, 
    	row.names=F, 
    	col.names=F, 
    	quote=F
    )
    
	# rerun request for next page
	start <- start + 500
    data <- occ_search(scientificName=opt$root, start=start, hasGeospatialIssue=F)
    
    # update flag
    endOfRecords <- data$meta$endOfRecords
}