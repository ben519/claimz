#' @title
#' Simulate Losses
#'
#' @description
#' Simulate a collection of claims and their Paid amounts over time
#'
#' @details
#' Returns a data.table with {ClaimID, ValuationDate, Paid, ...}.
#'
#' @param numLosses number of losses to simulate
#' @param startDate first date for which a loss can occur
#' @param endDate last date for which a loss can occur
#' @param cutoffDate last date for which a payment can occur
#'
#' @import data.table
#'
#' @export
#' @examples
#' library(data.table)
#'
#' set.seed(2017)
#' losses <- simulate_losses(numLosses = 500, startDate = as.Date("2010-01-01"), endDate = as.Date("2016-12-31"))
#' losses  # view losses
#'
#' make_triangles(losses)

simulate_losses <- function(numLosses = 500, startDate = as.Date("2010-01-01"), endDate = as.Date("2016-12-31"), cutoffDate = endDate){
  # Simulate payments for a set of random claims belonging to an exposure
  # Returns a data.table with columns {ClaimID, PaymentDate, Payment, ...}

  # Build the claims
  claims <- data.table(ClaimID = seq_len(numLosses))
  claims[, DOL := startDate + sample(as.integer(endDate - startDate) + 1L, size = numLosses, replace = T)]
  claims[, ReportDate := DOL + pmax(0, round(rnorm(n = .N, mean = -100, sd = 100)))]
  claims[, UltimateValue := rlnorm(n = .N, meanlog = 9, sdlog = 1)]
  claims[, CloseDate := ReportDate + round(pmax(0, round(30 * rnorm(n = 1, mean = 10*log(UltimateValue) - 60, sd = 4 * log(UltimateValue))))), by=ClaimID]
  claims[, Payments := 1L + pmax(0, round(rnorm(n = 1, mean = -3 + (CloseDate - ReportDate)/90, sd = 5))), by=ClaimID]

  # Build the payments
  payments <- claims[, list(
    Payment = abs(rnorm(n = Payments)),
    Time = abs(rnorm(n = Payments))
  ), by=list(ClaimID, DOL, ReportDate, CloseDate, UltimateValue)]
  payments[, `:=`(
    PaymentPct = Payment/sum(Payment),
    TimePct = cumsum(Time)/sum(Time),
    OpenDays = as.integer(CloseDate - ReportDate)
  ), by=ClaimID]
  payments[, `:=`(PaymentDate = ReportDate + round(TimePct * OpenDays), Payment = round(UltimateValue * PaymentPct, 2))]
  payments <- payments[, list(Payment = sum(Payment)), keyby=list(ClaimID, PaymentDate)]

  # Convert to claim valuations
  payments[, Paid := cumsum(Payment), by=ClaimID]
  setnames(payments, "PaymentDate", "ValuationDate")
  payments[, c("Payment") := NULL]

  # Exclude stuff after endDate
  payments <- payments[ValuationDate <= endDate]

  # Insert claim fields into payments
  payments[claims, `:=`(DateOfLoss = i.DOL, ReportDate = i.ReportDate, CloseDate = i.CloseDate), on="ClaimID"]

  # Cleanup
  newids <- payments[, list(1), keyby=list(DateOfLoss, OldClaimID = ClaimID)]
  newids[, NewClaimID := .I]
  payments[newids, ClaimID := i.NewClaimID, on=c("ClaimID"="OldClaimID")]
  payments <- payments[order(ClaimID, ValuationDate)]

  # Apply cutoff
  payments <- payments[ValuationDate <= cutoffDate]
  payments[CloseDate > cutoffDate, CloseDate := NA]

  setcolorder(payments, c("ClaimID", "DateOfLoss", "ReportDate", "CloseDate", "ValuationDate", "Paid"))

  return(payments[])
}
