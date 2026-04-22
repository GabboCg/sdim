# Factor proxies from He, Huang, Li, Zhou (2023)

Monthly returns on 70 factor proxies from the replication package of He,
Huang, Li, Zhou (2023): the five Fama-French factors (MKT, SMB, HML,
RMW, CMA) plus 65 anomaly-based long-short portfolios. Used as factor
proxies (`X`) in the RRA, PLS, and PCA estimators.

## Usage

``` r
he2023_factors
```

## Format

A data.frame with 516 rows and 71 variables:

- date:

  First day of each month, class `Date`.

- MKT:

  Market excess return (percent).

- SMB:

  Small-minus-big size factor (percent).

- HML:

  High-minus-low value factor (percent).

- RMW:

  Robust-minus-weak profitability factor (percent).

- CMA:

  Conservative-minus-aggressive investment factor (percent).

- ...:

  65 additional anomaly-based long-short factors (percent).

## Source

He, Huang, Li, Zhou (2023) replication package,
<https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563>.

## Note

The sample period ends 2016-12-01, twelve months earlier than the
portfolio datasets (`he2023_ff48vw`, etc., which end 2017-12-01). Align
dates before passing `he2023_factors` as `X` and any portfolio dataset
as `target`.

## References

He, J., Huang, J., Li, F., and Zhou, G. (2023). Shrinking Factor
Dimension: A Reduced-Rank Approach. *Management Science*, 69(9).
[doi:10.1287/mnsc.2022.4563](https://doi.org/10.1287/mnsc.2022.4563)

## Examples

``` r
head(he2023_factors[, 1:5])
#>         date   MKT   SMB   HML   RMW
#> 1 1974-01-01 -0.17 10.51  5.87 -2.98
#> 2 1974-02-01 -0.48  0.16  2.54 -1.96
#> 3 1974-03-01 -2.81  2.61 -0.12  2.96
#> 4 1974-04-01 -5.29 -0.61  1.01  2.80
#> 5 1974-05-01 -4.67 -3.21 -2.07  5.04
#> 6 1974-06-01 -2.83  0.00  0.76  0.66
```
