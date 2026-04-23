# Grunfeld (1958) investment dataset

Panel data on gross investment for 11 US firms over 20 years
(1935–1954), originally from Grunfeld (1958). This is a classic panel
dataset used for validating the IPCA estimator against the Python `ipca`
package (Kelly, Pruitt, Su, 2019).

## Usage

``` r
grunfeld
```

## Format

A data.frame with 220 rows and 5 variables:

- firm:

  Character; firm name (11 unique firms).

- year:

  Integer; year of observation (1935–1954).

- invest:

  Numeric; gross investment (millions of dollars).

- value:

  Numeric; market value of the firm (millions of dollars).

- capital:

  Numeric; stock of plant and equipment (millions of dollars).

## Source

Grunfeld, Y. (1958). The Determinants of Corporate Investment. Ph.D.
thesis, Department of Economics, University of Chicago. Loaded from the
`statsmodels` Python package (`statsmodels.datasets.grunfeld`).

## References

Kelly, B. T., Pruitt, S., and Su, Y. (2019). Characteristics are
Covariances: A Unified Model of Risk and Return. *Journal of Financial
Economics*, 134(3), 501–524.
[doi:10.1016/j.jfineco.2019.05.001](https://doi.org/10.1016/j.jfineco.2019.05.001)

## Examples

``` r
head(grunfeld)
#>             firm year invest   value capital
#> 1 American Steel 1935  2.938  30.284  52.011
#> 2 American Steel 1936  5.643  43.909  52.903
#> 3 American Steel 1937 10.233 107.020  54.499
#> 4 American Steel 1938  4.046  68.306  59.722
#> 5 American Steel 1939  3.326  84.164  61.659
#> 6 American Steel 1940  4.680  69.157  62.243

# Reshape for ipca_est(): T x N matrix and T x N x L array
firms <- sort(unique(grunfeld$firm))
years <- sort(unique(grunfeld$year))
N <- length(firms)
TT <- length(years)

ret <- matrix(NA, TT, N)
Z   <- array(NA, dim = c(TT, N, 2))
for (i in seq_along(firms)) {
  idx <- grunfeld$firm == firms[i]
  ret[, i]  <- grunfeld$invest[idx]
  Z[, i, 1] <- grunfeld$value[idx]
  Z[, i, 2] <- grunfeld$capital[idx]
}

fit <- ipca_est(ret, Z, nfac = 1)
print(fit)
#> <sdim_fit [ipca]>
#>  Observations    : 20 
#>  Characteristics : 2 
#>  Factors         : 1 
#>  Factor mean     : zero 
```
