#' @title
#' Is Valid claims
#'
#' @description
#' Validate a claims dataset
#'
#' @details
#' Checks claims dataset for valid columns, values, and other properties.  Returns TRUE if valid, FALSE otherwise.
#'
#' @param claims data.table object with columns {"ClaimID", "PolicyID", "DateOfLoss"}
#'
#' @export
#' @import data.table
#'
#' @examples
#' library(data.table)
#'
#' # Sample claims
#' claimz
#'
#' # Validate
#' is_valid_claims(claimz)
#' is_valid_claims(claimz[, c("PolicyID", "EffectiveDate")])

is_valid_claims <- function(claims){
  # Check the claims dataset for expected properties

  #--------------------------------------------------
  # Check for required fields

  fields.claims <- c("ClaimID", "PolicyID", "DateOfLoss")
  missingfields.claims <- setdiff(fields.claims, colnames(claims))
  if(length(missingfields.claims > 0)){
    warning(paste0("These fields missing from claims:{", paste(missingfields.claims, collapse=", "), "}"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Check ID for uniqueness

  dupes.ClaimID <- sum(duplicated(claims$ClaimID))
  if(dupes.ClaimID > 0){
    warning(paste("claims contains", dupes.ClaimID, "duplicate ClaimIDs"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Dataset is valid

  return(TRUE)
}
