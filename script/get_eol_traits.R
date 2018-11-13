library(DBI)
library(dplyr)
library(traits)
library(taxize)
library(logging)
basicConfig()

# get species names from database
db      <- dbConnect(RSQLite::SQLite(), "data/sql/tgd.db")
query   <- "select taxon_name from taxa where taxa.taxon_level='SPECIES' order by taxa.taxon_name"
species <- dbGetQuery(db, query)$taxon_name

# get EOL identifiers for species names
sources  <- gnr_datasources()
eol_id   <- sources[sources$title == "EOL", "id"]
eol_tnrs <- gnr_resolve( species, data_source_ids = c(eol_id), fields = "all" )
results  <- data.frame( row.names = species )

# iterate over species
for ( sp in species ) {
	
	# get the EOL taxon ID for focal species
	eol_taxon_id <- unique( eol_tnrs[eol_tnrs$matched_name == sp,]$local_id )
	
	# fetch the traits
	eol_traits <- list()
	try( eol_traits <- traitbank(eol_taxon_id) )
	
	# check if there are results in the graph
	if ( length(eol_traits[["graph"]]) > 0 ) {
		loginfo('have traits for %s', sp)
		for ( trait in unique(eol_traits[["graph"]]$predicate) ) {
			value <- first( filter( eol_traits[["graph"]], predicate == trait )$value )
			loginfo('%s => %s => %s', sp, trait, value)
			results[ sp, trait ] <- value
		}
	}
	else {
		loginfo('no traits for %s', sp)
	}	
}
write.table(results, file="data/traits/eol.tsv", quote=F, sep="\t", na="")