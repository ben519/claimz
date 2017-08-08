#' @title
#' Is Valid claim-valuations
#'
#' @description
#' Validate a claim-valuations dataset
#'
#' @details
#' Checks claim-valuations dataset for valid columns, values, and other properties.  Returns TRUE if valid, FALSE otherwise.
#'
#' @param claimvaluations data.table object with columns {"ValuationDate", "ClaimID"}
#'
#' @export
#' @import data.table
#'
#' @examples
#' library(data.table)
#'
#' # Sample claimvaluations
#' claimvaluationz
#'
#' # Validate
#' is_valid_claimvaluations(claimvaluationz)
#' is_valid_claimvaluations(claimvaluationz[, list(Claimid = ClaimID, ValuationDate)])

is_valid_claimvaluations <- function(claimvaluations){
  # Check the claimvaluations dataset for expected properties

  #--------------------------------------------------
  # Check for required fields

  fields.claimvaluations <- c("ValuationDate", "ClaimID")
  missingfields.claimvaluations <- setdiff(fields.claimvaluations, colnames(claimvaluations))
  if(length(missingfields.claimvaluations > 0)){
    warning(paste0("These fields missing from claimvaluations:{", paste(missingfields.claimvaluations, collapse=", "), "}"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Check (ClaimID, ValuationDate) for uniqueness

  dupes.IDValDt <- sum(duplicated(claimvaluations[, list(ClaimID, ValuationDate)]))
  if(dupes.IDValDt > 0){
    warning(paste("claimvaluations contains", dupes.IDValDt, "duplicate (ClaimID, ValuationDate) pairs"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Dataset is valid

  return(TRUE)
}
