#' @title
#' Check Claims
#'
#' @description
#' Validate a claims dataset

check_claims <- function(claims){
  # Check the claims dataset for expected properties

  #--------------------------------------------------
  # Check for required fields

  fields.claims <- c("ClaimID", "PolicyID", "DOL")
  missingfields.claims <- setdiff(fields.claims, colnames(claims))
  if(length(missingfields.claims > 0))
    warning(paste0("These fields missing from claims:{", paste(missingfields.claims, collapse=", "), "}"))

  #--------------------------------------------------
  # Check ID for uniqueness

  dupes.ClaimID <- sum(duplicated(claims$ClaimID))
  if(dupes.ClaimID > 0)
    warning(paste("claims contains", dupes.ClaimID, "duplicate ClaimIDs"))
}
