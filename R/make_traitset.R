library(DBI)

make.traitset <- function(db_file,names,data_source,characters=NA) {
	db <- dbConnect(RSQLite::SQLite(), db_file)
	
	# if no list of character names provided, get all the names from this data source
	if ( is.na(characters) ) {
		query_charnames <- 'select label from characters where data_source="%s" order by char_id'
		characters <- dbGetQuery(db, sprintf(query_charnames,data_source))
	}
	
	# create the data frame
	result <- data.frame(row.names=names)
	
	query_charvalue <- 'select states.character_value 
		from characters,states,taxonvariants 
		inner join taxa on taxonvariants.taxon_id=taxa.taxon_id
		where data_source="%s" and 
		characters.character_id=states.character_id and
		states.taxonvariant_id=taxonvariants.taxonvariant_id and
		taxa.taxon_name="%s"  and
		characters.label="%s"'	
	
	# iterate over rows
	for ( name in names ) {

		# iterate over columns
		i <- 1
		for ( col in characters$label ) {
			value <- dbGetQuery(db,sprintf(query_charvalue,data_source,name,col))
			if ( length(value$character_value) == 0 ) {
				result[name,i] <- NA
			}
			else {
				result[name,i] <- value
			}
			i <- i + 1
		}
	}
	colnames(result) <- characters$label
	return(result)
}