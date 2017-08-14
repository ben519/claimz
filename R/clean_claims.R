#' @title
#' Clean claims
#'
#' @description
#' Adjust the column names of a data.table of claims so that the resulting column names match the required names for claimz
#' functions.
#'
#' @details
#' Returns a data.table object, a copy of claims with required column names.
#'
#' @param claims data.table object
#' @param colmap a mapping of column names in the form of a named character vector, or NULL
#'
#' @import data.table
#'
#' @export
#' @examples
#' library(data.table)
#'
#' # Sample claims
#' claimz
#' claims <- copy(claimz)
#' setnames(claims, c("ClaimID"), c("claim_id"))
#' colmap <- c(
#'   "ClaimID"="claim_id",
#'   "PolicyID"="PolicyID",
#'   "EffectiveDate"="EffectiveDate",
#'   "ExpirationDate"="ExpirationDate",
#'   "DateOfLoss"="DateOfLoss",
#'   "ReportDate"="ReportDate"
#' )
#' clean_claims(claims, colmap)


clean_claims <- function(claims, colmap=NULL){
  # Returns a copy of claims with adjusted column names, so that new column names
  # are guaranteed to match the column names used internally for all claimz functions
  # colmap should have required fields c(ClaimID = "...", DateOfLoss = "...", ReportDate = "...")
  # colmap may have additional recognized fields c(EffectiveDate = "...", ExpirationDate = "...", PolicyID = "...", Paid = "...")
  # E.g. claims <- copy(claimz)

  # Special claims fields
  reqfields <- c("ClaimID", "DateOfLoss", "ReportDate")
  addtlfields <- c("EffectiveDate", "ExpirationDate", "PolicyID")

  # If colmap argument is null, but colmap exists as an attribute within the claims object
  if(is.null(colmap) & exists("colmap", where=attributes(claims)))
    colmap <- attr(claims, "colmap")

  # If colmap is null (and not an attribute of claims)
  if(is.null(colmap)){
    colmap <- intersect(colnames(claimvaluations), c(reqfields, addtlfields))
    names(colmap) <- colmap
  }

  # Make sure colmap is valid
  if(!is.null(colmap)){
    if(length(setdiff(reqfields, names(colmap))) > 0)
      stop("At least one of the required fields is missing from colmap")

    if(length(setdiff(names(colmap), c(reqfields, addtlfields))) > 0)
      stop("At least one field in colmap is unrecognized")
  }

  # Copy claims and adjust colnames
  claimsCopy <- copy(as.data.table(claims))
  setnames(claimsCopy, colmap, names(colmap))

  # Add colmap attribute to claimsCopy
  setattr(claimsCopy, "colmap", colmap)

  # Check for validity and return result
  if(is_valid_claims(claimsCopy))
    return(claimsCopy[])
}
