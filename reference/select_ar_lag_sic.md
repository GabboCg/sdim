# Select AR lag order by SIC (BIC)

Selects the lag order for an autoregressive model of the horizon-`h`
target \\y\_{t,h}\\ by minimising the Schwarz Information Criterion.

## Usage

``` r
select_ar_lag_sic(y, h, p_max)
```

## Arguments

- y:

  Numeric vector of the target variable.

- h:

  Positive integer; forecast horizon. For `h = 1` the target is simply
  `y`.

- p_max:

  Maximum lag order to consider. The function evaluates
  `p = 0, 1, ..., p_max`.

## Value

Integer: selected lag order. A value of 0 means the intercept-only model
is preferred.

## Examples

``` r
y <- rnorm(200)
select_ar_lag_sic(y, h = 1, p_max = 4)
#> [1] 1
```
