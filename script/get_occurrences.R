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

# page in steps of 500
endOfRecords <- FALSE
start <- 0
while ( !endOfRecords ) {
	
	# fetch records
	data <- occ_search(scientificName=opt$root, start=start, hasGeospatialIssue=F)
	
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
    
    # update record start
    start <- start + 500

    # update flag
    endOfRecords <- data$meta$endOfRecords
}