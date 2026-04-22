# Scaled PCA factor extraction

Implements scaled principal component analysis (sPCA): predictors are
first standardized, then each standardized predictor is scaled by its
univariate predictive slope on the target, and finally principal
components are extracted from the scaled predictors.

## Usage

``` r
spca_est(target, X, nfac, winsorize = FALSE, winsor_probs = c(0, 99))
```

## Arguments

- target:

  A numeric vector of length `T_reg` (`T_reg <= T`).

- X:

  A numeric matrix or data frame with `T` rows and `N` columns. When
  `length(target) < nrow(X)`, the first `length(target)` rows of the
  standardized `X` are used for the scaling regression while all `T`
  rows are used for standardization and factor extraction. This matches
  the out-of-sample workflow in Huang et al. (2022), where the
  predictive regression `y_{t+1} ~ X_t` uses fewer rows than the full
  training window.

- nfac:

  A positive integer giving the number of factors to extract.

- winsorize:

  Logical; if `TRUE`, winsorize absolute slope estimates before scaling
  predictors.

- winsor_probs:

  Numeric vector of length 2 giving winsorization percentiles. Used only
  when `winsorize = TRUE`.

## Value

An object of class `"sdim_spca"` with components:

- factors:

  A `T x nfac` matrix of extracted sPCA factors.

- beta:

  A numeric vector of predictor-specific predictive slopes.

- beta_scaled:

  A numeric vector of scaling coefficients actually used.

- col_means:

  Column means of `X` (used by `predict`).

- col_sds:

  Column standard deviations of `X` (used by `predict`).

- Xs:

  The standardized predictor matrix.

- scaleXs:

  The scaled standardized predictor matrix.

- lambda:

  The estimated loading matrix.

- residuals:

  Residual matrix from the PCA reconstruction step.

- ve2:

  Average squared residual by row.

- eigvals:

  Singular values from the decomposition of `scaleXs %*% t(scaleXs)`.

- call:

  The matched function call.

## Details

The function follows the MATLAB implementation of Huang, Jiang, Li,
Tong, and Zhou (2022).

## References

Huang, Jiang, Li, Tong, Zhou (2022)
[doi:10.1287/mnsc.2021.4020](https://doi.org/10.1287/mnsc.2021.4020)

## Examples

``` r
set.seed(123)
X <- matrix(rnorm(200 * 10), nrow = 200, ncol = 10)
y <- rnorm(200)

fit <- spca_est(target = y, X = X, nfac = 3)
dim(fit$factors)
#> [1] 200   3
head(fit$beta)
#> [1]  0.0007544186  0.0307199352  0.0074016978 -0.0217043884  0.0892871951
#> [6]  0.0260282689

# Predictive alignment: target has fewer rows than X
fit2 <- spca_est(target = y[1:199], X = X, nfac = 3)
dim(fit2$factors)  # 200 x 3 (factors for all T rows)
#> [1] 200   3
```
