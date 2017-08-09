#' @include helpers.R
#'
#' @title
#' Make Triangles
#'
#' @description
#' Build triangles
#'
#' @details
#' Returns a list of data.table objects
#'
#' @param claimvaluations A data.table of cumulative transaction valuations (result of calling cumulate_transactions())
#' @param format How should the triangles be returned? Either "tall" (a data.table) or "triangular" (a list of data.tables)
#' @param minLeftOrigin See ?triangle_skeleton
#' @param originLength See ?triangle_skeleton
#' @param rowDev See ?triangle_skeleton
#' @param colDev See ?triangle_skeleton
#' @param lastValuationDate See ?triangle_skeleton
#' @param fromMinLeftOrigin See ?triangle_skeleton
#' @param initialAge See ?triangle_skeleton
#' @param colsFinancial What financial columns in \code{claimvaluations} should generate triangles? Default="auto" guesses
#' @param verbose Should progress details be displayed?
#'
#' @export
#' @importFrom lubridate rollback
#' @importFrom lubridate %m+%
#' @importFrom lubridate %m-%
#' @import data.table
#'
#' @examples
#' library(data.table)
#'
#' make_triangles(claimvaluations, originLength = 3, rowDev = 3, colDev = 3)  # guess the financial columns

make_triangles <- function(claimvaluations, format="triangular", minLeftOrigin=NULL, originLength=12, rowDev=12, colDev=12,
                           lastValuationDate=NULL, fromMinLeftOrigin=TRUE, initialAge=originLength, colsFinancial="auto",
                           verbose=FALSE){
  # Method to build triangles from a cumulative transactions dataset (result of calling cumulate_transactions())
  # format can be one of {"tall", "triangular"}
  # If "tall", a single data.table is returned
  # If "triangular", a list of triangle objects is returned
  # colsFinancial should be a character vector corresponding to cumulative-valued columns of claimvaluations for which to
  # generate triangles (in addition to the guaranteed triangles {ActiveClaims, NewClaims, NewClaims.cmltv}). If "auto",
  # colsFinancial will look for numeric columns whose name ends in ".cmltv"

  if(is.null(minLeftOrigin)){
    minLeftOrigin <- as.Date(paste0(min(year(claimvaluations$ValuationDate)), "-1-1"))
    if(verbose) print(paste("minLeftOrigin automatically set to", minLeftOrigin))
  }

  if(is.null(lastValuationDate)){
    lastValuationDate <- max(claimvaluations$ValuationDate)
    if(verbose) print(paste("lastValuationDate automatically set to", lastValuationDate))
  }

  #======================================================================================================
  # triangle_skeleton()


  #======================================================================================================

  # Get colsFinancial
  if(colsFinancial == "auto"){
    numeric_cols <- colnames(claimvaluations)[sapply(claimvaluations, is.numeric)]
    colsFinancial <- setdiff(numeric_cols, c("ClaimID", "PolicyID"))
  }

  # Get the triangle skeletons
  if(verbose) print("Getting triangle skeletons")
  params <- triangle_skeleton(minLeftOrigin=minLeftOrigin, originLength=originLength, rowDev=rowDev, colDev=colDev,
                              lastValuationDate=lastValuationDate, fromMinLeftOrigin=fromMinLeftOrigin, initialAge=initialAge)

  # Build a vector of "FirstValuationDate"s for each claim corresponding to the claimvaluations dataset, but don't actually
  # insert this in the table
  firstvaldts <- claimvaluations[, list(.I, FirstValuationDate = min(ValuationDate)), by=ClaimID]$FirstValuationDate

  # Helper method to subset claims into a row and then partition claim-valuations in that row and aggregate them
  rowPartitionSums <- function(valDts, leftO, rightO){
    # For testing:
    # leftO <- params$LeftOrigin[1]; rightO <- params$RightOrigin[1]
    # valDts <- params[LeftOrigin==leftO & RightOrigin==rightO]$ValuationDate

    # Get the group of claims in the row of the triangle defined by leftO and rightO
    valDts <<- valDts
    leftO <<- leftO
    rightO <<- rightO
    claimvaluations.subset <- claimvaluations[between(firstvaldts, leftO, rightO)]

    # If there are no claims in this row, fill in the data as necessary
    if(nrow(claimvaluations.subset) == 0){

      # Build a table with the primary columns
      primary <- data.table(ValuationDate=valDts, ActiveClaims=0L, NewClaims=0L, NewClaims.cmltv=0L)

      if(length(colsFinancial) > 0){
        extra.cmltv <- claimvaluations.subset[, colsFinancial, with=FALSE]
        extra.cmltv <- extra.cmltv[, lapply(.SD, function(x) rep(ifelse(class(x) == "integer", 0L, 0), length(valDts)))]

        # Build a table with the extra non cumulative columns
        extra.nonCmltv <- copy(extra.cmltv)
        setnames(extra.nonCmltv, gsub("\\.cmltv","",colnames(extra.cmltv))) # remove .cmltv from the column names
        setnames(extra.nonCmltv, colsFinancial, paste0(colsFinancial, ".chg")) # append .chg to financial cols

        # Build a table with all the extra columns
        extra <- cbind(extra.cmltv, extra.nonCmltv)

        # Combine the primary and extra tables into one
        result <- cbind(primary, extra)

        # Set the column order of result
        setcolorder(result, c(colnames(primary), sort(colnames(extra))))

      } else{
        result <- primary

        # Set the column order of result
        setcolorder(result, colnames(primary))
      }

      return(result)
    }

    # Build a table to partition the data by ClaimID and ValuationDate
    partitioner <- CJ(ClaimID=unique(claimvaluations.subset$ClaimID), ValuationDate=valDts)

    # Add the Partition Numbers for each claim (used in calculating "active" claims)
    partitioner[, PNum:=seq_along(ValuationDate), by=ClaimID]

    # For each row in claimvaluations.subset get the nearest partition number via a backward rolling join from partitioner
    # to claimvaluations.subset
    setkey(partitioner, "ClaimID", "ValuationDate")
    setkey(claimvaluations.subset, "ClaimID", "ValuationDate")
    backwardjoin <- partitioner[claimvaluations.subset, roll=-Inf]

    # Partition the data via a forward rolling join from claimvaluations.subset to partitioner
    forwardjoin <- backwardjoin[partitioner, roll=TRUE]

    # Aggregate results
    expr <- "ActiveClaims=sum(PNum == i.PNum, na.rm=TRUE), NewClaims.cmltv=sum(!is.na(PNum))"
    if(length(colsFinancial) > 0)
      expr <- paste(expr, ",", paste0(colsFinancial, "=sum(", colsFinancial, ", na.rm=TRUE)", collapse=", "))
    expr <- paste("list(", expr, ")")
    result <- forwardjoin[, eval(parse(text=expr)), by=ValuationDate]

    # Build the non-cumulative columns
    nonCmltv <- result[, !c("ValuationDate", "ActiveClaims"), with=FALSE]
    nonCmltv <- nonCmltv[, lapply(.SD, function(x) c(x[1], tail(x,-1) - head(x,-1)))]
    setnames(nonCmltv, gsub("\\.cmltv","", colnames(nonCmltv))) # remove .cmltv from the column names
    if(length(colsFinancial) > 0) setnames(nonCmltv, colsFinancial, paste0(colsFinancial, ".chg")) # append .chg to financial cols

    # Join result and nonCmltv tables
    result <- cbind(result, nonCmltv)

    # Set the column order of result
    guaranteedCols <- c("ValuationDate", "ActiveClaims", "NewClaims", "NewClaims.cmltv")
    setcolorder(result, c(guaranteedCols, sort(setdiff(colnames(result), guaranteedCols))))

    return(result)
  }

  # For each (LeftOrigin, RightOrigin) pair, partition and aggregate the transactions by the ValuationDate column
  if(verbose) print("Building triangle data.table")
  triangleDT <- params[, c(rowPartitionSums(ValuationDate, LeftOrigin[1], RightOrigin[1]), Age=list(Age)),
                       by=list(LeftOrigin, RightOrigin)]

  # Change the column order so that Age comes after ValuationDate
  setcolorder(triangleDT, unique(c("LeftOrigin", "RightOrigin", "ValuationDate", "Age", colnames(triangleDT))))

  # If format == "triangular", return a list of triangle objects. Otherwise return triangleDT
  if(verbose) print("Building triangle list")
  if(format=="triangular") return(tall_to_triangular(triangleDT)) else return(triangleDT)
}
