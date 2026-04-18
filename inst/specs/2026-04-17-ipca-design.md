# IPCA Addition to sdim — Design Spec

**Date:** 2026-04-17
**Status:** Approved

## Overview

Add Instrumented Principal Components Analysis (IPCA; Kelly, Pruitt & Su, 2019, JFE) to the `sdim` R package as a native R + Rcpp implementation. IPCA models expected returns and risk exposures as linear functions of observed asset characteristics, estimating latent factors and characteristic loadings jointly via alternating least squares (ALS).

## Reference

Kelly, B., Pruitt, S., & Su, Y. (2019). Characteristics are covariances: A unified model of risk and return. *Journal of Financial Economics*, 134(3), 501–524.

## Files

### New
- `R/ipca_est.R` — main R function with roxygen documentation
- `src/ipca_als.cpp` — Rcpp/RcppArmadillo ALS inner loop
- `tests/testthat/test-ipca_est.R` — unit tests

### Modified
- `DESCRIPTION` — add `LinkingTo: Rcpp, RcppArmadillo` and `Imports: Rcpp`
- `NAMESPACE` — add `useDynLib` and `importFrom(Rcpp, sourceRcpp)`
- `R/sdim_fit.R` — add `"ipca"` branch in `print.sdim_fit` and `summary.sdim_fit`

## R API

```r
ipca_est(ret, Z, nfac, max_iter = 100, tol = 1e-6)
```

**Arguments:**
- `ret`: `T × N` numeric matrix of asset returns. `NA` indicates a missing observation (unbalanced panel).
- `Z`: `T × N × L` numeric array of asset characteristics. `NA`s must mirror `ret`.
- `nfac`: integer `K`, number of latent factors to extract.
- `max_iter`: maximum ALS iterations (default 100).
- `tol`: convergence tolerance on Frobenius norm of `Γ` change (default 1e-6).

**Returns:** an `sdim_fit` object of class `"ipca"`:

```r
list(
  method  = "ipca",
  factors = F,      # T × K numeric matrix — latent factor realizations
  Gamma   = Gamma,  # L × K numeric matrix — characteristic loadings
  nobs    = T,      # number of time periods
  npred   = L,      # number of characteristics
  nfac    = K       # number of factors
)
```

The `factors` field has the same name and shape as all other `sdim` methods, so `eval_factors()` requires no changes.

## Algorithm

### Model

```
r_{i,t} = z_{i,t}' Γ f_t + ε_{i,t}
```

where `z_{i,t}` is the `L`-vector of characteristics for asset `i` at time `t`, `Γ` is the `L × K` loading matrix, and `f_t` is the `K`-vector of latent factors.

### Data Preparation (R layer)

For each time period `t`, extract observed (non-NA) asset indices and build:
- `ret_list`: list of `T` vectors, each of length `N_t` (observed assets)
- `Z_list`: list of `T` matrices, each `N_t × L`

Pass both lists to the Rcpp function.

### ALS Loop (Rcpp/RcppArmadillo)

1. **Initialize** `Γ` (`L × K`) via SVD of the stacked `Z'r` matrix across all `t`
2. **Repeat until convergence:**
   - **Factor step:** for each `t`, solve `f_t = (Γ'Z_t'Z_tΓ)^{-1} Γ'Z_t'r_t` — a `K × K` system
   - **Loading step:** pool across all `t`: `Γ = (Σ_t Z_t'f_t f_t'Z_t)^{-1} (Σ_t Z_t'r_t f_t')`
   - **Normalize:** identify `Γ` via SVD (sign and scale normalization)
   - **Check:** `||Γ_new - Γ_old||_F < tol`
3. **Return** `Γ` (`L × K`) and `F` (`T × K`)

`RcppArmadillo` is used throughout (`arma::mat`, `arma::solve`, `arma::svd`).

## Output Display

`print.sdim_fit` for class `"ipca"`:

```
<sdim_fit [ipca]>
 Observations   : T
 Characteristics: L
 Factors        : K
```

Consistent layout with existing method types.

## Testing

All tests use synthetic data (`matrix(rnorm(...))`); no new datasets required.

### 1. Input validation
- Non-matrix `ret` or non-array `Z` → error
- Mismatched dimensions (T or N) between `ret` and `Z` → error
- `nfac > L` or `nfac > N` → error
- Cross-section with all NAs at some `t` → error with informative message

### 2. Algorithm correctness
- Balanced panel, synthetic DGP: verify `Γ` and `F` recover true factors up to rotation
- Convergence: fitting with `tol = 1e-4` produces smaller final `||ΔΓ||_F` than `tol = 1e-3`
- `eval_factors(ret, fit$factors)` runs without error on IPCA output

### 3. Unbalanced panel
- 10% random NAs in `ret`/`Z`: confirm no crash and `F` has shape `T × K`

## Compatibility

- `eval_factors()`: unchanged — accepts any `T × K` factor matrix
- All existing `sdim` functions: unaffected
- R `>= 4.1.0` (existing package requirement)
- Requires a C++ compiler (standard for packages with Rcpp; documented in README)
