# Validate policies, claims, and claimvaluations

check_datasets <- function(policies, claims, claimvaluations){
  # Run tests to validate the data

  #--------------------------------------------------
  # Run tests for each dataset in isolation

  check_policies(policies)
  check_claims(claims)
  check_claimvaluations(claimvaluations)

  #--------------------------------------------------
  # Test relational fields

  # Is there a policy in claims not in policies?
  polsInClaimsNotPolicies <- claims[, list(1), keyby=PolicyID][!policies, on="PolicyID"]
  if(nrow(polsInClaimsNotPolicies) > 0)
    warning(paste(nrow(polsInClaimsNotPolicies), "unique PolicyIDs in claims not in policies"))

  # Is every claim in claimvaluations?
  claimsNotInClaimValuations <- claims[!claimvaluations, on="ClaimID"]
  if(nrow(claimsNotInClaimValuations) > 0)
    warning(paste(nrow(claimsNotInClaimValuations), "unique ClaimIDs in claims not in claimvaluations"))

  # Is there a claim in claimvaluations not in claims?
  claimsInClaimValuationsNotInClaims <- claimvaluations[, list(1), keyby=ClaimID][!claims, on="ClaimID"]
  if(nrow(claimsInClaimValuationsNotInClaims) > 0)
    warning(paste(nrow(claimsInClaimValuationsNotInClaims), "unique ClaimIDs in claimvaluations not in claims"))
}

# check_datasets(policies, claims, claimvaluations)
