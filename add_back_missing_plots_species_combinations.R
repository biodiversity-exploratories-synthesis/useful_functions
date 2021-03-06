# Note : the function depends on the package data.table, if not available, install it with
#     install.packages("data.table")
#     all other explanation is given in the documentation below.

#' Add back missing plots x species combinations
#' 
#' date of creation : 26.01.21
#' In order to save storage, the diversity dataset for bacteria and soil fungi o not include all combinations
#' of plots x species when a given species was not found in a given plot i.e. they do not contain zeros.
#' They need to be added back in order to gain the complete set of studied plots (missing plots x
#' species are not NA but measured, just the given species was not found).
#' Code from Caterina Penone, for further explanations and rationale
#' see https://github.com/biodiversity-exploratories-synthesis/Synthesis-dataset-manual/blob/main/Synthesis%20datasets%20%20How%20to%20use.md
#' Note : Only the columns Plot and Species are considered, any other columns will be filled with NA.
#' This can cause problems if the dataset is later filtered for e.g. Year.
#' Note : special case if the input dataset does not contain all Plots, if certain plots do not 
#' contain any species. This special case is detected and solved in this function.
#' 
#' @param diversity_dataset A data.table of soilfuni or bacteria in the format of the synthesis diversity 
#' dataset, with at least the columns Plot, Species and value.
#' #' @param all_plots a character vector containing the complete set of plots from the 
#' Exploratories. (AEG 1-50, HEG 1-50 and SEG 1-50). Is needed for the subfunction
#' find_and_supplement_missing_plots.
#' @return A data.table in the same format as diversity_dataset, but with the previously
#' missing plots x species added back as 0. Note : Only the columns Plot, Species and value are
#' considered, any other columns will be filled with NA.
#' @export
add_back_missing_plots_species_combinations <- function(diversity_dataset, all_plots){
  # Control : check if there are any NA values, although none would be expected
  if(length(diversity_dataset[is.na(value), value]) > 0){
    stop("There are NA values in the dataset. Missing combinations can not be added.")
  }
  # Control : the provided dataset needs to be a data.table.
  if(!data.table::is.data.table(diversity_dataset)){
    stop("The provided dataset is not a data.table. Please first convert it to data.table with
         data.table(diversity_dataset).")
  }
  # check if the dataset contains all plots, or if plots need to be added manually
  if(length(unique(diversity_dataset$Plot)) < length(all_plots)){ 
    diversity_dataset <- find_and_supplement_missing_plots(diversity_dataset, all_plots)
  }
  
  # add back zeros
  diversity_dataset <- data.table::setDT(diversity_dataset)[data.table::CJ(Species = Species, Plot = Plot, unique = T), on=.(Species, Plot)]
  print(paste(nrow(diversity_dataset[is.na(value)]), "missing combinations were added."))
  diversity_dataset <- diversity_dataset[is.na(value), value := 0 ][] # note about the ending [] :
  # this is a reported bug from data.table, if not added, the function will not return the data.table
  # at first attempt (only at the second). https://stackoverflow.com/questions/32988099/data-table-objects-assigned-with-from-within-function-not-printed
  return(diversity_dataset)
}
NULL


#' Fill number of plots to 150
#' 
#' Subfunction for add_back_missing_plots_species_combinations
#' A dataset from soilfungi or bacteria can miss some plots. This happens if there are plots
#' without any species (e.g. for symbiont.soilfungi in 2011).
#' The dataset needs to be extended with the missing plots in order to use the function
#' `add_back_missing_plots_species_combinations`, because this function only adds the missing
#' plot x species combination, not completely missing plots.
#' 
#' @param diversity_dataset a species diversity data.table in the format of the
#' exploratories synthesis diversity dataset. It contains at least the columns Plot, 
#' Species and value.
#' @param all_plots a character vector containing the complete set of plots from the 
#' Exploratories. (AEG 1-50, HEG 1-50 and SEG 1-50).
#' @return a data.table consisting of the unchanged diversity_dataset as it has been provided 
#' as input, rbinded to a minimal data.table containing a random species and the 
#' missing plots.
find_and_supplement_missing_plots <- function(diversity_dataset, all_plots){
  if(length(unique(diversity_dataset$Plot)) == length(all_plots)){
    print("The dataset already contains the number of expected plots, no need to supplement missing ones.")
  } else {
    # find the set of missing plots and store to vector
    # get random species to be supplemented (only 1 is needed, all missing combinations
    # will be supplemented by add_back_missing_plots_species_combinations)
    # create a supplement dataset
    missing_plots <- all_plots[!all_plots %in% unique(diversity_dataset$Plot)]
    random_species <- diversity_dataset$Species[1]
    complementary_dataset <- data.table::data.table(Plot = missing_plots, Species = random_species, value = 0)
    diversity_dataset <- rbindlist(list(diversity_dataset, complementary_dataset), fill = T, use.names = T)
    # check if number of plots is the expected 150 now
    if(length(unique(diversity_dataset$Plot)) != length(all_plots)){
      stop("The number of plots is not the expected number. Check length of vector all_plots.")
    }
    return(diversity_dataset)
  }
}
NULL
