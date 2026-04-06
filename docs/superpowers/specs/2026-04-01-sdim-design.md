# sdim Package Design Spec

**Date:** 2026-04-01
**Status:** Approved

## Overview

`sdim` is an R package implementing four factor extraction methods from two related papers by an overlapping set of authors:

1. **sPCA** — Huang, Jiang, Li, Tong, and Zhou (2022), "Scaled PCA: A New Approach to Dimension Reduction", *Management Science*, doi:10.1287/mnsc.2021.4020. This is the dedicated source for `spca_est()`.
2. **PCA, PLS, RRA** — He, Huang, Li, and Zhou (2023), "Shrinking Factor Dimension: A Reduced-Rank Approach", *Management Science* 69(9), 5501–5522. RRA is the main contribution; PCA and PLS are included as benchmarks.

It is an independent R implementation of the published methods, targeting submission to the Journal of Statistical Software (JSS).

### Key design note on `target`

sPCA (Huang et al. 2021) was designed for **univariate forecasting**: `target` is a T×1 vector and each predictor is scaled by its slope on that single target. PCA, PLS, and RRA (He et al. 2023) are designed for **multivariate pricing**: `target` is a T×N matrix of asset returns.

For API uniformity, all four functions accept `target` as either a vector or matrix. When `spca_est()` receives a T×N matrix, slopes are averaged across the N target columns before scaling — a practical extension beyond the original paper, documented as such.

---

## File Layout

```
sdim/
├── R/
│   ├── utils.R          # shared internals: .validate_inputs, .standardize_matrix, .winsor, .pc_T
│   ├── sdim_fit.R       # S3 class: print, summary, plot methods for sdim_fit and sdim_list
│   ├── pca_est.R        # PCA estimator
│   ├── pls_est.R        # PLS estimator
│   ├── spca_est.R       # sPCA estimator (refactored from current implementation)
│   ├── rra_est.R        # RRA estimator
│   └── sdim.R           # sdim() wrapper + compare() generic
├── tests/testthat/
│   ├── test-utils.R     # shared helper tests (standardize, winsor, validate)
│   ├── test-pca_est.R
│   ├── test-pls_est.R
│   ├── test-spca_est.R
│   ├── test-rra_est.R   # includes numerical failure modes (singular Q, etc.)
│   └── test-sdim.R      # wrapper and compare()
└── vignettes/
    └── sdim.Rmd         # JSS paper vignette
```

**Cleanup:** Delete `R/hello.R` and `man/hello.Rd`. Move all internal helpers from `spca_est.R` to `utils.R`.

---

## Shared Input Validation (`utils.R`)

All four estimators call `.validate_inputs(target, X, nfac)` at the start. This function:
- Coerces `target` to matrix (via `as.matrix`); accepts T×1 vector or T×N matrix
- Validates `X` via `.as_numeric_matrix(X)` (checks matrix/data.frame, numeric)
- Checks `nrow(X) == nrow(target)`
- Validates `nfac`: positive integer, `nfac <= min(nrow(X), ncol(X))`
- Returns `list(target = target_matrix, X = X_matrix, nfac = as.integer(nfac))`

The existing `.as_numeric_matrix`, `.standardize_matrix`, `.winsor`, `.pc_T` helpers move to `utils.R` unchanged.

---

## S3 Class: `sdim_fit`

All four estimators return an object of class `sdim_fit`. One class means `print`, `summary`, and `plot` are implemented once.

### Common fields (all methods)

| Field | Type | Description |
|---|---|---|
| `method` | character | One of `"pca"`, `"pls"`, `"spca"`, `"rra"` |
| `factors` | T × nfac matrix | Extracted factors |
| `lambda` | N × nfac matrix | Loading matrix |
| `residuals` | T × N matrix | Residuals from factor reconstruction |
| `eigvals` | numeric vector (length nfac) | Leading eigenvalues (for PLS: squared L2-norm of each score vector `t_k`; `NA` if not applicable) |
| `ve2` | numeric vector (length T) | Average squared residual per observation |
| `call` | call | Matched function call |

### Method-specific fields (NULL for other methods)

| Field | Method | Description |
|---|---|---|
| `beta` | sPCA | Univariate predictive slopes (N-length vector) |
| `beta_scaled` | sPCA | Slopes after optional winsorization |
| `Xs` | sPCA | Standardized predictor matrix (T×N) |
| `scaleXs` | sPCA | Beta-scaled standardized predictor matrix (T×N) |
| `gmm_stat` | RRA | Named numeric: `stat` and `pvalue` |
| `pls_weights` | PLS | L×nfac NIPALS weight matrix |
| `gamma` | PCA | The gamma value used for mean-scaling |

### S3 methods

- `print.sdim_fit(x, ...)` — one-line header + method, T, N, nfac
- `summary.sdim_fit(x, ...)` — adds: beta quantiles (sPCA), GMM stat + p-value (RRA), first `nfac` eigenvalues (all), PLS weights summary (PLS)
- `print.summary.sdim_fit(x, ...)` — pretty-prints the summary object
- `plot.sdim_fit(x, index = NULL, ...)` — plots factor time series using base graphics (`par(mfrow = c(nfac, 1))`). `index` is an optional vector of length T for the x-axis (e.g., dates); if NULL, uses `seq_len(T)`. Each panel is one factor. Title shows method and factor number.

---

## Individual Estimator API

### `pca_est()`

```r
pca_est(target = NULL, X, nfac, gamma = -1)
```

Implements PCA on the factor proxies `X`. `target` is accepted for API uniformity but not used.

**Algorithm** (from `extract_factors_weight.m` lines 51–55 and `func_3pca.m`):

Let `G = X` (T×L), `mu = colMeans(G)`.

```
C = G'*G/T + gamma * outer(mu, mu)
[E, v] = eig(C)           # eigendecomposition, sort descending
E_k = E[, 1:nfac]
W = E_k %*% solve(t(E_k) %*% E_k)   # L × nfac weight matrix
factors = G %*% W                     # T × nfac
```

`gamma = -1` (default) gives the sample covariance matrix (traditional PCA).
`gamma = 10` and `gamma = 1` give the Lettau-Ludvigson variants from the paper.

`lambda` = `t(G) %*% factors / T` (L×nfac).
`eigvals` = leading `nfac` eigenvalues of `C`.

---

### `pls_est()`

```r
pls_est(target, X, nfac)
```

Implements PLS via the NIPALS algorithm in base R (no external packages).

**Algorithm:**

Let `G = X` (T×L), `R = target` (T×N). NIPALS with deflation:

```
For k = 1, ..., nfac:
  S = t(G) %*% R              # L×N cross-covariance
  w_k = first right singular vector of S (via svd(S)$v[,1])
  t_k = G %*% w_k             # T×1 score
  Deflate: G = G - t_k %*% (t(t_k) %*% G) / (t(t_k) %*% t_k)
           R = R - t_k %*% (t(t_k) %*% R) / (t(t_k) %*% t_k)
```

`factors` = `[t_1, ..., t_K]` (T×nfac).
`pls_weights` = `[w_1, ..., w_K]` (L×nfac weight matrix, stored as a matrix but the field description says "weight matrix").
`lambda` = `t(X_original) %*% factors / T`.

Note: this matches the SIMPLS/NIPALS approach used in MATLAB's `plsregress` for the univariate-scores step.

---

### `spca_est()`

```r
spca_est(target, X, nfac, winsorize = FALSE, winsor_probs = c(0, 99))
```

Unchanged algorithm from current implementation. When `target` is T×N, slopes are computed for each column of `target` and averaged (element-wise mean of the N slope vectors) before scaling.

Returns `sdim_fit` (replacing current `sdim_spca` class). Fields `Xs`, `scaleXs`, `beta`, `beta_scaled` are populated; others are common.

---

### `rra_est()`

```r
rra_est(target, X, nfac, restrict = FALSE, alpha_bound = NULL)
```

Implements the two-step iteratively re-weighted GMM from He et al. (2023) / Zhou (1994).

Let `R = target` (T×N), `G = X` (T×L), `K = nfac`.

**Unrestricted variant** (`restrict = FALSE`, mirrors `func_rraff.m`):

*Step 1 — identity weights:*

```
Z = cbind(1, G)           # T × (L+1), intercept augmented
X_int = matrix(1, T, 1)  # T × 1 intercept column
W1 = diag(N)
W2 = diag(L+1)
P0 = Z %*% W2 %*% t(Z)                                   # T × T
P  = P0 - P0 %*% X_int %*% solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0  # annihilates intercept
Q  = t(G) %*% P %*% G / T^2                              # L × L
A  = t(Q^(-1/2)) %*% (t(G) %*% P %*% R / T^2) %*% W1 %*% t(t(G) %*% P %*% R / T^2) %*% Q^(-1/2)  # L × L
[E, v] = eigen(A, symmetric=TRUE), sort descending
Phi   = Q^(-1/2) %*% E[, 1:K]                            # L × K
Gstar = G %*% Phi                                         # T × K (candidate factors)
Beta  = solve(t(Gstar) %*% P %*% Gstar) %*% t(Gstar) %*% P %*% R  # K × N
Theta = Phi %*% Beta                                      # L × N
Alpha_hat = solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0 %*% (R - G %*% Theta)  # 1 × N
U = R - X_int %*% t(Alpha_hat) - G %*% Theta             # T × N residuals
S1 = diag(diag(t(U) %*% U / T))                          # N × N diagonal
S2 = diag(diag(t(Z) %*% Z / T))                          # (L+1) × (L+1) diagonal
```

*Step 2 — updated weights (repeat with W1 = solve(S1), W2 = solve(S2)):*

```
W1 = solve(S1); W2 = solve(S2)
P0, P, Q, A recomputed as above with new weights
[E, v] = eigen(A), sort descending
Phi   = Q^(-1/2) %*% E[, 1:K]
factors = G %*% Phi                                       # T × K — final output
```

**Restricted variant** (`restrict = TRUE`, mirrors `func_rraff_PErestrict.m`):

- Requires `alpha_bound` (N-length numeric vector of pre-specified pricing errors)
- Subtract alpha upfront: `R = R - matrix(alpha_bound, T, N, byrow = TRUE)`
- Set `P = P0` throughout (no intercept annihilation — skip the Frisch-Waugh step in both steps)
- Run the identical two-step procedure on alpha-adjusted R: Step 1 still computes `Gstar`, `Beta`, `Theta`, `Alpha_hat`, `U`, `S1`, `S2` as above (the `Alpha_hat` re-estimation in Step 1 is kept even in the restricted case, matching lines 25–29 of `func_rraff_PErestrict.m`)
- Step 2 recomputes with `W1 = solve(S1)`, `W2 = solve(S2)` and returns `Gstar` as factors

**Return object:** `factors` (T×K), `lambda` computed as `t(X) %*% factors / T`, `residuals = R - factors %*% t(lambda)` (using original R), `eigvals` = eigenvalues of A from step 2, `gmm_stat` = `list(stat = v[1], pvalue = pchisq(v[1], df = N - K, lower.tail = FALSE))` (using leading eigenvalue as test statistic). `ve2 = rowMeans(residuals^2)`.

Note: `Q^(-1/2)` denotes the matrix square root of the inverse. Compute via eigendecomposition in base R: if `Q = V D V'` (from `eigen(Q, symmetric = TRUE)`) then `Q^(-1/2) = V %*% diag(d^(-1/2)) %*% t(V)` where `d = eigenvalues`. Do not use `expm`/`logm` (external package dependency). Use `crossprod` for numerical stability where possible.

---

## Unified Wrapper and Comparison

### `sdim()`

```r
sdim(target, X, nfac,
     methods   = c("rra", "spca", "pls", "pca"),
     pca_args  = list(),
     pls_args  = list(),
     spca_args = list(),
     rra_args  = list())
```

Method-specific arguments are passed via named lists (e.g., `pca_args = list(gamma = 10)`, `spca_args = list(winsorize = TRUE)`). No `...` pass-through — this avoids ambiguity when the same argument name exists in multiple estimators. Each `*_args` list is `do.call`-ed into the corresponding estimator. Unknown argument names in `*_args` raise an error from the estimator itself.

Returns a named list of `sdim_fit` objects. The list has class `c("sdim_list", "list")`.

`print.sdim_list(x, ...)` prints a one-line-per-method table: method name, T (from `nrow(x[[i]]$factors)`), N (from `ncol(x[[i]]$residuals)`), nfac (from `ncol(x[[i]]$factors)`), and leading eigenvalue (`x[[i]]$eigvals[1]`).

### `compare()`

```r
compare <- function(x, ...) UseMethod("compare")
compare.sdim_list <- function(x, metrics = c("r2", "mape", "rmse"), ...)
compare.list      <- function(x, metrics = c("r2", "mape", "rmse"), ...)  # dispatches for plain named lists
compare.default   <- function(x, ...) stop("`x` must be an `sdim_list` or a named list of `sdim_fit` objects.", call. = FALSE)
```

`compare.list` validates that all elements have class `sdim_fit` before proceeding; otherwise it stops with an informative message. `compare.sdim_list` and `compare.list` share the same implementation body (one calls the other, or both call a shared internal `.compare_impl()`).

Accepts `sdim_list` (output of `sdim()`) or a plain named list of `sdim_fit` objects. Returns a data frame with one row per method:

| Column | Description |
|---|---|
| `method` | character method name |
| `r2` | in-sample R² (column-wise): `1 - sum(residuals^2) / sum(sweep(target, 2, colMeans(target))^2)` — grand mean of per-column R² values |
| `mape` | mean absolute pricing error: `mean(abs(residuals))` |
| `rmse` | root mean squared pricing error: `sqrt(mean(residuals^2))` |

---

## DESCRIPTION (values to fill in before submission)

```
Title: Factor Extraction via Scaled PCA and Reduced-Rank Approaches
Version: 0.1.0
Description: Implements four factor extraction methods: principal component
    analysis (PCA), partial least squares (PLS), scaled PCA (sPCA) of Huang,
    Jiang, Li, Tong, and Zhou (2022) <doi:10.1287/mnsc.2021.4020>, and the
    reduced-rank approach (RRA) of He, Huang, Li, and Zhou (2023)
    <doi:10.1287/mnsc.2022.4428>. Both papers are published in Management
    Science.
License: MIT + file LICENSE
Depends: R (>= 4.1.0)
Suggests: frenchdata, knitr, rmarkdown, testthat (>= 3.0.0)
VignetteBuilder: knitr
```

Author fields to be filled in by the package author. License: MIT (open, appropriate for independent implementation of published academic method).

---

## NAMESPACE

Use explicit `@export` and `@importFrom` tags via roxygen2. Required entries:

```
export(pca_est, pls_est, spca_est, rra_est, sdim, compare)
S3method(print, sdim_fit)
S3method(summary, sdim_fit)
S3method(print, summary.sdim_fit)
S3method(plot, sdim_fit)
S3method(print, sdim_list)
S3method(compare, sdim_list)
S3method(compare, list)
S3method(compare, default)
importFrom(stats, lm.fit, quantile, sd, cov)
importFrom(graphics, par, plot, lines, title, mtext)
```

---

## Vignette (JSS Paper)

File: `vignettes/sdim.Rmd`, using the `jss` document class (from the `jss` package on CRAN).

### Structure

1. **Introduction** — motivation, relation to Huang et al. (2021) for sPCA and He et al. (2023) for RRA, package overview
2. **Methods** — mathematical description of PCA, PLS, sPCA (citing Huang et al. 2021), RRA (citing He et al. 2023)
3. **Package overview** — API walkthrough with minimal runnable examples
4. **Simulation study** — synthetic K-factor returns; `sdim()` + `compare()`; factor recovery (correlation with ground-truth factors) and pricing errors across methods
5. **Real-data application** — Fama-French data via `frenchdata`; 25 size/BM portfolios as `target`; FF5 + momentum as `X`; `sdim()` + `compare()` table analogous to He et al. Table 2

### Offline build fallback

Wrap the `frenchdata` download chunk in:
```r
knitr::opts_chunk$set(eval = requireNamespace("frenchdata", quietly = TRUE))
```
and provide a small pre-processed dataset in `data/ff_example.rda` as a fallback so `R CMD check` passes without internet.

---

## JSS Requirements Checklist

- [ ] `DESCRIPTION`: fill in Author, fill in Maintainer, verify License file present
- [ ] All exported functions have `@examples` passing `R CMD check --run-donttest`
- [ ] Vignette builds cleanly under `R CMD check` (offline fallback in place)
- [ ] `devtools::check()` returns 0 errors, 0 warnings, 0 notes
- [ ] Delete `hello.R` and `hello.Rd`
- [ ] No external hard dependencies (only base R + `stats` + `graphics`)
