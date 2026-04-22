# Evaluate extracted factors against target returns

Computes the two performance measures from He, Huang, Li, Zhou (2023),
Section 2.4: Total adj-\\R^2\\ (Equation 19) and root-mean-squared
pricing error (RMSPE, Equation 20).

## Usage

``` r
eval_factors(ret, factors)
```

## Arguments

- ret:

  Numeric matrix or data frame (T x N) of excess returns for the target
  portfolios.

- factors:

  Numeric matrix (T x K) of extracted factors, e.g. `fit$factors` from
  [`pca_est`](https://gabbocg.github.io/sdim/reference/pca_est.md),
  [`pls_est`](https://gabbocg.github.io/sdim/reference/pls_est.md), or
  [`rra_est`](https://gabbocg.github.io/sdim/reference/rra_est.md).

## Value

A named numeric vector with four elements:

- RMSPE:

  Root-mean-squared pricing error (percent). Average over assets of the
  per-asset RMSE of \\R\_{it} - \hat\beta_i' f_t\\ (intercept excluded
  from the fitted value), as in Equation 20. Multiplied by 100 when
  `ret` is in decimal units.

- TotalR2:

  Total adjusted \\R^2\\ (percent), as in Equation 19.

- SR:

  Mean absolute alpha-to-residual-volatility ratio (Sharpe ratio of
  pricing errors).

- A2R:

  Mean absolute alpha-to-mean-return ratio.

## References

He, J., Huang, J., Li, F., and Zhou, G. (2023). Shrinking Factor
Dimension: A Reduced-Rank Approach. *Management Science*, 69(9).
[doi:10.1287/mnsc.2022.4428](https://doi.org/10.1287/mnsc.2022.4428)

## Examples

``` r
set.seed(1)
ret <- matrix(rnorm(100 * 10) / 100, 100, 10)
X   <- matrix(rnorm(100 * 8), 100, 8)
fit <- pca_est(X = X, nfac = 3)
eval_factors(ret = ret, factors = fit$factors)
#> Factor Evaluation
#> ---------------------------------------- 
#>  Portfolios       10
#>  Factors          3
#> 
#> Performance (He et al., 2023, §2.4)
#> ---------------------------------------- 
#>  RMSPE              1.0123  (%)
#>  Total adj-R²       1.4927  (%)
#>  SR                 0.0708
#>  A2R               19.0977
```
