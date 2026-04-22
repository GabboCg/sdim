# Dacheng 202-portfolio value-weighted returns from He, Huang, Li, Zhou (2023)

Monthly value-weighted returns on 202 portfolios (from Dacheng Xiu's
replication data) from the replication package of He, Huang, Li, Zhou
(2023). Used as the target return matrix (`target`) in the RRA, PLS, and
PCA estimators. Columns are named sequentially `p001`–`p202`.

## Usage

``` r
he2023_dacheng202
```

## Format

A data.frame with 552 rows and 203 variables:

- date:

  First day of each month, class `Date`.

- p001:

  Portfolio 1 return (percent).

- p002:

  Portfolio 2 return (percent).

- ...:

  Portfolios p003 through p202 (percent).

## Source

He, Huang, Li, Zhou (2023) replication package,
<https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4428>.

## References

He, J., Huang, J., Li, F., and Zhou, G. (2023). Shrinking Factor
Dimension: A Reduced-Rank Approach. *Management Science*, 69(9).
[doi:10.1287/mnsc.2022.4428](https://doi.org/10.1287/mnsc.2022.4428)

## Examples

``` r
head(he2023_dacheng202[, 1:5])
#>         date    p001    p002    p003    p004
#> 1 1972-01-01 13.2243 13.3839 11.9412 10.7825
#> 2 1972-02-01  3.0288  5.4772  4.1469  4.2322
#> 3 1972-03-01  2.9574  0.1033 -1.7722 -1.6814
#> 4 1972-04-01 -1.2312  0.1863 -0.9854  1.2499
#> 5 1972-05-01 -1.5740 -1.9020 -4.1156 -2.2708
#> 6 1972-06-01 -4.2146 -4.6749 -3.0230 -3.3495
```
