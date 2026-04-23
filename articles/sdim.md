# Get started with sdim

## Overview

**sdim** implements five factor extraction methods for asset pricing and
macroeconomic forecasting:

| Function                                                             | Method                             | Reference                      |
|----------------------------------------------------------------------|------------------------------------|--------------------------------|
| [`pca_est()`](https://gabbocg.github.io/sdim/reference/pca_est.md)   | Principal Component Analysis (PCA) | He et al. (2023, MS)           |
| [`pls_est()`](https://gabbocg.github.io/sdim/reference/pls_est.md)   | Partial Least Squares (PLS)        | He et al. (2023, MS)           |
| [`rra_est()`](https://gabbocg.github.io/sdim/reference/rra_est.md)   | Reduced-Rank Approach (RRA)        | He et al. (2023, MS)           |
| [`spca_est()`](https://gabbocg.github.io/sdim/reference/spca_est.md) | Scaled PCA (sPCA)                  | Huang et al. (2022, MS)        |
| [`ipca_est()`](https://gabbocg.github.io/sdim/reference/ipca_est.md) | Instrumented PCA (IPCA)            | Kelly, Pruitt & Su (2019, JFE) |

All estimators return S3 objects with
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`predict()`](https://rdrr.io/r/stats/predict.html) methods.

## Quick start

``` r
library(sdim)

set.seed(42)
X   <- matrix(rnorm(200 * 20), 200, 20)
ret <- matrix(rnorm(200 * 30) / 100, 200, 30)
```

### PCA, PLS, and RRA

These methods take a multivariate target (T × N returns) and a matrix of
factor proxies (T × L):

``` r
fit_pca <- pca_est(target = ret, X = X, nfac = 3)
fit_pls <- pls_est(target = ret, X = X, nfac = 3)
fit_rra <- rra_est(target = ret, X = X, nfac = 3)

print(fit_rra)
#> <sdim_fit [rra]>
#>  Observations : 200 
#>  Predictors   : 20 
#>  Factors      : 3
```

### Scaled PCA

sPCA takes a univariate target and scales each predictor by its OLS
slope on the target before extracting principal components. When
`length(target) < nrow(X)`, the first `length(target)` rows are used for
the scaling regression while all rows are used for factor extraction —
this supports the predictive alignment needed in out-of-sample
forecasting.

``` r
y <- rnorm(200)

fit_spca <- spca_est(target = y, X = X, nfac = 3)
print(fit_spca)
#> <sdim_spca>
#>  Observations : 200 
#>  Predictors   : 20 
#>  Factors      : 3
```

### IPCA

IPCA extracts latent factors from panel data using time-varying
characteristics as instruments:

``` r
TT <- 120 
K <- 50
n_chars <- 6
ret_panel <- matrix(rnorm(TT * K) / 100, TT, K)
Z <- array(rnorm(TT * K * n_chars), dim = c(TT, K, n_chars))

fit_ipca <- ipca_est(ret_panel, Z, nfac = 3)
#> Warning in ipca_als_cpp(ret_list, z_list, K = nfac, max_iter = max_iter, :
#> ipca_est: ALS did not converge in 100 iterations
print(fit_ipca)
#> <sdim_fit [ipca]>
#>  Observations    : 120 
#>  Characteristics : 6 
#>  Factors         : 3 
#>  Factor mean     : zero
```

## Prediction

Use [`predict()`](https://rdrr.io/r/stats/predict.html) to project new
data onto the estimated factor loadings:

``` r
X_new <- matrix(rnorm(5 * 20), 5, 20)

# PCA projection
F_new <- predict(fit_pca, X_new)
dim(F_new)
#> [1] 5 3

# sPCA projection (standardizes newdata using training parameters)
F_spca_new <- predict(fit_spca, X_new)
dim(F_spca_new)
#> [1] 5 3
```

## Factor evaluation

Evaluate extracted factors using the metrics from He et al. (2023,
§2.4):

``` r
eval_factors(ret = ret, factors = fit_rra$factors)
#> Factor Evaluation
#> ---------------------------------------- 
#>  Portfolios       30
#>  Factors          3
#> 
#> Performance (He et al., 2023, §2.4)
#> ---------------------------------------- 
#>  RMSPE              0.9875  (%)
#>  Total adj-R²       2.9593  (%)
#>  SR                 0.0522
#>  A2R                0.9443
```

## Bundled datasets

The package ships with datasets for replication:

- **`grunfeld`**: Grunfeld (1958) investment panel (11 firms, 20 years)
  — used for IPCA validation.
- **`he2023_*`**: Seven datasets from He et al. (2023) — factor proxies
  and portfolio returns.
- **`huang2022_macro`**: 720 × 123 matrix of transformed FRED-MD
  predictors from Huang et al. (2022).
- **`huang2022_ip`**: IP growth target for the Huang et al. (2022)
  out-of-sample exercise.

See
[`vignette("ipca-grunfeld")`](https://gabbocg.github.io/sdim/articles/ipca-grunfeld.md),
[`vignette("he2023-table3")`](https://gabbocg.github.io/sdim/articles/he2023-table3.md),
and
[`vignette("huang2022-table4")`](https://gabbocg.github.io/sdim/articles/huang2022-table4.md)
for full examples.
