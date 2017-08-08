#' @title
#' Is Valid datasets
#'
#' @description
#' Validate policies, claims, and claimvaluations
#'
#' @details
#' Checks datasets for valid columns, values, and relational properties.  Returns TRUE if valid, FALSE otherwise.
#'
#' @param policies data.table object with columns {"PolicyID"}
#' @param claims data.table object with columns {"ClaimID", "PolicyID", "DOL"}
#' @param claimvaluations data.table object with columns {"ValuationDate", "ClaimID"}
#'
#' @export
#' @import data.table
#'
#' @examples
#' library(data.table)
#'
#' # Sample datasets
#' policiez
#' claimz
#' claimvaluationz
#'
#' # Validate
#' is_valid_datasets(policiez, claimz, claimvaluationz)
#' is_valid_datasets(policiez[1], claimz, claimvaluationz)

is_valid_datasets <- function(policies, claims, claimvaluations){
  # Run tests to validate the data

  #--------------------------------------------------
  # Run tests for each dataset in isolation

  is_valid_policies(policies)
  is_valid_claims(claims)
  is_valid_claimvaluations(claimvaluations)

  #--------------------------------------------------
  # Test relational fields

  # Is there a policy in claims not in policies?
  polsInClaimsNotPolicies <- claims[, list(1), keyby=PolicyID][!policies, on="PolicyID"]
  if(nrow(polsInClaimsNotPolicies) > 0){
    warning(paste(nrow(polsInClaimsNotPolicies), "unique PolicyIDs in claims not in policies"))
    return(FALSE)
  }

  # Is every claim in claimvaluations?
  claimsNotInClaimValuations <- claims[!claimvaluations, on="ClaimID"]
  if(nrow(claimsNotInClaimValuations) > 0){
    warning(paste(nrow(claimsNotInClaimValuations), "unique ClaimIDs in claims not in claimvaluations"))
    return(FALSE)
  }

  # Is there a claim in claimvaluations not in claims?
  claimsInClaimValuationsNotInClaims <- claimvaluations[, list(1), keyby=ClaimID][!claims, on="ClaimID"]
  if(nrow(claimsInClaimValuationsNotInClaims) > 0){
    warning(paste(nrow(claimsInClaimValuationsNotInClaims), "unique ClaimIDs in claimvaluations not in claims"))
    return(FALSE)
  }

  #--------------------------------------------------
  # Datasets are valid

  return(TRUE)

}
