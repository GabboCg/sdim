## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(sdim)

set.seed(42)
X   <- matrix(rnorm(200 * 20), 200, 20)
ret <- matrix(rnorm(200 * 30) / 100, 200, 30)

## -----------------------------------------------------------------------------
fit_pca <- pca_est(target = ret, X = X, nfac = 3)
fit_pls <- pls_est(target = ret, X = X, nfac = 3)
fit_rra <- rra_est(target = ret, X = X, nfac = 3)

print(fit_rra)

## -----------------------------------------------------------------------------
y <- rnorm(200)

fit_spca <- spca_est(target = y, X = X, nfac = 3)
print(fit_spca)

## -----------------------------------------------------------------------------
TT <- 120 
K <- 50
n_chars <- 6
ret_panel <- matrix(rnorm(TT * K) / 100, TT, K)
Z <- array(rnorm(TT * K * n_chars), dim = c(TT, K, n_chars))

fit_ipca <- ipca_est(ret_panel, Z, nfac = 3)
print(fit_ipca)

## -----------------------------------------------------------------------------
X_new <- matrix(rnorm(5 * 20), 5, 20)

# PCA projection
F_new <- predict(fit_pca, X_new)
dim(F_new)

# sPCA projection (standardizes newdata using training parameters)
F_spca_new <- predict(fit_spca, X_new)
dim(F_spca_new)

## -----------------------------------------------------------------------------
eval_factors(ret = ret, factors = fit_rra$factors)

