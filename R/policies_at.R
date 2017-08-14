#' @title
#' Claims At
#'
#' @description
#' Returns the given policies at the desired valuation points with Total Incurred
#'
#' @details
#' fill me in
#'
#' @param policies fill me in
#' @param claims fill me in
#' @param claimvaluations fill me in
#' @param valuationDate fill me in
#' @param policyAge fill me in
#' @param maxValuationDate fill me in
#' @param dropNAs fill me in
#'
#' @export
#' @importFrom lubridate %m+%
#' @import data.table
#'
#' @examples
#' library(lubridate)
#' library(data.table)

policies_at <- function(policies, claims, claimvaluations, valuationDate=NULL, policyAge=NULL, maxValuationDate=NULL, dropNAs=FALSE){
  # Returns the given policies at the desired valuation points with Total Incurred
  # Note that Incurred = NA can occur because 1) valuationDate < effectiveDate or 2) valuationDate > maxValuationDate

  #--------------------------------------------------
  # Chek inputs

  if(length(setdiff(c("PolicyID"), colnames(policies))) > 0)
    stop("policies is missing the required columns {PolicyID}")

  if(length(setdiff(c("ClaimID", "PolicyID"), colnames(claims))) > 0)
    stop("claims is missing the required columns {ClaimID, PolicyID}")

  if(length(setdiff(c("ClaimID", "ValuationDate"), colnames(claimvaluations))) > 0)
    stop("claimvaluations is missing the required columns {ClaimID, ValuationDate}")

  if(is.null(valuationDate) + is.null(policyAge) != 1)
    stop("Exactly one of {valuationDate, policyAge} must be given")

  if(!is.null(policyAge) & !"EffectiveDate" %in% colnames(policies))
    stop("claimAge is specified, but EffectiveDate is not in policies")

  if(!is.null(valuationDate) & !is.null(maxValuationDate))
    warning("Warning - It rarely makes sense to specify maxValuationDate when valuationDate is given")

  #--------------------------------------------------
  # Prep the claimvaluations dataset

  cv <- claimvaluations[, list(ClaimID, ValuationDate)]
  cv[claims, PolicyID := PolicyID, on="ClaimID"]
  cv[policies, EffectiveDate := EffectiveDate, on="PolicyID"]

  if(sum(is.na(cv$EffectiveDate)) > 0){
    countNA <- sum(is.na(cv$EffectiveDate))
    warning(paste(countNA, "EffectiveDates could not be mapped to every record in claimvaluations. These records will be dropped."))
  }

  #--------------------------------------------------
  # policyIncurreds

  # Get claimset
  claimset <- claims_at(cv, valuationDate=valuationDate, policyAge=policyAge, maxValuationDate=NULL, dropImmatureValuations=FALSE)

  # Insert PolicyID
  claimset[claims, PolicyID := PolicyID, on="ClaimID"]

  # Insert Incurred
  claimset[claimvaluations, Incurred := Incurred, on=c("ClaimID", "ValuationDate")]

  # Calculate total incurred per policy
  policyIncurreds <- claimset[, list(ValuationDate=ValuationDate[1], Incurred=sum(Incurred)), keyby=PolicyID]

  #--------------------------------------------------
  # Build the pols dataset

  if(!is.null(valuationDate)){
    pols <- policies[, list(PolicyID, EffectiveDate, ValuationDate=valuationDate)]
  } else if(!is.null(policyAge)){
    # pols <- policies[, list(PolicyID, EffectiveDate, ValuationDate=EffectiveDate %m+% months(policyAge))]
    pols <- policies[, list(PolicyID, EffectiveDate, ValuationDate=lubridate::`%m+%`(EffectiveDate, months(policyAge)))]
  }

  #--------------------------------------------------
  # Pull in the incurred amounts

  # Make sure there are no records in policyIncurreds which don't match pols
  mismatch <- policyIncurreds[!pols, on=c("PolicyID", "ValuationDate")]
  if(nrow(mismatch) > 0) stop("Unexpected policies returned by claims_at() inside policies_at(). Will require debugging...")

  # Get the incurreds
  pols <- policyIncurreds[pols, on=c("PolicyID", "ValuationDate")]
  pols[is.na(Incurred) & ValuationDate >= EffectiveDate, Incurred := 0]

  # Use maxValuationDate to invalidate some results
  pols[ValuationDate > maxValuationDate, Incurred := NA]

  # Drop invalid results
  if(dropNAs) pols <- pols[!is.na(Incurred)]

  return(pols[])
}
