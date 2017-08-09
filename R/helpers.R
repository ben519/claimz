# Helper functions
# Use @include tags to load these functions into other scripts
# See https://github.com/tidyverse/ggplot2/blob/master/R/utilities.r for an example of this

triangle_skeleton <- function(minLeftOrigin, fromMinLeftOrigin, originLength, rowDev, colDev, initialAge, lastValuationDate){
  # Returns a table of skeleton parameters that define a set of triangles

  # Input corrections
  minLeftOrigin <- rollback(minLeftOrigin) + 1  # Force minLeftOrigin to be a first-of-month
  lastValuationDate <- rollback((rollback(lastValuationDate) + 1) %m+% months(1))  # Force the lastValuationDate to be an end-of-month

  # Generate all leftOrigins
  if(fromMinLeftOrigin){
    leftOrigins <- seq(minLeftOrigin, (lastValuationDate + 1) %m-% months(initialAge), by=paste(rowDev, "months"))
  } else{
    leftOrigins <- rev(seq((lastValuationDate + 1) %m-% months(initialAge), minLeftOrigin, by=paste(-rowDev, "months")))
  }

  # Generate all rightOrigins
  rightOrigins <- leftOrigins %m+% months(originLength) - 1

  # Helper method to get all valuation dates given (rightOrigin, originLength, initialAge, lastValuationDate, colDev)
  getValDts <- function(rightOrigin, originLength, initialAge, lastValuationDate, colDev){
    seq((as.Date(rightOrigin) + 1) %m-% months(originLength-initialAge), lastValuationDate + 1, by=paste(colDev,"months")) - 1
  }

  skeleton <- data.table(LeftOrigin=leftOrigins, RightOrigin=rightOrigins, lastValuationDate=lastValuationDate, colDev=colDev, originLength=originLength, initialAge=initialAge)
  skeleton <- skeleton[, list(ValuationDate=getValDts(rightOrigin=RightOrigin, originLength=originLength, initialAge=initialAge, lastValuationDate=lastValuationDate, colDev=colDev)), keyby=list(LeftOrigin, RightOrigin)]
  skeleton[, Age := year(ValuationDate)*12 + month(ValuationDate)-(year(LeftOrigin)*12 + month(LeftOrigin)) + 1]
  setkey(skeleton, "LeftOrigin", "RightOrigin", "ValuationDate")

  return(skeleton[])
}

tall_to_triangular <- function(triangleDT){
  # Converts a set of triangles in the tall, data.table format to a list of triangular formats

  triCols <- colnames(triangleDT[, !c("LeftOrigin", "RightOrigin", "ValuationDate", "Age"), with=FALSE])

  mylist <- list()
  for(colname in triCols){
    mylist[[length(mylist)+1]] <- as.triangle(copy(triangleDT), valueCol=colname)
  }
  names(mylist) <- triCols
  return(mylist)
}

as.triangle <- function(triangleDT, valueCol="NewClaims"){
  # Convert a triangle from tall format to triangular format

  tri <- triangleDT[, c("LeftOrigin", "RightOrigin", "Age", valueCol), with=FALSE]
  tri[, Origin := paste0(LeftOrigin, " - ", RightOrigin)]
  tri <- dcast.data.table(tri, Origin ~ Age, value.var=valueCol, drop=FALSE)
  result <- as.matrix(tri[, 2:ncol(tri), with=FALSE])
  dimnames(result) <- list(Origin=tri$Origin, Age=colnames(tri)[2:ncol(tri)])
  return(result)
}
