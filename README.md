# sdim  <a href="https://github.com/GabboCg/sdim"><img src="man/figures/logo.png" align="right" height="138" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/GabboCg/sdim/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/GabboCg/sdim/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/GabboCg/sdim/actions/workflows/pkgdown.yaml/badge.svg)](https://gabbocg.github.io/sdim/)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

## Overview

**sdim** implements five factor extraction methods for asset pricing and macroeconomic forecasting:

| Function | Method | Reference |
|---|---|---|
| `pca_est()` | Principal Component Analysis (PCA) | He et al. (2023, MS) |
| `pls_est()` | Partial Least Squares (PLS) | He et al. (2023, MS) |
| `rra_est()` | Reduced-Rank Approach (RRA) | He et al. (2023, MS) |
| `spca_est()` | Scaled PCA (sPCA) | Huang et al. (2022, MS) |
| `ipca_est()` | Instrumented PCA (IPCA) | Kelly, Pruitt & Su (2019, JFE) |

PCA, PLS, and RRA take a multivariate target (T×N returns matrix) and a matrix of factor proxies. sPCA takes a univariate target and scales each proxy by its OLS slope on the target before extracting principal components. IPCA extracts latent factors from panel data using time-varying characteristics as instruments, estimated via alternating least squares (ALS). Performance of extracted factors can be evaluated with `eval_factors()`.

The package ships with seven `he2023_*` datasets (factor proxies and portfolio returns) from the He et al. (2023, MS) replication package.

## Installation

``` r
# Install from GitHub (not yet on CRAN)
# install.packages("pak")
pak::pak("GabboCg/sdim")
```

## Usage

### Quick start

``` r
library(sdim)

set.seed(42)
X   <- matrix(rnorm(200 * 20), 200, 20)   # T x L factor proxies
ret <- matrix(rnorm(200 * 30) / 100, 200, 30)  # T x N returns (target)

# Fit each method
fit_pca <- pca_est(target = ret, X = X, nfac = 3)
fit_pls <- pls_est(target = ret, X = X, nfac = 3)
fit_rra <- rra_est(target = ret, X = X, nfac = 3)

print(fit_rra)
#> <sdim_fit [rra]>
#>  Observations : 200
#>  Predictors   : 20
#>  Factors      : 3

# Evaluate factor quality (RMSPE and total adj-R² from He et al. 2023, §2.4)
eval_factors(ret = ret, factors = fit_rra$factors)
#> Factor Evaluation
#> ----------------------------------------
#>  Portfolios       30
#>  Factors           3
#>
#> Performance (He et al., 2023, §2.4)
#> ----------------------------------------
#>  RMSPE              0.9875  (%)
#>  Total adj-R²       2.9593  (%)
#>  SR                 0.0522
#>  A2R                0.9443
```

### IPCA (panel with time-varying characteristics)

``` r
# Simulate panel: T periods, N assets, L characteristics
set.seed(99)
T <- 120; N <- 50; L <- 6
ret <- matrix(rnorm(T * N) / 100, T, N)
Z   <- array(rnorm(T * N * L), dim = c(T, N, L))

fit_ipca <- ipca_est(ret, Z, nfac = 3)
print(fit_ipca)
#> <sdim_fit [ipca]>
#>  Observations    : 120
#>  Characteristics : 6
#>  Factors         : 3
#>  Factor mean     : zero

summary(fit_ipca)
#> Instrumented Principal Components Analysis (IPCA)
#> ----------------------------------------
#> Call: ipca_est(ret = ret, Z = Z, nfac = 3)
#>
#> Dimensions
#> ----------------------------------------
#>  Observations     120
#>  Characteristics  6
#>  Factors          3
#>  Factor mean      zero
#>
#> Eigenvalues
#> ----------------------------------------
#>                     F1      F2      F3
#> Eigenvalue      0.8952  0.9336  0.8652
#> Var. expl. (%) 33.2300 34.6600 32.1200

# With factor mean specifications
fit_const <- ipca_est(ret, Z, nfac = 3, factor_mean = "constant")
fit_const$mu   # time-series mean of each factor

fit_var <- ipca_est(ret, Z, nfac = 3, factor_mean = "VAR1")
fit_var$var_coef   # K x K VAR(1) coefficient matrix
```

### sPCA (univariate target)

``` r
y <- rnorm(200)   # univariate return series

fit_spca <- spca_est(target = y, X = X, nfac = 3)
summary(fit_spca)
#> Scaled PCA (sPCA)
#> ----------------------------------------
#> Call: spca_est(target = y, X = X, nfac = 3)
#>
#> Dimensions
#> ----------------------------------------
#>  Observations     200
#>  Predictors        20
#>  Factors            3
#>
#> Eigenvalues
#> ----------------------------------------
#>                      F1       F2       F3
#> Eigenvalue      12.3456   8.7654   5.4321
#> Var. expl. (%)   46.73    33.20    20.57
#>
#> OLS slope summary (beta)
#> ----------------------------------------
#>       0%      25%      50%      75%     100%
#> -0.1234  -0.0512   0.0103   0.0634   0.1521
```

## Getting help

If you encounter a bug, please file an issue with a minimal reproducible example on [GitHub](https://github.com/GabboCg/sdim/issues). For questions, email gabriel.cabreraguzman@postgrad.manchester.ac.uk.

## References

- He, J., Huang, J., Li, F., and Zhou, G. (2023). "Shrinking Factor Dimension: A Reduced-Rank Approach." *Management Science*, 69(9). [doi:10.1287/mnsc.2022.4563](https://doi.org/10.1287/mnsc.2022.4563)

- Huang, J., Jiang, J., Li, F., Tong, G., and Zhou, G. (2022). "Scaled PCA: A New Approach to Dimension Reduction." *Management Science*, 68(3). [doi:10.1287/mnsc.2021.4020](https://doi.org/10.1287/mnsc.2021.4020)

- Kelly, B. T., Pruitt, S., and Su, Y. (2019). "Characteristics are Covariances: A Unified Model of Risk and Return." *Journal of Financial Economics*, 134(3). [doi:10.1016/j.jfineco.2019.05.001](https://doi.org/10.1016/j.jfineco.2019.05.001)
