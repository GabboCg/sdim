# Reduced-Rank Approach (RRA) factor extraction

Implements the two-step GMM estimator of He, Huang, Li, and Zhou (2023).
Factor proxies `X` are rotated to maximise explanatory power for the
target return matrix `target`, using diagonal GMM weighting matrices.

## Usage

``` r
rra_est(target, X, nfac, compute_stat = FALSE)
```

## Arguments

- target:

  Numeric matrix (T x N) of target variables (e.g., asset returns). A
  vector is coerced to a T x 1 matrix.

- X:

  Numeric matrix or data frame (T x L) of factor proxies.

- nfac:

  Positive integer; number of RRA factors to extract.

- compute_stat:

  Logical; if `TRUE`, compute the GMM J-test statistic for
  overidentifying restrictions. Returned as `NULL` when `FALSE`
  (default) or when degrees of freedom \<= 0.

## Value

An object of class `"sdim_fit"`.

## References

He, Huang, Li, Zhou (2023)
[doi:10.1287/mnsc.2022.4428](https://doi.org/10.1287/mnsc.2022.4428)

## Examples

``` r
set.seed(1)
X <- matrix(rnorm(100 * 8), 100, 8)
Y <- matrix(rnorm(100 * 5), 100, 5)
fit <- rra_est(target = Y, X = X, nfac = 3)
print(fit)
#> <sdim_fit [rra]>
#>  Observations : 100 
#>  Predictors   : 8 
#>  Factors      : 3 
```
