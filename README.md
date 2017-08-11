# claimz
Fast utility methods for insurance claims data using data.table

About
------
The goals of this package are

- Provide a framework for wrangling and analyzing claims data
- Provide methods for validating structure (e.g. every claim should be tied to a policy)

## Installation

You can install claimz from github with:

```R
# install.packages("devtools")
devtools::install_github("ben519/claimz")
```

Demonstration
------

#### Load packages
```r
library(claimz)
library(data.table)
library(lubridate)
```

#### Toy datasets included in the claimz package
```r
policiez
   PolicyID EffectiveDate ExpirationDate
1:        1    2014-01-01     2015-01-01
2:        2    2014-06-01     2015-06-01

claimz
   ClaimID PolicyID EffectiveDate ExpirationDate DateOfLoss ReportDate
1:       1        1    2014-01-01     2015-01-01 2014-03-15 2014-03-15
2:       2        1    2014-01-01     2015-01-01 2014-04-01 2015-07-11
3:       3        2    2014-06-01     2015-06-01 2015-05-30 2015-06-10

claimvaluationz
   ValuationDate ClaimID PolicyID EffectiveDate ExpirationDate DateOfLoss ReportDate Incurred Paid
1:    2015-01-01       1        1    2014-01-01     2015-01-01 2014-03-15 2014-03-15      100   50
2:    2015-01-01       2        1    2014-01-01     2015-01-01 2014-04-01 2015-07-11      150  100
3:    2016-01-01       1        1    2014-01-01     2015-01-01 2014-03-15 2014-03-15      125  125
4:    2016-01-01       2        1    2014-01-01     2015-01-01 2014-04-01 2015-07-11      230  230
5:    2016-01-01       3        2    2014-06-01     2015-06-01 2015-05-30 2015-06-10       75   75
```

#### Validate the data structure and relationships
```r
is_valid_datasets(policiez, claimz, claimvaluationz)  # No warnings 
is_valid_datasets(policiez, head(claimz, 2), claimvaluationz)  # 1 warning: "1 unique ClaimIDs in claimvaluations not in claims"
```

#### Claim Snapshots
We can run special queries of claim-valuations using the function `claims_at(...)`.  For example, we can get all claims valued as of 2015-06-30.
```r
claims_at(claimvaluationz, valuationDate = as.Date("2015-06-30"))
   ClaimID ValuationDate CHValuationDate
1:       1    2015-06-30      2015-01-01
2:       2    2015-06-30      2015-01-01
3:       3    2015-06-30            <NA>
```
Take a look at ClaimID = 1.  It has date of loss (DOL) = 2014-03-15, and subsequent claim valuation records on 2015-01-01 and 2016-01-01.  For this claim, claims_at(...) assumes that the value of the claim on 2015-06-30 was the same as its value on 2015-01-01 since this is the closest valuation date for Claim 1 prior to the desired valuation date.  The pair of columns (**ClaimID**, **CHValuationDate**) can be used to map each row in the result to the corresponding row from claimvaluations.

Now take a look at claim 3.  It has DOL = 2015-05-30, and one valuation record on 2016-01-01. So, as of 2015-06-30 the claim had occured, but the insurance company ws unaware of existence.  This is why it is returned with CHValuationDate = NA.

We can also query claims as of a particular **age**.  For example we can get all claims as of age = 10 months.
```r
claims_at(claimvaluationz, claimAge = 10)
   ClaimID ValuationDate CHValuationDate DateOfLoss
1:       1    2015-01-15      2015-01-01 2014-03-15
2:       2    2015-02-01      2015-01-01 2014-04-01
3:       3    2016-03-30      2016-01-01 2015-05-30
```
Here, **age** is measured in months since the DOL of the claim. For example, ClaimID = 1 occured on 2014-03-15. The claim is 10 months old as of 2015-01-15, so the value of the claim as of this date is returned.  Of course, claimvaluations does not contain a row for (ClaimID = 1, ValuationDate = 2015-01-15) so the most recent prior valuation point for the claim is assumed to be the value as of that date.

Sometimes this can be problematic.  For example, consider ClaimID = 3.  It is 10 months old as of 2016-03-30, but perhaps our data is only valid up through 2016-02-29. In this case, resulting row for (ClaimID = 3, ValuationDate = 2016-03-30) is invalid because it is immature. We can prevent this from happening by using the parameters `maxValuationDate = as.Date("2016-02-29")` and `dropImmatureValuations = TRUE` (which is TRUE by default).
```r
claims_at(claimvaluationz, claimAge = 10, maxValuationDate = as.Date("2016-02-29"), dropImmatureValuations = TRUE)
   ClaimID ValuationDate CHValuationDate DateOfLoss
1:       1    2015-01-15      2015-01-01 2014-03-15
2:       2    2015-02-01      2015-01-01 2014-04-01
```
(Note that Claim 3 is exluded from this result set).

We might also want to get the value of each claim when its corresponding policy is a certain age. For example
```r
claims_at(claimvaluationz, policyAge = 18)
   ClaimID ValuationDate CHValuationDate EffectiveDate
1:       1    2015-07-01      2015-01-01    2014-01-01
2:       2    2015-07-01      2015-01-01    2014-01-01
3:       3    2015-12-01            <NA>    2014-06-01
```
Looking at ClaimID = 2, its policy began on 2014-01-01, so the policy was 18 months old as of 2015-07-01. The result shows that it can be mapped back to the 2015-01-01 valuation point in **claimvaluationz** to infer the values of the claim when the policy was 18 months old.

#### Loss Triangles
The claimz package also makes it easy to generate loss triangles for analyzing changes in loss amounts over time. To start, we'll make use of the `simulate_losses()` method to generate a random set of claimvaluations.

```r
set.seed(0)
claimvalz <- simulate_losses(numLosses = 6, startDate = as.Date("2010-01-1"), endDate = as.Date("2012-12-31"))

claimvalz
    ClaimID DateOfLoss ReportDate  CloseDate ValuationDate     Paid
 1:       1 2010-11-14 2010-11-14 2010-11-14    2010-11-14  3840.15
 2:       2 2011-05-31 2011-05-31       <NA>    2011-09-15  3942.93
 3:       2 2011-05-31 2011-05-31       <NA>    2012-03-03  4993.45
 4:       2 2011-05-31 2011-05-31       <NA>    2012-05-09  5515.82
 5:       2 2011-05-31 2011-05-31       <NA>    2012-11-04  7510.48
 6:       3 2011-08-13 2011-08-13 2012-11-17    2011-11-05    95.52
 7:       3 2011-08-13 2011-08-13 2012-11-17    2011-12-16  4086.58
 8:       3 2011-08-13 2011-08-13 2012-11-17    2012-01-25  6526.67
 9:       3 2011-08-13 2011-08-13 2012-11-17    2012-02-12  6691.28
10:       3 2011-08-13 2011-08-13 2012-11-17    2012-02-26  6806.08
11:       3 2011-08-13 2011-08-13 2012-11-17    2012-04-22  6839.26
12:       3 2011-08-13 2011-08-13 2012-11-17    2012-05-28  6897.72
13:       3 2011-08-13 2011-08-13 2012-11-17    2012-07-04  9447.92
14:       3 2011-08-13 2011-08-13 2012-11-17    2012-08-31  9970.55
15:       3 2011-08-13 2011-08-13 2012-11-17    2012-09-03 10490.37
16:       3 2011-08-13 2011-08-13 2012-11-17    2012-10-08 10985.27
17:       3 2011-08-13 2011-08-13 2012-11-17    2012-11-17 11415.97
18:       4 2012-04-25 2012-04-25 2012-04-25    2012-04-25 11011.00
19:       5 2012-04-27 2012-04-27       <NA>    2012-07-24   844.10
20:       5 2012-04-27 2012-04-27       <NA>    2012-08-27  1289.29
21:       6 2012-10-10 2012-10-10       <NA>    2012-10-13  1143.53
```

The function `make_triangles()` has a host of parameters for customizing loss triangles.  For example, if we wanted to generate annual triangles, we could simply run `make_triangles(claimvalz, minLeftOrigin = as.Date("2010-01-01"), originLength = 12)`.  The result is a list of six triangles.

```r
make_triangles(claimvalz, minLeftOrigin = as.Date("2010-01-01"), originLength = 12)
$Occurred.cmltv
                         Age
Origin                    12 24
  2010-01-01 - 2010-12-31  1  1
  2011-01-01 - 2011-12-31  2 NA

$Occurred
                         Age
Origin                    12 24
  2010-01-01 - 2010-12-31  1  0
  2011-01-01 - 2011-12-31  2 NA

$Reported.cmltv
                         Age
Origin                    12 24
  2010-01-01 - 2010-12-31  1  1
  2011-01-01 - 2011-12-31  2 NA

$Reported
                         Age
Origin                    12 24
  2010-01-01 - 2010-12-31  1  0
  2011-01-01 - 2011-12-31  2 NA

$Paid
                         Age
Origin                          12      24
  2010-01-01 - 2010-12-31  3840.15 3840.15
  2011-01-01 - 2011-12-31 18926.45      NA

$Paid.chg
                         Age
Origin                          12 24
  2010-01-01 - 2010-12-31  3840.15  0
  2011-01-01 - 2011-12-31 18926.45 NA
```

Each row represents a distinct set of claims.  For example, the first row, *2010-01-01 - 2010-12-31*, represents claims that occurred between 2010-01-01 and 2010-12-31.  Looking at the *Reported* triangle, we see that 1 claim which occurred in the period was reported within 12 months of 2010-01-01.  Similarly, row 2 shows that 2 claim2 which occurred between 2011-01-01 and 2011-12-31 were each reported within 12 months of 2011-01-01.

#### Contact
If you'd like to contact me regarding bugs, questions, or general consulting, feel free to drop me a line - bgorman519@gmail.com
