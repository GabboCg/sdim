# IPCA `factor_mean` Parameter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `factor_mean` parameter to `ipca_est()` supporting `"zero"` (default), `"constant"`, and `"VAR"` specifications, with corresponding display updates.

**Architecture:** The Rcpp ALS loop (`ipca_als_cpp`) is unchanged. All three specs share the same estimation; they differ only in post-ALS computation in the R wrapper and in the display methods. Task 1 introduces the full return-list skeleton (`extra <- list()` + `c(list(...), extra)`) so Tasks 2 and 3 only append to `extra` without touching the return structure again.

**Tech Stack:** R 4.1+, testthat 3, roxygen2. No new packages.

---

## File Map

| File | Change |
|---|---|
| `R/ipca_est.R` | Add `factor_mean` parameter, validation, post-ALS computation, return-list update, roxygen `@param`/`@return` |
| `R/sdim_fit.R` | Add "Factor mean" line in `print.sdim_fit`; copy `factor_mean` in `summary.sdim_fit`; add row in `print.summary.sdim_fit` |
| `tests/testthat/test-ipca_est.R` | Add 6 new `test_that` blocks |

---

## Task 1: `factor_mean` parameter skeleton — validation and `"zero"` default

**Files:**
- Modify: `R/ipca_est.R`
- Test: `tests/testthat/test-ipca_est.R`

### Background

Current `R/ipca_est.R` structure (read the file before editing):
- Line 24: function signature
- Lines 29–70: input validation (ret, Z, dimensions, nfac, max_iter, tol)
- Lines 72–80: NA-mirror check loop
- Lines 83–96: per-period list building
- Lines 98–100: `ipca_als_cpp` call
- Lines 102–110: `structure(list(...), class = "sdim_fit")` return

We make three changes:
1. Add `factor_mean = "zero"` to the signature.
2. Add `factor_mean` validation **after line 70** (end of `tol` check) and **before line 72** (NA-mirror loop) — it belongs with the input validation section.
3. Replace the return block (lines 102–110) **once** with the `extra`-pattern that all subsequent tasks will reuse. Task 2 and Task 3 will only append to `extra`; they will NOT touch the return block again.

- [ ] **Step 1.1: Write the two failing tests**

Append to `tests/testthat/test-ipca_est.R`:

```r
# ---------------------------------------------------------------------------
# factor_mean tests
# ---------------------------------------------------------------------------

test_that("factor_mean = 'zero' stores scalar and no extra fields", {
  set.seed(10)
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  fit <- ipca_est(ret, Z, nfac = 2)
  expect_equal(fit$factor_mean, "zero")
  expect_null(fit$mu)
  expect_null(fit$var_coef)
  expect_null(fit$var_intercept)
  expect_null(fit$var_resid)
})

test_that("ipca_est errors on invalid factor_mean value", {
  set.seed(14)
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  expect_error(
    ipca_est(ret, Z, nfac = 2, factor_mean = "foo"),
    regexp = "factor_mean.*must be one of"
  )
})
```

- [ ] **Step 1.2: Run the failing tests**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/AI/sdim"
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: both new tests FAIL (`fit$factor_mean` is `NULL`; no error on `"foo"`).

- [ ] **Step 1.3: Change the function signature (line 24 of `R/ipca_est.R`)**

```r
ipca_est <- function(ret, Z, nfac, max_iter = 100, tol = 1e-6,
                     factor_mean = "zero") {
```

- [ ] **Step 1.4: Add `factor_mean` validation (insert between line 70 and line 72)**

After the closing brace of the `tol` check (line 70) and before the comment `# Check NAs mirror between ret and Z` (line 72), insert:

```r
  if (!is.character(factor_mean) || length(factor_mean) != 1L ||
        !factor_mean %in% c("zero", "constant", "VAR"))
    stop(
      "`factor_mean` must be one of \"zero\", \"constant\", or \"VAR\".",
      call. = FALSE
    )
```

- [ ] **Step 1.5: Replace the return block (lines 102–110) with the `extra` pattern**

Replace the entire block:
```r
  structure(
    list(method  = "ipca",
         call    = cl,
         factors = res[["F"]],
         lambda  = res[["Gamma"]],
         eigvals = as.numeric(res[["sv"]]),
         nfac    = nfac),
    class = "sdim_fit"
  )
```

with:
```r
  # --- Post-ALS: factor mean ---
  extra <- list()

  # (factor_mean = "constant" and "VAR" branches will be added here in Tasks 2 and 3)

  structure(
    c(list(method      = "ipca",
           call        = cl,
           factors     = res[["F"]],
           lambda      = res[["Gamma"]],
           eigvals     = as.numeric(res[["sv"]]),
           nfac        = nfac,
           factor_mean = factor_mean),
      extra),
    class = "sdim_fit"
  )
```

Note: `c(list(...), list())` in R merges named lists, preserving all names. `structure()` then sets `class = "sdim_fit"` on the result. This pattern is correct and used throughout Tasks 1–3 — only `extra` grows.

- [ ] **Step 1.6: Run the tests**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: both new tests pass; all existing tests pass.

- [ ] **Step 1.7: Run `devtools::check()`**

```bash
Rscript -e "devtools::check()" 2>&1 | tail -20
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 1.8: Commit**

```bash
git add R/ipca_est.R tests/testthat/test-ipca_est.R
git commit -m "feat(ipca): add factor_mean param skeleton with 'zero' default and validation"
```

---

## Task 2: `factor_mean = "constant"`

**Files:**
- Modify: `R/ipca_est.R`
- Test: `tests/testthat/test-ipca_est.R`

### Background

When `factor_mean == "constant"`, compute `mu <- colMeans(res[["F"]])` (K-vector) and add it to `extra`. The return block and the `extra <- list()` line are already in place from Task 1 — do not touch them. Only add a branch before the `structure(...)` call.

- [ ] **Step 2.1: Write the failing test**

Append to `tests/testthat/test-ipca_est.R`:

```r
test_that("factor_mean = 'constant' stores mu = colMeans(factors)", {
  set.seed(11)
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  fit <- ipca_est(ret, Z, nfac = 2, factor_mean = "constant")
  expect_equal(fit$factor_mean, "constant")
  expect_length(fit$mu, 2L)
  expect_equal(fit$mu, colMeans(fit$factors), tolerance = 1e-10)
  expect_null(fit$var_coef)
  expect_null(fit$var_intercept)
  expect_null(fit$var_resid)
})
```

- [ ] **Step 2.2: Run the failing test**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: FAIL — `fit$mu` is `NULL`.

- [ ] **Step 2.3: Implement in `R/ipca_est.R`**

Replace the placeholder comment inside the `# --- Post-ALS: factor mean ---` block:

```r
  # (factor_mean = "constant" and "VAR" branches will be added here in Tasks 2 and 3)
```

with:

```r
  if (factor_mean == "constant") {
    extra$mu <- colMeans(res[["F"]])
  }
```

Leave the `extra <- list()` line and the `structure(c(...), ...)` return block completely untouched.

- [ ] **Step 2.4: Run the tests**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: all tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add R/ipca_est.R tests/testthat/test-ipca_est.R
git commit -m "feat(ipca): implement factor_mean = 'constant'"
```

---

## Task 3: `factor_mean = "VAR"`

**Files:**
- Modify: `R/ipca_est.R`
- Test: `tests/testthat/test-ipca_est.R`

### Background

When `factor_mean == "VAR"`, fit a VAR(1) on the estimated factors:

```
F[2:T,] = c + A F[1:(T-1),] + η
```

**Pre-condition:** raise an error if `T ≤ nfac + 1` — with fewer than `nfac + 2` observations, `crossprod(X)` (shape `(K+1)×(K+1)`) is rank-deficient. The pre-condition check goes at the **top** of the `"VAR"` branch, before any OLS computation.

Use `tryCatch` around `solve()` with a ridge fallback.

Fields added to `extra`:
- `var_intercept`: K-vector
- `var_coef`: K×K matrix
- `var_resid`: (T−1)×K matrix

- [ ] **Step 3.1: Write the failing tests**

Append to `tests/testthat/test-ipca_est.R`:

```r
test_that("factor_mean = 'VAR' stores var_coef, var_intercept, var_resid", {
  set.seed(12)
  T <- 60; N <- 15; L <- 4; K <- 2
  ret <- matrix(rnorm(T * N) / 100, T, N)
  Z   <- array(rnorm(T * N * L), dim = c(T, N, L))
  fit <- ipca_est(ret, Z, nfac = K, factor_mean = "VAR")
  expect_equal(fit$factor_mean, "VAR")
  expect_equal(dim(fit$var_coef),  c(K, K))
  expect_length(fit$var_intercept, K)
  expect_equal(dim(fit$var_resid), c(T - 1L, K))
  expect_null(fit$mu)
})

test_that("factor_mean = 'VAR' errors when T <= nfac + 1", {
  set.seed(13)
  K <- 2; T <- K + 1L   # T = 3; need T > 3
  ret <- matrix(rnorm(T * 10) / 100, T, 10)
  Z   <- array(rnorm(T * 10 * 4), dim = c(T, 10, 4))
  expect_error(
    ipca_est(ret, Z, nfac = K, factor_mean = "VAR"),
    regexp = "T > nfac \\+ 1"
  )
})
```

- [ ] **Step 3.2: Run the failing tests**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: both new tests FAIL.

- [ ] **Step 3.3: Implement in `R/ipca_est.R`**

After the `"constant"` branch, add the `"VAR"` branch (still inside the `# --- Post-ALS: factor mean ---` block, before the `structure(...)` call):

```r
  if (factor_mean == "VAR") {
    f_mat <- res[["F"]]
    if (nrow(f_mat) <= nfac + 1L)
      stop(
        "`factor_mean = 'VAR'` requires T > nfac + 1 time periods.",
        call. = FALSE
      )
    Y   <- f_mat[-1L, , drop = FALSE]
    X   <- cbind(1, f_mat[-nrow(f_mat), , drop = FALSE])
    XtX <- crossprod(X)
    XtY <- crossprod(X, Y)
    B   <- tryCatch(
      solve(XtX, XtY),
      error = function(e)
        solve(XtX + 1e-8 * diag(nrow(XtX)), XtY)
    )
    extra$var_intercept <- B[1L, ]
    extra$var_coef      <- B[-1L, , drop = FALSE]
    extra$var_resid     <- Y - X %*% B
  }
```

- [ ] **Step 3.4: Run the tests**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: all tests pass.

- [ ] **Step 3.5: Run `devtools::check()`**

```bash
Rscript -e "devtools::check()" 2>&1 | tail -20
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 3.6: Commit**

```bash
git add R/ipca_est.R tests/testthat/test-ipca_est.R
git commit -m "feat(ipca): implement factor_mean = 'VAR'"
```

---

## Task 4: Display updates in `R/sdim_fit.R`

**Files:**
- Modify: `R/sdim_fit.R`
- Test: `tests/testthat/test-ipca_est.R`

### Background

Three changes to `R/sdim_fit.R` (read the file before editing):

**Change A — `print.sdim_fit` (lines 4–10):** Add `cat(" Factor mean     :", x$factor_mean, "\n")` immediately before `return(invisible(x))` (line 9). The full updated block:

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

**Change B — `summary.sdim_fit` (lines 21–43):** Add `out$factor_mean <- object$factor_mean` after the `gmm_stat` block (after line 39). The tail of `summary.sdim_fit` becomes:

```r
  if (!is.null(object$gamma))
    out$gamma <- object$gamma
  if (!is.null(object$gmm_stat))
    out$gmm_stat <- object$gmm_stat

  out$factor_mean <- object$factor_mean

  class(out) <- "summary.sdim_fit"
  out
```

**Change C — `print.summary.sdim_fit` (lines 47–93):** Add a conditional "Factor mean" row after line 68 (`cat(sprintf(" %-16s %d\n", "Factors", x$n_fac))`), before the `if (!is.null(x$gamma))` block at line 70:

```r
  cat(sprintf(" %-16s %d\n", "Factors",       x$n_fac))

  if (!is.null(x$factor_mean) && x$method == "ipca")
    cat(sprintf(" %-16s %s\n", "Factor mean", x$factor_mean))

  if (!is.null(x$gamma))
    cat(sprintf(" %-16s %g\n", "gamma (PCA)",  x$gamma))
```

- [ ] **Step 4.1: Write the failing test**

Append to `tests/testthat/test-ipca_est.R`:

```r
test_that("print and summary show Factor mean for all three specs", {
  set.seed(15)
  ret <- matrix(rnorm(60 * 12) / 100, 60, 12)
  Z   <- array(rnorm(60 * 12 * 5), dim = c(60, 12, 5))

  for (fm in c("zero", "constant", "VAR")) {
    fit <- ipca_est(ret, Z, nfac = 2, factor_mean = fm)

    out_print   <- capture.output(print(fit))
    out_summary <- capture.output(summary(fit))

    expect_true(
      any(grepl("Factor mean", out_print)),
      info = paste("print() missing 'Factor mean' for factor_mean =", fm)
    )
    expect_true(
      any(grepl(fm, out_print)),
      info = paste("print() missing spec value for factor_mean =", fm)
    )
    expect_true(
      any(grepl("Factor mean", out_summary)),
      info = paste("summary() missing 'Factor mean' for factor_mean =", fm)
    )
    expect_true(
      any(grepl(fm, out_summary)),
      info = paste("summary() missing spec value for factor_mean =", fm)
    )
  }
})
```

- [ ] **Step 4.2: Run the failing test**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: FAIL — "Factor mean" not found in output.

- [ ] **Step 4.3: Apply Change A to `R/sdim_fit.R`**

Replace the `"ipca"` branch (lines 4–10) as described in Background above.

- [ ] **Step 4.4: Apply Change B to `R/sdim_fit.R`**

Add `out$factor_mean <- object$factor_mean` as described in Background above.

- [ ] **Step 4.5: Apply Change C to `R/sdim_fit.R`**

Add the conditional "Factor mean" row after line 68 as described in Background above.

- [ ] **Step 4.6: Run all tests**

```bash
Rscript -e "devtools::test(filter = 'ipca_est')" 2>&1 | tail -30
```

Expected: all 6 new tests and all existing tests pass.

- [ ] **Step 4.7: Run `devtools::check()`**

```bash
Rscript -e "devtools::check()" 2>&1 | tail -20
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 4.8: Commit**

```bash
git add R/sdim_fit.R tests/testthat/test-ipca_est.R
git commit -m "feat(ipca): add Factor mean display in print and summary"
```

---

## Task 5: Roxygen docs for `factor_mean`

**Files:**
- Modify: `R/ipca_est.R` (roxygen block only)

- [ ] **Step 5.1: Add `@param` for `factor_mean`**

In the roxygen block of `ipca_est()` (before `@return`, currently at line 12), add after the `@param tol` entry:

```r
#' @param factor_mean Character scalar controlling the factor mean
#'   specification. One of \code{"zero"} (default — no mean adjustment),
#'   \code{"constant"} (time-series average stored as \code{fit$mu}), or
#'   \code{"VAR"} (VAR(1) coefficients stored as \code{fit$var_coef},
#'   \code{fit$var_intercept}, \code{fit$var_resid}). Requires
#'   \code{T > nfac + 1} for \code{"VAR"}.
```

- [ ] **Step 5.2: Update `@return`**

Replace the existing `@return` lines (12–15) with:

```r
#' @return An object of class \code{"sdim_fit"} with fields:
#'   \code{factors} (T x K), \code{lambda} (L x K characteristic loadings,
#'   i.e. Gamma in Kelly et al.), \code{eigvals} (factor variances),
#'   \code{factor_mean} (character scalar), \code{call},
#'   \code{method = "ipca"}, \code{nfac}.
#'   If \code{factor_mean = "constant"}: also \code{mu} (length-K mean vector).
#'   If \code{factor_mean = "VAR"}: also \code{var_coef} (K x K),
#'   \code{var_intercept} (length-K), \code{var_resid} ((T-1) x K).
```

- [ ] **Step 5.3: Regenerate documentation**

```bash
Rscript -e "devtools::document()" 2>&1 | tail -10
```

Expected: `Writing man/ipca_est.Rd` in output.

- [ ] **Step 5.4: Verify help page renders**

```bash
Rscript -e "devtools::load_all(); ?ipca_est" 2>&1 | head -30
```

Confirm `factor_mean` appears in the Arguments section.

- [ ] **Step 5.5: Run final check**

```bash
Rscript -e "devtools::check()" 2>&1 | tail -20
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 5.6: Commit**

```bash
git add R/ipca_est.R man/ipca_est.Rd
git commit -m "docs(ipca): add factor_mean param and updated return to roxygen docs"
```
