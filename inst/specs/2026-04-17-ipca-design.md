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
- `DESCRIPTION` — add `LinkingTo: Rcpp, RcppArmadillo` and `Imports: Rcpp`. Note: `RcppArmadillo` belongs in `LinkingTo` only, not `Imports`.
- `NAMESPACE` — add `useDynLib` and `importFrom(Rcpp, sourceRcpp)`
- `R/sdim_fit.R` — add `"ipca"` branch in `print.sdim_fit` and `"ipca"` label in `print.summary.sdim_fit` switch (see Output Display section)

## R API

```r
ipca_est(ret, Z, nfac, max_iter = 100, tol = 1e-6)
```

**Arguments:**
- `ret`: `T × N` numeric matrix of asset returns. `NA` indicates a missing observation (unbalanced panel).
- `Z`: `T × N × L` numeric array of asset characteristics. `NA`s must exactly mirror `ret` (same positions).
- `nfac`: integer `K`, number of latent factors to extract.
- `max_iter`: maximum ALS iterations (default 100).
- `tol`: convergence tolerance on Frobenius norm of `Γ` change (default 1e-6).

**Returns:** an `sdim_fit` object of class `"ipca"`:

```r
list(
  method  = "ipca",
  call    = match.call(),   # consistent with all other sdim methods
  factors = F,              # T × K numeric matrix — latent factor realizations
  lambda  = Gamma,          # L × K numeric matrix — characteristic loadings
                            # named `lambda` to match package convention;
                            # corresponds to Γ in Kelly et al. (2019)
  eigvals = sv,             # length-K numeric vector — singular values of final Γ
                            # used by print/summary for variance explained display
  nfac    = K               # number of factors
)
```

**Field naming rationale:** `lambda` and `eigvals` are used in `print.sdim_fit`, `summary.sdim_fit`, and `print.sdim_list` without method dispatch (`nrow(x$lambda)`, `x$eigvals[1]`). Using these names keeps all three functions working for IPCA objects and for mixed-method `sdim_list` objects without any conditional branching. Internally the variable is `Gamma` (following the paper); it is stored as `lambda` in the return list.

`eigvals` holds the K singular values of the final normalized `Γ`, providing a natural measure of characteristic importance analogous to eigenvalues in PCA.

The `factors` field is identical in name and shape to `pca_est`, `pls_est`, etc. — so **`eval_factors()` works unchanged**.

## Algorithm

### Model

```
r_{i,t} = z_{i,t}' Γ f_t + ε_{i,t}
```

where `z_{i,t}` is the `L`-vector of characteristics for asset `i` at time `t`, `Γ` is the `L × K` loading matrix, and `f_t` is the `K`-vector of latent factors.

### Data Preparation (R layer)

For each time period `t = 1, …, T`, extract the set of observed (non-NA) asset indices `I_t`. Build:

- `ret_list`: list of `T` numeric vectors; element `t` is `r_t` of length `N_t = |I_t|`
- `Z_list`: list of `T` numeric matrices; element `t` is `Z_t` of shape `N_t × L`

Pass both lists to the Rcpp function.

**Precondition enforced by input validation:** `N_t ≥ K` for all `t`. If any time period has fewer observed assets than factors, raise an informative error before entering ALS.

### ALS Loop (Rcpp/RcppArmadillo)

**Initialization:**
Build the `L × T` matrix `M` where column `t` is `Z_t' r_t` (shape `L × 1`, sum of characteristic-weighted returns). Take the thin SVD of `M = U S V'`. Initialize `Γ = U[:, 1:K]` (first `K` left singular vectors), shape `L × K`.

**Repeat until convergence (max `max_iter` iterations):**

1. **Factor step:** for each `t = 1, …, T`, solve the `K × K` system:

   ```
   A_t = Γ' Z_t' Z_t Γ          # K × K
   b_t = Γ' Z_t' r_t             # K × 1
   f_t = arma::solve(A_t, b_t)
   ```

   If `A_t` is near-singular (detected by `arma::solve` failure), fall back to ridge: `A_t + 1e-8 * I_K`. Collect `f_t` as row `t` of `F` (shape `T × K`).

2. **Loading step:** update `Γ` via the pooled OLS normal equations (Kelly et al. 2019, eq. 12). Vectorize over `Γ`:

   ```
   LHS = Σ_t  kron(f_t f_t', Z_t' Z_t)    # KL × KL
   RHS = vec( Σ_t  Z_t' r_t f_t' )         # KL × 1
   vec(Γ) = arma::solve(LHS, RHS)
   Γ = reshape(vec(Γ), L, K)               # arma::reshape
   ```

   In code, `LHS` is accumulated as `LHS += arma::kron(f_t * f_t.t(), Z_t.t() * Z_t)` over `t`.

   **Column-major note:** Armadillo uses column-major storage. `arma::vec` stacks columns of a matrix; `arma::reshape(v, L, K)` fills column-by-column. The Kronecker order `kron(f_t f_t', Z_t' Z_t)` (K×K ⊗ L×L = KL×KL) is consistent with `vec(Γ)` stacking columns of the L×K matrix Γ under this convention. Do not swap the operands of `kron`.

3. **Normalize:** compute thin SVD of `Γ = U S V'`. Set:
   - `Γ ← U[:, 1:K]` (ensures `Γ'Γ = I_K`)
   - `F ← F * V * diag(S)` (rotate factors to preserve fitted values)
   - Sign convention: for each column `k`, if the element of `Γ[:, k]` with largest absolute value is negative, flip the sign of column `k` in both `Γ` and `F`.

4. **Convergence check:** `||Γ_new - Γ_old||_F < tol`. Store `Γ_old ← Γ_new`.

**Non-convergence:** if the loop exits at `max_iter` without converging, issue `warning("ipca_est: ALS did not converge in ", max_iter, " iterations")` and return current estimates.

**Return to R:** `Γ` (`L × K`), `F` (`T × K`), and singular values `sv` (length `K`) from the final normalization SVD.

**Rcpp function signature** (exported from `src/ipca_als.cpp`):

```cpp
// [[Rcpp::export]]
Rcpp::List ipca_als_cpp(Rcpp::List ret_list, Rcpp::List Z_list,
                        int K, int max_iter, double tol);
```

Returns a named `List` with elements `"Gamma"` (`L × K` `arma::mat`), `"F"` (`T × K` `arma::mat`), and `"sv"` (`arma::vec` length `K`). The R wrapper calls it as `ipca_als_cpp(ret_list, Z_list, K, max_iter, tol)`.

## Output Display

`print.sdim_fit` adds an `"ipca"` branch using `"Characteristics"` as the label:

```r
if (x$method == "ipca") {
  cat(sprintf("<sdim_fit [%s]>\n", x$method))
  cat(" Observations    :", nrow(x$factors), "\n")
  cat(" Characteristics :", nrow(x$lambda),  "\n")
  cat(" Factors         :", ncol(x$factors), "\n")
  return(invisible(x))
}
```

`print.summary.sdim_fit` adds `"ipca"` to the `method_label` switch:

```r
ipca = "Instrumented Principal Components Analysis (IPCA)"
```

Additionally, the Dimensions block in `print.summary.sdim_fit` prints `"Predictors"` for all methods (line 58 of `sdim_fit.R`). For IPCA, replace this label with `"Characteristics"`. Add a conditional for the label:

```r
pred_label <- if (x$method == "ipca") "Characteristics" else "Predictors"
cat(sprintf(" %-16s %d\n", pred_label, x$n_pred))
```

`print.sdim_list` requires **no changes** because `lambda` and `eigvals` are present in the IPCA return object.

## Testing

All tests use synthetic data (`matrix(rnorm(...))`); no new datasets required.

### 1. Input validation
- Non-matrix `ret` → error
- Non-array `Z` → error
- Mismatched T or N between `ret` and `Z` → error
- `nfac > L` → error
- `nfac > min(N_t)` (fewer observed assets than factors at some t) → error
- NAs in `Z` that do not mirror `ret` → informative error

### 2. Algorithm correctness
- Balanced panel, synthetic DGP with known `Γ` and `F`: verify `fit$lambda %*% t(fit$lambda)` approximates `Γ_true %*% t(Γ_true)` (rotation-invariant check)
- `eval_factors(ret, fit$factors)` runs without error on IPCA output
- `print(fit)` and `summary(fit)` run without error
- Non-convergence path: set `max_iter = 1`, confirm a warning is issued

### 3. Edge cases
- `nfac = 1`: single factor; verify no matrix-to-vector coercion error in Rcpp
- `nfac = L`: square `Γ`; verify normalization does not error
- Unbalanced panel (10% random NAs in `ret`/`Z` mirrored): no crash, `fit$factors` has shape `T × K`
- Mixed `sdim_list` with `rra` and `ipca` fits: `print.sdim_list` runs without error

## Compatibility

- `eval_factors()`: unchanged
- All existing `sdim` functions: unaffected
- R `>= 4.1.0` (existing package requirement)
- Requires a C++ compiler (standard for Rcpp packages; documented in README)
