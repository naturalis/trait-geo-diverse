library(DBI)
library(ape)

# tree_id <- 12
# tip_vector <- c("Homo sapiens", "Pan troglodytes", "Gorilla gorilla")
# db_file <- "/Users/rutger.vos/Documents/local-projects/trait-geo-diverse/data/sql/tgd.db"

# THIS IS VERY EXPERIMENTAL AND INEFFICIENT CODE!!!

make.phylo <- function(db_file,tree_id,tip_vector) {
	
	# will use this with sprintf
	branch_template <- "select node_id,parent_id,branch_length from branches where node_id=%d and tree_id=%d"
	parent_template <- "select parent_id from branches where node_id=%d and tree_id=%d"
	id_template <- 'select branches.node_id
	from ((taxonvariants 
	inner join taxa on taxonvariants.taxon_id = taxa.taxon_id)
	inner join branches on branches.taxonvariant_id = taxonvariants.taxonvariant_id)
	where taxa.taxon_name="%s" and
	branches.tree_id=%d limit 1'
	
	# connect to the database
	db <- dbConnect(RSQLite::SQLite(), db_file)
	
	# lookup IDs for names
	temp <- vector(mode="integer", length=length(tip_vector))
	for ( i in 1:length(tip_vector) ) {
		id_lookup <- dbGetQuery(db, sprintf(id_template, tip_vector[i], tree_id))$node_id
		temp[i] <- id_lookup
	}
	
	# build a list of node IDs anywhere in the tree
	total <- temp
	uniq <- unique(temp)
	while(length(uniq) > 1) {
		result <- vector(mode="integer", length=length(uniq))
		for ( i in 1:length(uniq) ) {
			result[i] <- dbGetQuery(db, sprintf(parent_template,uniq[i],tree_id))$parent_id
		}
		uniq <- unique(na.omit(result))
		total <- unique(c(total, uniq))
	}
	
	## List of 4
	##  $ edge       : int [1:38, 1:2] 21 22 23 24 24 23 25 26 27 27 ...
	##  $ tip.label  : chr [1:20] "t1" "t20" "t2" "t7" ...
	##  $ edge.length: num [1:38] 0.0729 0.8743 0.1989 0.5346 0.1056 ...
	##  $ Nnode      : int 19
	max <- length(total)-1
	edge <- matrix(nrow=max,ncol=2)
	tip.label <- tip_vector
	edge.length <- vector(mode="numeric", length=max)
	Nnode <- as.integer( length(total) - length(tip_vector) )
	j <- 1
	lookup <- list()
	for ( i in 1:max ) {
		result <- dbGetQuery(db, sprintf(branch_template,total[i],tree_id))
		edge[i,1] <- result$parent_id
		edge[i,2] <- result$node_id
		edge.length[i] <- result$branch_length
		lookup[ as.character(result$node_id) ] <- j
		j <- j + 1
	}
	lookup[ as.character(edge[max,1]) ] <- j
	for ( i in 1:max ) {
		value <- edge[i,1]
		edge[i,1] <- as.integer(lookup[[ as.character(value) ]])
		value <- edge[i,2]
		edge[i,2] <- as.integer(lookup[[ as.character(value) ]])
	}
	obj <- list(edge=edge,tip.label=tip.label,edge.length=edge.length,Nnode=Nnode)
	class(obj) <- "phylo"
	
	# God help me, why is this necessary. Clearly the phylo object is sensitive to something like:
	# - unbranched internal nodes
	# - root branches
	# - unexpected node orders
	# One day I will know R well enough to do this elegantly.
	newick <- write.tree(obj)
	obj <- read.tree(text = newick)
	obj$tip.label <- gsub("_", " ", obj$tip.label)
	obj
}