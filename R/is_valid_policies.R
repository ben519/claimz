#' @title
#' Is Valid policies
#'
#' @description
#' Validate a policies dataset
#'
#' @details
#' Checks policies dataset for valid columns, values, and other properties.  Returns TRUE if valid, FALSE otherwise.
#'
#' @param policies data.table object with columns {"PolicyID"}
#'
#' @import data.table
#'
#' @examples
#' library(data.table)
#'
#' # Sample policies
#' policiez
#'
#' # Validate
#' is_valid_policies(policiez)
#' is_valid_policies(rbind(policiez, policiez))

is_valid_policies <- function(policies){
  # Check the policies dataset for expected properties

  #--------------------------------------------------
  # Check for required fields

  fields.policies <- c("PolicyID")
  missingfields.policies <- setdiff(fields.policies, colnames(policies))
  if(length(missingfields.policies > 0)){
    warning(paste0("These fields missing from policies:{", paste(missingfields.policies, collapse=", "), "}"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Check ID for uniqueness

  dupes.PolicyID <- sum(duplicated(policies$PolicyID))
  if(dupes.PolicyID > 0){
    warning(paste("policies contains", dupes.PolicyID, "duplicate PolicyIDs"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Dataset is valid

  return(TRUE)
}
