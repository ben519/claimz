#' @title
#' Claims At
#'
#' @description
#' Given a data.table of claimvaluations (i.e. with columns {"ValuationDate", "ClaimID", ...}), return claim-level subsets of the
#' data.
#'
#' @details
#' One may return
#' \describe{
#'   \item{claims valued as of a specific date}{E.g. "claims valued as of 2016-12-31"}
#'   \item{claims valued as of a specific claim age}{E.g. "claims valued as of age = 9 months"}
#'   \item{claims valued as of a specific policy age}{E.g. "claims at the instant their policy is of age = 12 months"}
#' }
#' Here, "claim age" refers to the number of months since the date of loss (DOL) while "policy age" refers to the number of months
#' since the effective date.  Additionally, the parameter \code{maxValuationDate} may be provided to prevent results which have
#' future valuation dates.  For example, if claimvaluations has monthly valuations from Jan 2010 thru Dec 2016, specifying
#' \code{maxValuationDate = as.Date("2016-12-31")} and calling claims_at(claimvaluationz, claimAge = 2) will discard all claims
#' which occured in Novemeber and December of 2016.
#'
#' @param claimvaluations data.table object with columns {"ValuationDate", "ClaimID"}. Depending on the exact call to
#' claims_at(...), other columns may be required.
#' @param valuationDate return all claims valued as of this date
#' @param claimAge return all claims as of this age, as measured in months since DOL
#' @param policyAge return all claims valued at the time their policy is this age, as measured in months since Effective Date
#' @param maxValuationDate don't return claims valued after this date
#' @param dropNAs should claims be included in the result if their first valuation date is before the specified ValuationDate?
#'
#' @import data.table
#' @import lubridate
#'
#' @examples
#' library(data.table)
#' library(lubridate)
#'
#' # Sample claim valuations
#' claimvaluationz
#'
#' # View claims as they were valued on 2015-06-30
#' claims_at(claimvaluationz, valuationDate = as.Date("2015-06-30"))
#'
#' # View each claim at age = 12 months
#' claims_at(claimvaluationz, claimAge = 12)
#'
#' # View each claim at age = 12 months, assuming the data is valued as of 2016-03-01
#' claims_at(claimvaluationz, claimAge = 12, maxValuationDate = as.Date("2016-03-01"))
#'
#' # View claims as they were valued when each policy was age = 12 months
#' claims_at(claimvaluationz, policyAge = 12)

claims_at <- function(claimvaluations, valuationDate=NULL, claimAge=NULL, policyAge=NULL, maxValuationDate=NULL, dropNAs=FALSE){
  # Returns a set of unique claims, each mapped to a single row in claimvaluations
  # The resulting data.table has columns {ClaimValuationID, ClaimID, ValuationDate}
  #
  # If valuationDate is given, each claim in the result set corresponds to the row of claimvaluations (for the same ClaimID)
  #   closest to but before valuationDate. If a claim did not exist as of valuationDate it will either be excluded from the
  #   result set or returned with NA values depnding on whether dropNAs is TRUE or FALSE
  #
  # If claimAge is given, claimAge months will be added to the DOL for each claim to generate the reference ValuationDate for
  #   for each claim and then the same procedure as above will occur. Note that this can result in some claims with invalid
  #   results (consider a brand new claim). Provide value for maxValuationDate to safeguard for this.
  #
  # If policyAge is given, same as above except policyAge months is added to the EffectiveDate of the policy for each claim

  #--------------------------------------------------
  # Chek inputs

  if(length(setdiff(c("ClaimValuationID", "ClaimID", "ValuationDate"), colnames(claimvaluations))) > 0)
    stop("claimvaluations is missing the required columns {ClaimValuationID, ClaimID, ValuationDate}")

  if(is.null(valuationDate) + is.null(claimAge) + is.null(policyAge) != 2)
    stop("Exactly one of {valuationDate, claimAge, policyAge} must be given")

  if(!is.null(claimAge) & !"DOL" %in% colnames(claimvaluations))
    stop("claimAge is specified, but DOL is not in claimvaluations")

  if(!is.null(policyAge) & !"EffectiveDate" %in% colnames(claimvaluations))
    stop("claimAge is specified, but EffectiveDate is not in claimvaluations")

  if(!is.null(valuationDate) & !is.null(maxValuationDate))
    warning("Warning - It rarely makes sense to specify maxValuationDate when valuationDate is given")

  #--------------------------------------------------
  # Algorithm:
  #
  # Determine the desired valuation date for every claim based on inputs
  # Get the record in claimvaluations that corresponds to every (claim, desired valuation) pair via forward rolling join
  #   from claimvaluations to (claim, desired valuation) pairs, keeping every (claim, desired valuation) pair

  # Build the claim set and get the desired valuation date per claim
  if(!is.null(valuationDate)){
    claims <- unique(claimvaluations[, list(ClaimID)])
    claims[, DesiredValDate := valuationDate]
  } else if(!is.null(claimAge)){
    claims <- unique(claimvaluations[, list(ClaimID, DOL)])
    claims[, DesiredValDate := DOL %m+% months(claimAge)]
  } else if(!is.null(policyAge)){
    claims <- unique(claimvaluations[, list(ClaimID, EffectiveDate, DOL)])
    claims[, DesiredValDate := DOL %m+% months(policyAge)]
  }

  # Execute rolling join to get the nearest claim valuation prior to each (ClaimID, ValuationDate) pair
  cv <- claimvaluations[, list(ClaimValuationID, ClaimID, DesiredValDate=ValuationDate, CHValuationDate=ValuationDate)]
  result <- cv[claims, roll=TRUE, on=c("ClaimID", "DesiredValDate")]

  # If maxValuationDate is given, invalidate rows where DesiredValDate > maxValuationDate
  if(!is.null(maxValuationDate)) result[DesiredValDate > maxValuationDate, `:=`(ClaimValuationID=NA, CHValuationDate=NA)]

  # If dropNAs is TRUE, remove claims with ClaimValuationID as NA
  # E.g. User wants claims @ age 24, but claim occured today and maxValuationDate is specifed as today
  if(dropNAs) result <- result[!is.na(ClaimValuationID)]

  # Fix column names
  setnames(result, "DesiredValDate", "ValuationDate")

  return(result[])
}

# ## EXAMPLES
# claims_at(claimvaluations, valuationDate=as.Date("2016-2-23"))
# claims_at(claimvaluations, valuationDate=as.Date("2015-10-15"))
# claims_at(claimvaluations, valuationDate=as.Date("2015-1-1"))
# claims_at(claimvaluations, valuationDate=as.Date("2015-1-1"), dropNAs=TRUE)
# claims_at(claimvaluations, claimAge = 9)
# claims_at(claimvaluations, claimAge = 24)
# claims_at(claimvaluations, claimAge = 24, maxValuationDate=as.Date("2017-1-1"))
