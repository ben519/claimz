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
   ClaimID PolicyID EffectiveDate ExpirationDate        DOL
1:       1        1    2014-01-01     2015-01-01 2014-03-15
2:       2        1    2014-01-01     2015-01-01 2014-04-01
3:       3        2    2014-06-01     2015-06-01 2015-05-30

claimvaluationz
   ValuationDate ClaimID PolicyID EffectiveDate ExpirationDate        DOL Incurred
1:    2015-01-01       1        1    2014-01-01     2015-01-01 2014-03-15      100
2:    2015-01-01       2        1    2014-01-01     2015-01-01 2014-04-01      150
3:    2016-01-01       1        1    2014-01-01     2015-01-01 2014-03-15      125
4:    2016-01-01       2        1    2014-01-01     2015-01-01 2014-04-01      230
5:    2016-01-01       3        2    2014-06-01     2015-06-01 2015-05-30       75
```

#### Validate the data structure and relationships
```r
is_valid_datasets(policiez, claimz, claimvaluationz)  # No warnings 
check_datasets(policiez, head(claimz, 2), claimvaluationz)  # 1 warning: "1 unique ClaimIDs in claimvaluations not in claims"
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
   ClaimID ValuationDate CHValuationDate        DOL
1:       1    2015-01-15      2015-01-01 2014-03-15
2:       2    2015-02-01      2015-01-01 2014-04-01
3:       3    2016-03-30      2016-01-01 2015-05-30
```
Here, **age** is measured in months since the DOL of the claim. For example, ClaimID = 1 occured on 2014-03-15. The claim is 10 months old as of 2015-01-15, so the value of the claim as of this date is returned.  Of course, claimvaluations does not contain a row for (ClaimID = 1, ValuationDate = 2015-01-15) so the most recent prior valuation point for the claim is assumed to be the value as of that date.

Sometimes this can be problematic.  For example, consider ClaimID = 3.  It is 10 months old as of 2016-03-30, but perhaps our data is only valid up through 2016-02-29. In this case, resulting row for (ClaimID = 3, ValuationDate = 2016-03-30) is invalid because it is immature. We can prevent this from happening by using the parameters `maxValuationDate = as.Date("2016-02-29")` and `dropImmatureValuations = TRUE` (which is TRUE by default).
```r
claims_at(claimvaluationz, claimAge = 10, maxValuationDate = as.Date("2016-02-29"), dropImmatureValuations = TRUE)
   ClaimID ValuationDate CHValuationDate        DOL
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

#### Contact
If you'd like to contact me regarding bugs, questions, or general consulting, feel free to drop me a line - bgorman519@gmail.com
