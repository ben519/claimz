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
set.seed(4)
claimvalz <- simulate_losses(numLosses = 10, startDate = as.Date("2010-01-1"), endDate = as.Date("2012-12-31"))

claimvalz
| ClaimID | DateOfLoss | ReportDate | CloseDate  | ValuationDate |   Paid   |
|:-------:|:----------:|:----------:|:----------:|:-------------:|:--------:|
|    1    | 2010-01-11 | 2010-01-11 |     NA     |  2010-01-18   |  857.71  |
|    1    | 2010-01-11 | 2010-01-11 |     NA     |  2010-07-09   |  967.22  |
|    1    | 2010-01-11 | 2010-01-11 |     NA     |  2010-08-07   | 1566.26  |
|    1    | 2010-01-11 | 2010-01-11 |     NA     |  2010-10-22   | 4276.51  |
|    1    | 2010-01-11 | 2010-01-11 |     NA     |  2011-05-07   | 5097.13  |
|   ...   |    ...     |    ...     |    ...     |      ...      |   ...    |
|    7    | 2012-03-05 | 2012-03-05 |     NA     |  2012-12-31   |  783.25  |
|    8    | 2012-09-21 | 2012-09-21 |     NA     |  2012-10-13   | 5291.33  |
|    8    | 2012-09-21 | 2012-09-21 |     NA     |  2012-10-21   | 6083.48  |
|    8    | 2012-09-21 | 2012-09-21 |     NA     |  2012-12-04   | 6114.92  |
|    9    | 2012-11-07 | 2012-11-07 | 2012-11-07 |  2012-11-07   | 29385.51 |
```

The function `make_triangles()` has a host of parameters for customizing loss triangles.  For example, if we wanted to generate annual triangles, we could simply run `make_triangles(claimvalz, minLeftOrigin = as.Date("2010-01-01"), originLength = 12)`.  The result is a list of six triangles.

```r
make_triangles(claimvalz, minLeftOrigin = as.Date("2010-01-01"), originLength = 12)
$Occurred.cmltv
                         Age
Origin                    12 24 36
  2010-01-01 - 2010-12-31  5  5  5
  2011-01-01 - 2011-12-31  1  1 NA
  2012-01-01 - 2012-12-31  3 NA NA

$Occurred
                         Age
Origin                    12 24 36
  2010-01-01 - 2010-12-31  5  0  0
  2011-01-01 - 2011-12-31  1  0 NA
  2012-01-01 - 2012-12-31  3 NA NA

$Reported.cmltv
                         Age
Origin                    12 24 36
  2010-01-01 - 2010-12-31  4  5  5
  2011-01-01 - 2011-12-31  1  1 NA
  2012-01-01 - 2012-12-31  3 NA NA

$Reported
                         Age
Origin                    12 24 36
  2010-01-01 - 2010-12-31  4  1  0
  2011-01-01 - 2011-12-31  1  0 NA
  2012-01-01 - 2012-12-31  3 NA NA

$Paid
                         Age
Origin                          12       24       36
  2010-01-01 - 2010-12-31 41751.49 49080.76 49080.76
  2011-01-01 - 2011-12-31  6189.03  6189.03       NA
  2012-01-01 - 2012-12-31 36283.68       NA       NA

$Paid.chg
                         Age
Origin                          12      24 36
  2010-01-01 - 2010-12-31 41751.49 7329.27  0
  2011-01-01 - 2011-12-31  6189.03    0.00 NA
  2012-01-01 - 2012-12-31 36283.68      NA NA
```

Each row represents a distinct set of claims.  For example, the first row, *2010-01-01 - 2010-12-31*, represents claims that occurred between 2010-01-01 and 2010-12-31.  Looking at the *Reported* triangle, we see that four claims which occurred in the period were reported within 12 months of 2010-01-01 and 1 other claim the occurred in the period was reported between 12 and 24 months.  Similarly, row two shows that one claim which occurred between 2011-01-01 and 2011-12-31 was reported within 12 months of 2011-01-01.

We could also look at quarterly or monthly triangles
```r
# quarterly
make_triangles(claimvalz, minLeftOrigin = as.Date("2010-01-01"), originLength = 3, rowDev = 3, colDev = 3)

# monthly
make_triangles(claimvalz, minLeftOrigin = as.Date("2010-01-01"), originLength = 1, rowDev = 1, colDev = 1)
```

There are **many** additional options within `make_triangles()` - too many to explain here so be sure to read the function documentation to learn all its capabilities.

#### Contact
If you'd like to contact me regarding bugs, questions, or general consulting, feel free to drop me a line - bgorman519@gmail.com
