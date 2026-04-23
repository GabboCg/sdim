# IPCA factor extraction

IPCA factor extraction

## Usage

``` r
ipca_est(ret, Z, nfac, max_iter = 100, tol = 1e-06, factor_mean = "zero")
```

## Arguments

- ret:

  Numeric matrix (T x N) of asset returns. Use `NA` for missing
  observations (unbalanced panel).

- Z:

  Numeric array (T x N x L) of asset characteristics. `NA`s must mirror
  `ret` exactly.

- nfac:

  Positive integer; number of latent factors K to extract.

- max_iter:

  Maximum ALS iterations (default 100).

- tol:

  Convergence tolerance on Frobenius norm of loading change (default
  1e-6).

- factor_mean:

  Character scalar specifying how the factor mean is modelled. One of
  `"zero"` (default, no mean adjustment), `"constant"` (time-series
  average), or `"VAR1"` (VAR(1) with intercept).

## Value

An object of class `"sdim_fit"` with fields: `factors` (T x K), `lambda`
(L x K characteristic loadings, i.e. Gamma in Kelly et al.), `eigvals`
(factor variances), `factor_mean` (character scalar), `call`,
`method = "ipca"`, `nfac`. If `factor_mean = "constant"`: also `mu`
(length-K mean vector). If `factor_mean = "VAR1"`: also `var_coef` (K x
K), `var_intercept` (length-K), `var_resid` ((T-1) x K).

## References

Kelly, B. T., Pruitt, S., and Su, Y. (2019). Characteristics are
Covariances: A Unified Model of Risk and Return. *Journal of Financial
Economics*, 134(3), 501–524.
[doi:10.1016/j.jfineco.2019.05.001](https://doi.org/10.1016/j.jfineco.2019.05.001)

## Examples

``` r
set.seed(1)
ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
fit <- ipca_est(ret, Z, nfac = 2)
print(fit)
#> <sdim_fit [ipca]>
#>  Observations    : 50 
#>  Characteristics : 4 
#>  Factors         : 2 
#>  Factor mean     : zero 
```
