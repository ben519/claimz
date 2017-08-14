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
#' Here, "claim age" refers to the number of months since the date of loss (DateOfLoss) while "policy age" refers to the number of months
#' since the effective date.  Additionally, the parameter \code{maxValuationDate} may be provided to prevent results which have
#' future valuation dates.  For example, if claimvaluations has monthly valuations from Jan 2010 thru Dec 2016, specifying
#' \code{maxValuationDate = as.Date("2016-12-31")} and calling claims_at(claimvaluationz, claimAge = 2) will discard all claims
#' which occured in Novemeber and December of 2016.
#'
#' @param claimvaluations data.table object with columns {"ValuationDate", "ClaimID"}. Depending on the exact call to
#' claims_at(...), other columns may be required.
#' @param valuationDate return all claims valued as of this date
#' @param claimAge return all claims as of this age, as measured in months since DateOfLoss
#' @param policyAge return all claims valued at the time their policy is this age, as measured in months since Effective Date
#' @param maxValuationDate don't return claims valued after this date
#' @param dropImmatureValuations should claims be excluded in the result if their first valuation date is before maxValuationDate?
#'
#' @importFrom lubridate %m+%
#' @import data.table
#'
#' @export
#' @examples
#' library(lubridate)
#' library(data.table)
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

claims_at <- function(claimvaluations, valuationDate = NULL, claimAge = NULL, policyAge = NULL, maxValuationDate = NULL,
                      dropImmatureValuations = TRUE, colmap_claimvaluations = NULL){
  # Returns a set of unique claims, each mapped to a single row in claimvaluations
  # The resulting data.table has columns {ClaimID, ValuationDate}
  #
  # If valuationDate is given, each claim in the result set corresponds to the row of claimvaluations (for the same ClaimID)
  #   closest to but before valuationDate. If a claim did not exist as of valuationDate it will either be excluded from the
  #   result set or returned with NA values depnding on whether dropImmatureValuations is TRUE or FALSE
  #
  # If claimAge is given, claimAge months will be added to the DateOfLoss for each claim to generate the reference ValuationDate for
  #   for each claim and then the same procedure as above will occur. Note that this can result in some claims with invalid
  #   results (consider a brand new claim). Provide value for maxValuationDate to safeguard for this.
  #
  # If policyAge is given, same as above except policyAge months is added to the EffectiveDate of the policy for each claim

  #--------------------------------------------------
  # Clean claimvaluations

  claimvaluations <- clean_claimvaluations(claimvaluations = claimvaluations, colmap = colmap_claimvaluations)

  #--------------------------------------------------
  # Chek inputs

  if(length(setdiff(c("ClaimID", "ValuationDate"), colnames(claimvaluations))) > 0)
    stop("claimvaluations is missing the required columns {ClaimID, ValuationDate}")

  if(is.null(valuationDate) + is.null(claimAge) + is.null(policyAge) != 2)
    stop("Exactly one of {valuationDate, claimAge, policyAge} must be given")

  if(!is.null(claimAge) & !"DateOfLoss" %in% colnames(claimvaluations))
    stop("claimAge is specified, but DateOfLoss is not in claimvaluations")

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
    claims <- unique(claimvaluations[, list(ClaimID, DateOfLoss)])
    claims[, DesiredValDate := DateOfLoss %m+% months(claimAge)]
  } else if(!is.null(policyAge)){
    claims <- unique(claimvaluations[, list(ClaimID, EffectiveDate)])
    claims[, DesiredValDate := EffectiveDate %m+% months(policyAge)]
  }

  # Execute rolling join to get the nearest claim valuation prior to each (ClaimID, ValuationDate) pair
  cv <- claimvaluations[, list(ClaimID, DesiredValDate=ValuationDate, CHValuationDate=ValuationDate)]
  result <- cv[claims, roll=TRUE, on=c("ClaimID", "DesiredValDate")]

  # If maxValuationDate is given, invalidate rows where DesiredValDate > maxValuationDate
  if(!is.null(maxValuationDate)){
    if(dropImmatureValuations == TRUE){
      result <- result[DesiredValDate <= maxValuationDate]
    } else{
      result[DesiredValDate > maxValuationDate, `:=`(CHValuationDate=NA)]
    }
  }

  # Pull in the oether claimvaluations fields
  result <- claimvaluations[result, on=c("ClaimID", "ValuationDate"="CHValuationDate")]

  # Fix column names and order
  setnames(result, c("DesiredValDate", "ValuationDate"), c("ValuationDate", "CHValuationDate"))
  setcolorder(result, unique(c("ClaimID", "ValuationDate", "CHValuationDate", colnames(result))))

  return(result[])
}
