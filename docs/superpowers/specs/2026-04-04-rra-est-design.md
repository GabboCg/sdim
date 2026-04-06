# Design: `rra_est()` — Reduced-Rank Approach Factor Extraction

**Date:** 2026-04-04
**Status:** Approved

---

## Overview

Implement `rra_est(target, X, nfac, compute_stat = FALSE)` in `R/rra_est.R`, completing the fourth and final estimator in the `sdim` package. The algorithm is a 2-step GMM estimator from He, Huang, Li, Zhou (2023) doi:10.1287/mnsc.2022.4428, translated from the reference Matlab implementation (`refs/replication_package_MS-FIN-21-01990/codes/Matlab for Main/func_rraff.m`).

---

## Signature

```r
rra_est(target, X, nfac, compute_stat = FALSE)
```

| Argument | Type | Description |
|---|---|---|
| `target` | T×N numeric matrix | Returns matrix R. A vector is coerced to T×1. |
| `X` | T×L numeric matrix or data frame | Factor proxies G. |
| `nfac` | positive integer | Number of factors K to extract. |
| `compute_stat` | logical, default `FALSE` | Whether to compute the GMM J-test statistic. |

Inputs validated via `.validate_inputs(target, X, nfac)`.

Both `.mat_neghalf(Q)` calls (one per step) must be wrapped independently in `tryCatch`, re-throwing with: `"Q = G'PG/T^2 is not positive definite; check that X has full column rank, nfac < ncol(X), and nfac <= ncol(target)"`.

Roxygen block must include `@param compute_stat`, `@export`, and `@examples` (required for JSS / `R CMD check`). Follow the `pls_est` example pattern.

---

## Algorithm

Direct translation of `func_rraff.m`. Two identical GMM steps; step 1 uses identity weighting matrices, step 2 uses estimated optimal diagonal weights from step 1's residuals.

### Notation

- T: observations, L: factor proxies, N: return series, K = nfac, M = L+1
- G = X (T×L), R = target (T×N)
- Z = cbind(1_T, G) — T×M
- X_int = matrix(1, T, 1) — intercept column

### Step 1 — identity weights

```r
W1 <- diag(N)   # N×N
W2 <- diag(M)   # M×M

P0 <- Z %*% W2 %*% t(Z)
P  <- P0 - P0 %*% X_int %*% solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0

Q    <- t(G) %*% P %*% G / T^2                          # L×L; Qnh is symmetric
Qnh  <- tryCatch(.mat_neghalf(Q), ...)                  # Q^{-1/2}
cross <- t(G) %*% P %*% R / T^2                         # L×N
A    <- Qnh %*% cross %*% W1 %*% t(cross) %*% Qnh       # Qnh symmetric so t(Qnh)==Qnh

ev   <- eigen(A, symmetric = TRUE)                       # eigenvalues descending
E_k  <- ev$vectors[, seq_len(K), drop = FALSE]           # use seq_len, not 1:K; drop=FALSE for K=1
Phi  <- Qnh %*% E_k                                      # L×K
Gstar <- G %*% Phi                                       # T×K initial factors
```

### Residual computation (for weight update)

```r
Beta  <- solve(t(Gstar) %*% P %*% Gstar) %*% t(Gstar) %*% P %*% R  # K×N
Theta <- Phi %*% Beta                                                 # L×N
Alpha <- solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0 %*% (R - G %*% Theta)  # 1×N
U     <- R - X_int %*% Alpha - G %*% Theta                           # T×N

S1 <- diag(diag(t(U) %*% U / T))    # N×N diagonal
S2 <- diag(diag(t(Z) %*% Z / T))    # M×M diagonal
```

### Step 2 — updated weights

```r
W1 <- solve(S1);  W2 <- solve(S2)
# Repeat P0, P, Q, Qnh, cross, A, ev, E_k, Phi, Gstar with same expressions as Step 1.
# The second .mat_neghalf(Q) call also gets its own tryCatch.
```

### Standard outputs

```r
factors   <- Gstar                              # T×K
lambda    <- crossprod(G, factors) / T          # L×K  (consistent with pls_est)
residuals <- G - factors %*% t(lambda)          # T×L
ve2       <- rowMeans(residuals^2)              # length-T (consistent with pca_est, pls_est)
eigvals   <- ev$values[seq_len(K)]              # leading eigenvalues of A (step 2)
```

### GMM J-statistic (when `compute_stat = TRUE`)

After step 2, recompute U using final Phi (P, P0, S1, S2 already available from step 2):

```r
Beta2  <- solve(t(Gstar) %*% P %*% Gstar) %*% t(Gstar) %*% P %*% R
Theta2 <- Phi %*% Beta2
Alpha2 <- solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0 %*% (R - G %*% Theta2)
U2     <- R - X_int %*% Alpha2 - G %*% Theta2

g   <- t(Z) %*% U2 / T                                          # M×N sample moments
J   <- T * sum(diag(t(g) %*% solve(S2) %*% g %*% solve(S1)))   # scalar
# J = T * vec(g)' * (S2^{-1} ⊗ S1^{-1}) * vec(g) via trace-Kronecker identity
df  <- (N - K) * (L - K)
# df derivation: (L+1)*N total moments − [N + K*(L+N−K)] = (N−K)*(L−K)
# df = 0 when K=L (exact identification); df < 0 when K > N (over-specified K)
# In both degenerate cases, set gmm_stat = NULL (keeps sdim_fit.R unchanged).
gmm_stat <- if (df > 0) list(stat = J, df = df,
                              pvalue = pchisq(J, df = df, lower.tail = FALSE)) else NULL
```

Setting `gmm_stat = NULL` when `df <= 0` means `summary.sdim_fit` silently skips the J-stat line (no changes to `sdim_fit.R` needed).

---

## Return Value

An S3 object of class `"sdim_fit"`:

| Field | Value |
|---|---|
| `method` | `"rra"` |
| `factors` | T×K matrix |
| `lambda` | L×K matrix |
| `residuals` | T×L matrix |
| `eigvals` | length-K numeric |
| `ve2` | length-T numeric |
| `call` | `match.call()` |
| `gmm_stat` | `list(stat, df, pvalue)` when `compute_stat = TRUE` and `df > 0`; `NULL` otherwise |
| `beta`, `beta_scaled`, `Xs`, `scaleXs`, `pls_weights`, `gamma` | all `NULL` |

---

## Tests (`tests/testthat/test-rra_est.R`)

Five tests:

1. **Dimensions and class** — `sdim_fit`, `method == "rra"`, correct dims for `factors` (T×K), `lambda` (L×K), `eigvals` (length K).
2. **Eigenvalues sorted descending** — `fit$eigvals` is non-increasing (tests that the eigenvector sort was applied).
3. **`compute_stat = TRUE` returns valid J-stat** — `gmm_stat` is a list; `stat > 0`; `pvalue` in [0, 1]; `!is.na(pvalue)`; `df == (N-K)*(L-K)`. Use fixture with N > K and L > K to guarantee `df > 0`.
4. **`compute_stat = FALSE` (default) returns `NULL` gmm_stat** — protects `summary.sdim_fit` default path.
5. **`ve2` and `residuals` are consistent** — `expect_equal(fit$ve2, rowMeans(fit$residuals^2))` (present in all other estimator test files).

---

## Files Changed

| File | Action |
|---|---|
| `R/rra_est.R` | Create |
| `tests/testthat/test-rra_est.R` | Create |
| `sdim/CLAUDE.md` | Remove `*(planned)*` marker for `rra_est.R` |

No changes to `utils.R`, `sdim_fit.R`, or `NAMESPACE`.
