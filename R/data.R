#' Policies sample dataset
#'
#' A dataset with sample policies
#'
#' @format A data.table with 2 rows and 3 variables:
#' \describe{
#'   \item{PolicyID}{Unique identifier}
#'   \item{EffectiveDate}{Effective date}
#'   \item{ExpirationDate}{Expiration date}
#' }
#'
#' @details
#' library(data.table)
#'
#' policiez <- data.table::data.table(
#'   PolicyID = c(1,2),
#'   EffectiveDate = as.Date(c("2014-1-1", "2014-6-1")),
#'   ExpirationDate = as.Date(c("2015-1-1", "2015-6-1"))
#' )
#'
#' save(policiez, file="data/policiez.rda")
"policiez"


#' Claims sample dataset
#'
#' A dataset with sample claims
#'
#' @format A data.table with 3 rows and 5 variables:
#' \describe{
#'   \item{ClaimID}{Unique identifier}
#'   \item{PolicyID}{Associated Policy ID}
#'   \item{EffectiveDate}{Effective date of the policy}
#'   \item{ExpirationDate}{Expiration date of the policy}
#'   \item{DOL}{Date of Loss}
#' }
#'
#' @details
#' library(data.table)
#'
#' claimz <- data.table(
#'   ClaimID = c(1,2,3),
#'   PolicyID = c(1,1,2),
#'   DOL = as.Date(c("2014-3-15", "2014-4-1", "2015-5-30"))
#' )
#' claimz <- policiez[claimz, on="PolicyID"]
#' setcolorder(claimz, c("ClaimID", "PolicyID", "EffectiveDate", "ExpirationDate", "DOL"))
#'
#' save(claimz, file="data/claimz.rda")
"claimz"


#' Claim Valuations sample dataset
#'
#' A dataset with sample claim valuations
#'
#' @format A data.table with 2 rows and 3 variables:
#' \describe{
#'   \item{ClaimValuationID}{Unique identifier}
#'   \item{ClaimID}{Associated Claim ID}
#'   \item{PolicyID}{Associated Policy ID}
#'   \item{EffectiveDate}{Effective date of the policy}
#'   \item{ExpirationDate}{Expiration date of the policy}
#'   \item{DOL}{Date of Loss of the claim}
#'   \item{ValuationDate}{Valuation Date}
#'   \item{Incurred}{Incurred as of ValuationDate}
#' }
#'
#' @details
#' library(data.table)
#'
#' claimvaluationz <- data.table(
#'   ClaimValuationID = c(1,2,3,4,5),
#'   ClaimID = c(1,2,1,2,3),
#'   ValuationDate = as.Date(c("2015-1-1", "2015-1-1", "2016-1-1", "2016-1-1", "2016-1-1")),
#'   Incurred = c(100, 150, 125, 230, 75)
#' )
#' claimvaluationz <- claimz[claimvaluationz, on="ClaimID"]
#' setcolorder(
#'   claimvaluationz,
#'   c("ClaimValuationID", "ClaimID", "PolicyID", "EffectiveDate", "ExpirationDate", "DOL", "ValuationDate", "Incurred")
#' )
#'
#' save(claimvaluationz, file="data/claimvaluationz.rda")
"claimvaluationz"
