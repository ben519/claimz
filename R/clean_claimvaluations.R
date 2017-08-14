#' @title
#' Clean claim-valuations
#'
#' @description
#' Adjust the column names of a data.table of claimvaluations so that the resulting column names match the required names for
#' claimz functions.
#'
#' @details
#' Returns a data.table object, a copy of claimvaluations with required column names.
#'
#' @param claimvaluations data.table object
#' @param colmap a mapping of column names in the form of a named character vector, or NULL
#'
#' @import data.table
#'
#' @export
#' @examples
#' library(data.table)
#'
#' # Sample claim valuations
#' claimvaluationz
#' claimvaluations <- copy(claimvaluationz)
#' setnames(claimvaluations, c("ClaimID"), c("claim_id"))
#' colmap <- c(
#'   "ClaimID"="claim_id",
#'   "PolicyID"="PolicyID",
#'   "EffectiveDate"="EffectiveDate",
#'   "ExpirationDate"="ExpirationDate",
#'   "DateOfLoss"="DateOfLoss",
#'   "ReportDate"="ReportDate"
#' )
#' clean_claimvaluations(claimvaluations, colmap)


clean_claimvaluations <- function(claimvaluations, colmap=NULL){
  # Returns a copy of claimvaluations with adjusted column names, so that new column names
  # are guaranteed to match the column names used internally for all claimz functions
  # colmap should have required fields c(ClaimID = "...", DateOfLoss = "...", ReportDate = "...")
  # colmap may have additional recognized fields c(EffectiveDate = "...", ExpirationDate = "...", PolicyID = "...", Paid = "...")
  # E.g. claimvaluations <- copy(claimz)

  # Special claimvaluations fields
  reqfields <- c("ClaimID", "ValuationDate", "DateOfLoss", "ReportDate")
  addtlfields <- c("EffectiveDate", "ExpirationDate", "PolicyID")

  # If colmap argument is null, but colmap exists as an attribute within the claimvaluations object
  if(is.null(colmap) & exists("colmap", where=attributes(claimvaluations)))
    colmap <- attr(claimvaluations, "colmap")

  # If colmap is null (and not an attribute of claimvaluations)
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

  # Copy claimvaluations and adjust colnames
  claimvaluationsCopy <- copy(as.data.table(claimvaluations))
  setnames(claimvaluationsCopy, colmap, names(colmap))

  # Add colmap attribute to claimvaluationsCopy
  setattr(claimvaluationsCopy, "colmap", colmap)

  # Check for validity and return result
  if(is_valid_claimvaluations(claimvaluationsCopy))
    return(claimvaluationsCopy[])
}
