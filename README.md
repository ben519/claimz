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

#### Datasets
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
   ClaimValuationID ClaimID PolicyID EffectiveDate ExpirationDate        DOL ValuationDate Incurred
1:                1       1        1    2014-01-01     2015-01-01 2014-03-15    2015-01-01      100
2:                2       2        1    2014-01-01     2015-01-01 2014-04-01    2015-01-01      150
3:                3       1        1    2014-01-01     2015-01-01 2014-03-15    2016-01-01      125
4:                4       2        1    2014-01-01     2015-01-01 2014-04-01    2016-01-01      230
5:                5       3        2    2014-06-01     2015-06-01 2015-05-30    2016-01-01       75
```

#### Validate the data structure and relationships
```r
check_datasets(policiez, claimz, claimvaluationz)  # No warnings 
check_datasets(policiez, head(claimz, 2), claimvaluationz)  # 1 warning: "1 unique ClaimIDs in claimvaluations not in claims"
```

#### Snapshots by date/age
```r
claims_at(claimvaluationz, valuationDate=as.Date("2015-6-30"))
   ClaimValuationID ClaimID ValuationDate CHValuationDate
1:                1       1    2015-06-30      2015-01-01
2:                2       2    2015-06-30      2015-01-01
3:               NA       3    2015-06-30            <NA>

claims_at(claimvaluationz, claimAge=12)
   ClaimValuationID ClaimID ValuationDate CHValuationDate        DOL
1:                1       1    2015-03-15      2015-01-01 2014-03-15
2:                2       2    2015-04-01      2015-01-01 2014-04-01
3:                5       3    2016-05-30      2016-01-01 2015-05-30
```

#### Contact
If you'd like to contact me regarding bugs, questions, or general consulting, feel free to drop me a line - bgorman519@gmail.com
