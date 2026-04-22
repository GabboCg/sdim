# Estimate AR(p) model

Fits an autoregressive model of order `p` for the horizon-`h` target and
returns the OLS coefficients and residuals.

## Usage

``` r
estimate_ar_res(y, h, p)
```

## Arguments

- y:

  Numeric vector of the target variable.

- h:

  Positive integer; forecast horizon.

- p:

  Non-negative integer; AR lag order.

## Value

A list with components:

- a_hat:

  Coefficient vector (intercept first).

- res:

  Residual vector.

## Examples

``` r
y <- arima.sim(list(ar = 0.7), n = 200)
ar_fit <- estimate_ar_res(y, h = 1, p = 1)
ar_fit$a_hat
#>           [,1]
#> [1,] 0.1027578
#> [2,] 0.7011676
```
