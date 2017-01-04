#' @title
#' Check Claim Valuations
#'
#' @description
#' Validate a claimvaluations dataset

check_claimvaluations <- function(claimvaluations){
  # Check the claimvaluations dataset for expected properties

  #--------------------------------------------------
  # Check for required fields

  fields.claimvaluations <- c("ClaimValuationID", "ClaimID", "ValuationDate")
  missingfields.claimvaluations <- setdiff(fields.claimvaluations, colnames(claimvaluations))
  if(length(missingfields.claimvaluations > 0))
    warning(paste0("These fields missing from claimvaluations:{", paste(missingfields.claimvaluations, collapse=", "), "}"))

  #--------------------------------------------------
  # Check ID for uniqueness

  dupes.ClaimValuationID <- sum(duplicated(claimvaluations$ClaimValuationID))
  if(dupes.ClaimValuationID > 0)
    warning(paste("claimvaluations contains", dupes.ClaimValuationID, "duplicate ClaimValuationIDs"))

  #--------------------------------------------------
  # Check (ClaimID, ValuationDate) for uniqueness

  dupes.IDValDt <- sum(duplicated(claimvaluations[, list(ClaimID, ValuationDate)]))
  if(dupes.IDValDt > 0)
    warning(paste("claimvaluations contains", dupes.IDValDt, "duplicate (ClaimID, ValuationDate) pairs"))
}
