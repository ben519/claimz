% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clean_claimvaluations.R
\name{clean_claimvaluations}
\alias{clean_claimvaluations}
\title{Clean claim-valuations}
\usage{
clean_claimvaluations(claimvaluations, colmap = NULL)
}
\arguments{
\item{claimvaluations}{data.table object}

\item{colmap}{a mapping of column names in the form of a named character vector, or NULL}
}
\description{
Adjust the column names of a data.table of claimvaluations so that the resulting column names match the required names for
claimz functions.
}
\details{
Returns a data.table object, a copy of claimvaluations with required column names.
}
\examples{
library(data.table)

# Sample claim valuations
claimvaluationz
claimvaluations <- copy(claimvaluationz)
setnames(claimvaluations, c("ClaimID"), c("claim_id"))
colmap <- c(
  "ClaimID"="claim_id",
  "PolicyID"="PolicyID",
  "EffectiveDate"="EffectiveDate",
  "ExpirationDate"="ExpirationDate",
  "DateOfLoss"="DateOfLoss",
  "ReportDate"="ReportDate"
)
clean_claimvaluations(claimvaluations, colmap)
}
