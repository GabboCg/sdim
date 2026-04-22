# Estimate ARDL(p1, p2) model

Fits an autoregressive distributed lag model for the horizon-`h` target,
with `p1` lags of `y` and `p2` lags of additional regressors `z` (e.g.,
extracted factors).

## Usage

``` r
estimate_ardl_multi(y, z, h, p)
```

## Arguments

- y:

  Numeric vector of the target variable.

- z:

  Numeric matrix of additional regressors (e.g., factor estimates).

- h:

  Positive integer; forecast horizon.

- p:

  Integer vector of length 2: `c(p1, p2)` where `p1` is the number of AR
  lags and `p2` the number of `z` lags.

## Value

Coefficient vector (intercept, AR lags, then z lags).

## Examples

``` r
y <- rnorm(200)
z <- matrix(rnorm(200 * 3), 200, 3)
coefs <- estimate_ardl_multi(y, z, h = 1, p = c(1, 1))
coefs
#>             [,1]
#> [1,]  0.09589635
#> [2,] -0.09184243
#> [3,] -0.03458890
#> [4,]  0.07320798
#> [5,]  0.13344224
```
