#' Validate a policies dataset

check_policies <- function(policies){
  # Check the policies dataset for expected properties

  #--------------------------------------------------
  # Check for required fields

  fields.policies <- c("PolicyID")
  missingfields.policies <- setdiff(fields.policies, colnames(policies))
  if(length(missingfields.policies > 0))
    warning(paste0("These fields missing from policies:{", paste(missingfields.policies, collapse=", "), "}"))

  #--------------------------------------------------
  # Check ID for uniqueness

  dupes.PolicyID <- sum(duplicated(policies$PolicyID))
  if(dupes.PolicyID > 0)
    warning(paste("policies contains", dupes.PolicyID, "duplicate PolicyIDs"))
}
