library(DBI)

#db_file <- "/Users/rutger.vos/Documents/local-projects/trait-geo-diverse/data/sql/tgd.db"
#taxon_name <- "ARTIODACTYLA"
#taxon_rank <- "SPECIES"
#db <- NA
#result <- list()

expand.taxon <- function(db_file,taxon_name,taxon_level='SPECIES',tree_id=11,db=NA,result=list()) {
		
	# connect to the database
	if ( class(db) != 'SQLiteConnection' ) {
		db <- dbConnect(RSQLite::SQLite(), db_file)
	}
	
	# we are at the start of the recursion
	if ( length(result) == 0 ) {
		
		# first we look for the node_id, taxon_level, taxon_name of the input
		query_lookup <- 'select branches.node_id,taxa.taxon_level,taxa.taxon_name
					from ((taxonvariants 
			   		inner join taxa on taxonvariants.taxon_id = taxa.taxon_id)
			  		inner join branches on branches.taxonvariant_id = taxonvariants.taxonvariant_id)
					where branches.tree_id=%d and taxa.taxon_name="%s"'
		
		# do the first query and store it in the result set, then recurse
		record <- dbGetQuery(db, sprintf(query_lookup,tree_id,taxon_name))
		result[ as.character(record$node_id) ] <- list(record)
		expand.taxon(
			db_file,
			taxon_name,
			taxon_level,
			tree_id,
			db,
			result
		)
	}
	else {
		
		# expand to children for all items that aren't yet at the taxon_level
		query_expand <- 'select branches.node_id,taxa.taxon_level,taxa.taxon_name
			from ((taxonvariants 
			inner join taxa on taxonvariants.taxon_id = taxa.taxon_id)
			inner join branches on branches.taxonvariant_id = taxonvariants.taxonvariant_id)
			where branches.tree_id=%d and branches.parent_id=%d'
		
		for ( r in result ) {
			
			# coerce to string
			char_id <- as.character(r$node_id)
			
			# we will process this ID
			if ( result[[char_id]]$taxon_level != taxon_level ) {
				result[char_id] <- NULL # splices record out of set
				
				# gets children, which we insert in the result set
				records <- dbGetQuery(db, sprintf(query_expand,tree_id,r$node_id))
				for( i in 1:length(records$node_id) ) {
					result[ as.character(records$node_id[[i]]) ] <- list(list(
						node_id     = records$node_id[[i]],
						taxon_level = records$taxon_level[[i]],
						taxon_name  = records$taxon_name[[i]]
					))
				}
			}
		}
		
		# check if we need to recurse
		recurse_deeper <- FALSE
		for ( r in result ) {
			if ( r$taxon_level != taxon_level ) {
				recurse_deeper <- TRUE
				break
			}
		}
		if ( recurse_deeper ) {
			expand.taxon(
				db_file,
				taxon_name,
				taxon_level,
				tree_id,
				db,
				result
			)
		}
		else {
			return(result)
		}
	}
}