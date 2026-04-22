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

  A numeric vector of length \`T\`.

- X:

  A numeric matrix or data frame with \`T\` rows and \`N\` columns.

- nfac:

  A positive integer giving the number of factors to extract.

- winsorize:

  Logical; if \`TRUE\`, winsorize absolute slope estimates before
  scaling predictors.

- winsor_probs:

  Numeric vector of length 2 giving winsorization percentiles. Used only
  when \`winsorize = TRUE\`.

## Value

## Details

The function follows the MATLAB implementation supplied by the user,
with package-style input checking and a structured return object.

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
```
