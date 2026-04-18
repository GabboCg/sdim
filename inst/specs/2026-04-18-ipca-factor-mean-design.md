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
- `R/sdim_fit.R` — add "Factor mean" display line in `print.sdim_fit` and `print.summary.sdim_fit`; copy `factor_mean` into the summary list in `summary.sdim_fit`
- `tests/testthat/test-ipca_est.R` — add six new tests (specs for zero/constant/VAR + VAR edge case + invalid value + display text)

### Unchanged
- `src/ipca_als.cpp` — ALS loop is identical for all three specs
- `DESCRIPTION`, `NAMESPACE` — no new dependencies or exports

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

The `factor_mean` character scalar is **always** stored in the return object as `fit$factor_mean`, regardless of the spec value. This is required by the display functions.

## Algorithm — Post-ALS Computation

The Rcpp function `ipca_als_cpp` runs identically for all three specs. After obtaining `F` (T×K) from Rcpp:

### `"zero"`
No additional computation.

### `"constant"`
```r
mu <- colMeans(res[["F"]])   # K-vector
```

### `"VAR"`

**Pre-condition check:** raise an informative error if T ≤ K + 1, because `crossprod(X)` (which is (K+1)×(K+1)) would be rank-deficient with fewer than K+2 observations:

```r
if (nrow(res[["F"]]) <= nfac + 1L)
  stop(
    "`factor_mean = 'VAR'` requires T > nfac + 1 time periods.",
    call. = FALSE
  )
```

OLS fit of the VAR(1) model f_t = c + A f_{t-1} + η_t:

```r
F   <- res[["F"]]
Y   <- F[-1L, , drop = FALSE]                    # (T-1) x K  (response)
X   <- cbind(1, F[-nrow(F), , drop = FALSE])     # (T-1) x (K+1) (1 + lagged factors)
XtX <- crossprod(X)                              # (K+1) x (K+1)
XtY <- crossprod(X, Y)                           # (K+1) x K
B   <- tryCatch(
  solve(XtX, XtY),
  error = function(e) solve(XtX + 1e-8 * diag(nrow(XtX)), XtY)
)                                                # (K+1) x K
var_intercept <- B[1L, ]                         # K-vector
var_coef      <- B[-1L, , drop = FALSE]          # K x K
var_resid     <- Y - X %*% B                     # (T-1) x K
```

The `tryCatch` ridge fallback handles near-singular `XtX` if the pre-condition check passes but the system is still numerically ill-conditioned.

## Output Display

### `print.sdim_fit`
Inside the `"ipca"` branch, add the "Factor mean" line **before** the `return(invisible(x))`:

```r
if (x$method == "ipca") {
  cat(sprintf("<sdim_fit [%s]>\n", x$method))
  cat(" Observations    :", nrow(x$factors), "\n")
  cat(" Characteristics :", nrow(x$lambda),  "\n")
  cat(" Factors         :", ncol(x$factors), "\n")
  cat(" Factor mean     :", x$factor_mean,   "\n")
  return(invisible(x))
}
```

### `summary.sdim_fit`
Add `factor_mean` to the summary list that is built and returned (analogous to how `gamma` and `gmm_stat` are copied):

```r
out$factor_mean <- object$factor_mean   # always present; NULL-safe for non-ipca methods
```

Then in `print.summary.sdim_fit`, add a conditional row in the Dimensions block:

```r
if (!is.null(x$factor_mean) && x$method == "ipca")
  cat(sprintf(" %-16s %s\n", "Factor mean", x$factor_mean))
```

### `print.sdim_list`
No changes.

## Testing

All tests use synthetic data. Appended to `tests/testthat/test-ipca_est.R`.

### 1. `factor_mean = "zero"` (default)
- `fit$factor_mean` equals `"zero"`.
- Return object has no `mu`, `var_coef`, `var_intercept`, or `var_resid` fields (`NULL`).

### 2. `factor_mean = "constant"`
- `fit$mu` is a numeric vector of length K.
- `fit$mu` equals `colMeans(fit$factors)` (up to floating-point tolerance).
- `fit$var_coef`, `fit$var_intercept`, `fit$var_resid` are all `NULL`.

### 3. `factor_mean = "VAR"`
- `fit$var_coef` is a K×K numeric matrix.
- `fit$var_intercept` is a length-K numeric vector.
- `fit$var_resid` is a numeric matrix with `nrow(fit$factors) - 1` rows and K columns.
- `fit$mu` is `NULL`.

### 4. `factor_mean = "VAR"` with T ≤ K + 1
- `expect_error(..., regexp = "T > nfac \\+ 1")` — the error message must contain the substring `T > nfac + 1`.

### 5. Invalid `factor_mean` value
- `factor_mean = "foo"` → informative error.

### 6. Display
- For each of the three specs, `capture.output(print(fit))` contains a line matching `"Factor mean"` and the spec value (e.g., `"zero"`, `"constant"`, `"VAR"`).
- `summary(fit)` runs without error for all three specs.

## Compatibility

- `eval_factors()`: unchanged — uses `fit$factors`, which is unaffected.
- All existing `sdim` functions: unaffected.
- `ipca_est()` with default `factor_mean = "zero"` is backward-compatible with existing calls. The only additive change is the `factor_mean = "zero"` field in the return list, which is non-breaking.
