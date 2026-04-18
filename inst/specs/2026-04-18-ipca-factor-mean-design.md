# IPCA `factor_mean` Extension — Design Spec

**Date:** 2026-04-18
**Status:** Approved

## Overview

Extend `ipca_est()` with a `factor_mean` parameter that characterises the time-series mean structure of the estimated latent factors. Three specifications are supported: `"zero"` (no mean, default), `"constant"` (constant factor mean estimated as time-series average), and `"VAR"` (factor means follow a VAR(1) process). All three share the same ALS estimation loop; the specifications differ only in post-ALS computation attached to the return object.

## Reference

Kelly, B., Pruitt, S., & Su, Y. (2019). Characteristics are covariances: A unified model of risk and return. *Journal of Financial Economics*, 134(3), 501–524.

## Files

### Modified
- `R/ipca_est.R` — add `factor_mean` argument, validation, post-ALS computation, updated return object and roxygen docs
- `R/sdim_fit.R` — add "Factor mean" display line in `print.sdim_fit` and `print.summary.sdim_fit`
- `tests/testthat/test-ipca_est.R` — add five new tests (one per spec + invalid value + display)

### Unchanged
- `src/ipca_als.cpp` — ALS loop is identical for all three specs
- `DESCRIPTION`, `NAMESPACE` — no new dependencies

## R API

```r
ipca_est(ret, Z, nfac, max_iter = 100, tol = 1e-6, factor_mean = "zero")
```

**New argument:**
- `factor_mean`: character scalar, one of `"zero"`, `"constant"`, `"VAR"`. Default `"zero"`. Error if any other value is supplied.

**Returns:** an `sdim_fit` object of class `"ipca"` with all existing fields plus:

| `factor_mean` | Extra fields |
|---|---|
| `"zero"` | none |
| `"constant"` | `mu`: length-K numeric vector — time-series mean of each factor (`colMeans(F)`) |
| `"VAR"` | `var_coef`: K×K numeric matrix (A in f_t = c + A f_{t-1} + η_t), `var_intercept`: length-K numeric vector (c), `var_resid`: (T−1)×K numeric matrix |

The value `factor_mean` is also stored as `fit$factor_mean` (character scalar) for display and downstream use.

## Algorithm — Post-ALS Computation

The Rcpp function `ipca_als_cpp` runs identically for all three specs. After obtaining `F` (T×K) from Rcpp:

### `"zero"`
No additional computation.

### `"constant"`
```r
mu <- colMeans(res[["F"]])   # K-vector
```

### `"VAR"`
OLS fit of the VAR(1) model f_t = c + A f_{t-1} + η_t:

```r
F   <- res[["F"]]
Y   <- F[-1L, , drop = FALSE]                    # (T-1) x K  (response)
X   <- cbind(1, F[-nrow(F), , drop = FALSE])     # (T-1) x (K+1) (1 + lagged factors)
B   <- solve(crossprod(X), crossprod(X, Y))      # (K+1) x K
var_intercept <- B[1L, ]                         # K-vector
var_coef      <- B[-1L, , drop = FALSE]          # K x K
var_resid     <- Y - X %*% B                     # (T-1) x K
```

If `crossprod(X)` is near-singular (e.g. T is very small), a ridge term `1e-8 * diag(K+1)` is added before solving.

## Output Display

`print.sdim_fit` — add one line inside the `"ipca"` branch:

```r
cat(" Factor mean     :", x$factor_mean, "\n")
```

`print.summary.sdim_fit` — add a conditional row in the Dimensions block:

```r
if (x$method == "ipca")
  cat(sprintf(" %-16s %s\n", "Factor mean", x$factor_mean))
```

`print.sdim_list` — no changes.

## Testing

All tests use synthetic data. Appended to `tests/testthat/test-ipca_est.R`.

### 1. `factor_mean = "zero"` (default)
- Return object has no `mu`, `var_coef`, `var_intercept`, or `var_resid` fields.

### 2. `factor_mean = "constant"`
- `fit$mu` is a numeric vector of length K.
- `fit$mu` equals `colMeans(fit$factors)` (up to floating-point tolerance).

### 3. `factor_mean = "VAR"`
- `fit$var_coef` is K×K numeric matrix.
- `fit$var_intercept` is length-K numeric vector.
- `fit$var_resid` is a numeric matrix with `nrow(fit$factors) - 1` rows and K columns.

### 4. Invalid `factor_mean` value
- `factor_mean = "foo"` → informative error.

### 5. Display
- `print()` and `summary()` run without error for all three `factor_mean` specs.

## Compatibility

- `eval_factors()`: unchanged — uses `fit$factors`, which is unaffected.
- All existing `sdim` functions: unaffected.
- `ipca_est()` with default `factor_mean = "zero"` is backward-compatible with existing calls.
