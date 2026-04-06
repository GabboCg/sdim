# sdim Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, JSS-ready R package implementing PCA, PLS, sPCA, and RRA factor extraction methods.

**Architecture:** All estimators return a single `sdim_fit` S3 class. Shared helpers live in `utils.R`. The `sdim()` wrapper calls all four and returns an `sdim_list`; `compare()` produces a metrics data frame.

**Tech Stack:** Base R + `stats` + `graphics` only (hard dependencies). `testthat` for tests. `devtools`/`roxygen2` for package tooling.

**Spec:** `docs/superpowers/specs/2026-04-01-sdim-design.md`

**Run all tests:** `Rscript -e 'devtools::test()'` from inside `sdim/`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `R/hello.R` | Delete | Template placeholder — remove |
| `man/hello.Rd` | Delete | Template placeholder — remove |
| `DESCRIPTION` | Modify | Fill in title, description, license, DOIs |
| `R/utils.R` | Create | `.validate_inputs`, `.as_numeric_matrix`, `.standardize_matrix`, `.winsor`, `.pc_T` |
| `R/sdim_fit.R` | Create | `print.sdim_fit`, `summary.sdim_fit`, `print.summary.sdim_fit`, `plot.sdim_fit`, `print.sdim_list` |
| `R/pca_est.R` | Create | `pca_est()` |
| `R/pls_est.R` | Create | `pls_est()` |
| `R/spca_est.R` | Modify | Refactor to return `sdim_fit`; move helpers to `utils.R` |
| `R/rra_est.R` | Create | `rra_est()` |
| `R/sdim.R` | Create | `sdim()`, `compare()` generic and methods |
| `NAMESPACE` | Modify | Switch to explicit exports via roxygen2 |
| `tests/testthat/test-utils.R` | Create | Tests for shared helpers |
| `tests/testthat/test-sdim_fit.R` | Create | Tests for S3 methods |
| `tests/testthat/test-pca_est.R` | Create | Tests for `pca_est` |
| `tests/testthat/test-pls_est.R` | Create | Tests for `pls_est` |
| `tests/testthat/test-spca_est.R` | Modify | Update for `sdim_fit` class, add matrix-target test |
| `tests/testthat/test-rra_est.R` | Create | Tests for `rra_est` |
| `tests/testthat/test-sdim.R` | Create | Tests for wrapper and `compare()` |
| `vignettes/sdim.Rmd` | Create | JSS paper vignette |
| `data-raw/make_ff_example.R` | Create | Script to generate offline fallback dataset |
| `data/ff_example.rda` | Create | Pre-processed FF data for offline vignette build |

---

## Task 1: Cleanup and DESCRIPTION

**Files:**
- Delete: `R/hello.R`
- Delete: `man/hello.Rd`
- Modify: `DESCRIPTION`

- [ ] **Step 1: Delete template files**

```bash
rm "R/hello.R" "man/hello.Rd"
```

- [ ] **Step 2: Update DESCRIPTION**

Replace the entire file with:

```
Package: sdim
Type: Package
Title: Factor Extraction via Scaled PCA and Reduced-Rank Approaches
Version: 0.1.0
Authors@R: c(
    person("YOUR", "NAME", email = "your@email.com", role = c("aut", "cre"))
  )
Description: Implements four factor extraction methods for asset pricing and
    macroeconomic forecasting: principal component analysis (PCA), partial
    least squares (PLS), scaled PCA (sPCA) of Huang, Jiang, Li, Tong, and
    Zhou (2022) <doi:10.1287/mnsc.2021.4020>, and the reduced-rank approach
    (RRA) of He, Huang, Li, and Zhou (2023) <doi:10.1287/mnsc.2022.4428>.
    Both papers are published in Management Science.
License: MIT + file LICENSE
Encoding: UTF-8
LazyData: false
Depends: R (>= 4.1.0)
Imports: stats, graphics
Suggests: frenchdata, knitr, rmarkdown, testthat (>= 3.0.0)
VignetteBuilder: knitr
RoxygenNote: 7.0.0
Config/testthat/edition: 3
```

- [ ] **Step 3: Create LICENSE file**

```
MIT License

Copyright (c) 2026 YOUR NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Verify package loads**

```bash
Rscript -e 'devtools::load_all(); cat("OK\n")'
```

Expected: `OK` with no errors.

- [ ] **Step 5: Commit**

```bash
git add DESCRIPTION LICENSE R/hello.R man/hello.Rd
git commit -m "chore: remove template files, fill DESCRIPTION"
```

---

## Task 2: Shared helpers (`utils.R`)

**Files:**
- Create: `R/utils.R`
- Create: `tests/testthat/test-utils.R`
- Modify: `R/spca_est.R` (remove helpers, keep algorithm)

- [ ] **Step 1: Write failing tests**

Create `tests/testthat/test-utils.R`:

```r
test_that(".validate_inputs coerces vector target to matrix", {
  X <- matrix(rnorm(50 * 5), 50, 5)
  y <- rnorm(50)
  out <- sdim:::.validate_inputs(y, X, 2L)
  expect_true(is.matrix(out$target))
  expect_equal(dim(out$target), c(50L, 1L))
})

test_that(".validate_inputs accepts matrix target", {
  X <- matrix(rnorm(50 * 5), 50, 5)
  Y <- matrix(rnorm(50 * 3), 50, 3)
  out <- sdim:::.validate_inputs(Y, X, 2L)
  expect_equal(dim(out$target), c(50L, 3L))
})

test_that(".validate_inputs errors on dimension mismatch", {
  X <- matrix(rnorm(50 * 5), 50, 5)
  y <- rnorm(40)
  expect_error(sdim:::.validate_inputs(y, X, 2L), "same number of rows")
})

test_that(".validate_inputs errors when nfac too large", {
  X <- matrix(rnorm(10 * 3), 10, 3)
  y <- rnorm(10)
  expect_error(sdim:::.validate_inputs(y, X, 5L), "cannot exceed")
})

test_that(".standardize_matrix centers and scales columns", {
  set.seed(1)
  X <- matrix(rnorm(100 * 4, mean = 5, sd = 2), 100, 4)
  Xs <- sdim:::.standardize_matrix(X)
  expect_equal(colMeans(Xs), rep(0, 4), tolerance = 1e-10)
  expect_equal(apply(Xs, 2, sd), rep(1, 4), tolerance = 1e-10)
})

test_that(".standardize_matrix errors on zero-variance column", {
  X <- matrix(c(rep(1, 10), rnorm(10)), 10, 2)
  expect_error(sdim:::.standardize_matrix(X), "nonzero")
})

test_that(".winsor clips at specified percentiles", {
  x <- c(1:100) * 1.0
  w <- sdim:::.winsor(x, c(5, 95))
  expect_equal(min(w), x[5])
  expect_equal(max(w), x[95])
})

test_that(".pc_T returns correct dimensions", {
  set.seed(1)
  Y <- matrix(rnorm(50 * 8), 50, 8)
  out <- sdim:::.pc_T(Y, 3L)
  expect_equal(dim(out$fhat), c(50L, 3L))
  expect_equal(dim(out$lambda), c(8L, 3L))
  expect_length(out$ve2, 50L)
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "utils")'
```

Expected: errors — functions not found.

- [ ] **Step 3: Create `R/utils.R`**

```r
# Shared internal helpers for sdim estimators.
# All functions are prefixed with a dot and not exported.

.validate_inputs <- function(target, X, nfac) {
  target <- as.matrix(target)
  X <- .as_numeric_matrix(X)

  if (nrow(X) != nrow(target))
    stop("`target` and `X` must have the same number of rows.", call. = FALSE)

  if (!is.numeric(nfac) || length(nfac) != 1L || is.na(nfac) || nfac < 1L)
    stop("`nfac` must be a positive integer.", call. = FALSE)

  nfac <- as.integer(nfac)

  if (nfac > min(nrow(X), ncol(X)))
    stop("`nfac` cannot exceed min(nrow(X), ncol(X)).", call. = FALSE)

  list(target = target, X = X, nfac = nfac)
}

.as_numeric_matrix <- function(x) {
  if (is.data.frame(x)) x <- as.matrix(x)
  if (!is.matrix(x))   stop("`X` must be a matrix or data frame.", call. = FALSE)
  if (!is.numeric(x))  stop("`X` must be numeric.", call. = FALSE)
  x
}

.standardize_matrix <- function(y) {
  y   <- as.matrix(y)
  mu  <- colMeans(y, na.rm = TRUE)
  sdv <- apply(y, 2, stats::sd, na.rm = TRUE)
  if (any(is.na(sdv) | sdv == 0))
    stop("All columns of `X` must have nonzero finite standard deviation.",
         call. = FALSE)
  out <- sweep(y, 2, mu, `-`)
  sweep(out, 2, sdv, `/`)
}

.winsor <- function(x, p) {
  if (!is.numeric(x) || length(p) != 2L)
    stop("Invalid inputs to `.winsor()`.", call. = FALSE)
  if (p[1] < 0 || p[1] > 100 || p[2] < 0 || p[2] > 100 || p[1] > p[2])
    stop("`winsor_probs` must satisfy 0 <= left <= right <= 100.", call. = FALSE)
  q  <- as.numeric(stats::quantile(x, probs = p / 100, na.rm = TRUE, type = 7))
  y  <- x
  i1 <- x < q[1];  i2 <- x > q[2]
  y[i1] <- q[1]
  y[i2] <- q[2]
  y
}

.pc_T <- function(y, nfac) {
  y    <- as.matrix(y)
  bigt <- nrow(y)
  s    <- base::svd(y %*% t(y))
  idx  <- seq_len(nfac)
  fhat <- s$u[, idx, drop = FALSE] * sqrt(bigt)
  lambda <- t(y) %*% fhat / bigt
  ehat   <- y - fhat %*% t(lambda)
  list(ehat = ehat, fhat = fhat, lambda = lambda,
       ve2 = rowMeans(ehat^2), ss = s$d[idx])
}

# Compute Q^(-1/2) via eigendecomposition (base R, no external packages).
# Q must be symmetric positive definite.
.mat_neghalf <- function(Q) {
  ev <- eigen(Q, symmetric = TRUE)
  ev$vectors %*% diag(ev$values^(-0.5), nrow = length(ev$values)) %*% t(ev$vectors)
}
```

- [ ] **Step 4: Strip helpers from `R/spca_est.R`**

Remove `.as_numeric_matrix`, `.standardize_matrix`, `.winsor`, `.pc_T` from `spca_est.R` — they now live in `utils.R`.

- [ ] **Step 5: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "utils")'
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add R/utils.R R/spca_est.R tests/testthat/test-utils.R
git commit -m "feat: extract shared helpers into utils.R"
```

---

## Task 3: `sdim_fit` S3 class

**Files:**
- Create: `R/sdim_fit.R`
- Create: `tests/testthat/test-sdim_fit.R`

- [ ] **Step 1: Write failing tests**

Create `tests/testthat/test-sdim_fit.R`:

```r
# Helper: minimal valid sdim_fit object
make_fit <- function(method = "pca", nfac = 2L, T = 30L, N = 5L, L = 4L) {
  factors   <- matrix(rnorm(T * nfac), T, nfac)
  lambda    <- matrix(rnorm(L * nfac), L, nfac)
  residuals <- matrix(rnorm(T * N),   T, N)
  structure(
    list(method = method, factors = factors, lambda = lambda,
         residuals = residuals, eigvals = c(3.0, 1.5)[seq_len(nfac)],
         ve2 = rowMeans(residuals^2), call = quote(test()),
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         gmm_stat = NULL, pls_weights = NULL, gamma = NULL),
    class = "sdim_fit"
  )
}

test_that("print.sdim_fit returns x invisibly", {
  fit <- make_fit()
  out <- capture.output(ret <- print(fit))
  expect_identical(ret, fit)
  expect_true(any(grepl("pca", out, ignore.case = TRUE)))
})

test_that("summary.sdim_fit returns summary.sdim_fit object", {
  fit <- make_fit()
  s   <- summary(fit)
  expect_s3_class(s, "summary.sdim_fit")
  expect_equal(s$n_obs,  30L)
  expect_equal(s$n_pred, 4L)
  expect_equal(s$n_fac,  2L)
})

test_that("print.summary.sdim_fit runs without error", {
  fit <- make_fit()
  expect_output(print(summary(fit)), "Model size")
})

test_that("plot.sdim_fit runs without error using base graphics", {
  fit <- make_fit(nfac = 2L, T = 20L)
  expect_no_error(plot(fit))
})

test_that("plot.sdim_fit accepts index argument", {
  fit   <- make_fit(nfac = 1L, T = 20L)
  idx   <- seq(as.Date("2000-01-01"), by = "month", length.out = 20)
  expect_no_error(plot(fit, index = idx))
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "sdim_fit")'
```

Expected: errors — class methods not found.

- [ ] **Step 3: Create `R/sdim_fit.R`**

```r
#' @export
print.sdim_fit <- function(x, ...) {
  cat(sprintf("<sdim_fit [%s]>\n", x$method))
  cat(" Observations :", nrow(x$factors), "\n")
  cat(" Predictors   :", nrow(x$lambda),  "\n")
  cat(" Factors      :", ncol(x$factors), "\n")
  invisible(x)
}

#' @export
summary.sdim_fit <- function(object, ...) {
  out <- list(
    call    = object$call,
    method  = object$method,
    n_obs   = nrow(object$factors),
    n_pred  = nrow(object$lambda),
    n_fac   = ncol(object$factors),
    eigvals = object$eigvals
  )
  if (!is.null(object$beta))
    out$beta_summary <- stats::quantile(object$beta, probs = c(0, .25, .5, .75, 1))
  if (!is.null(object$gmm_stat))
    out$gmm_stat <- object$gmm_stat
  class(out) <- "summary.sdim_fit"
  out
}

#' @export
print.summary.sdim_fit <- function(x, ...) {
  cat("Call:\n"); print(x$call)
  cat("\nModel size:\n")
  cat(" Observations :", x$n_obs,  "\n")
  cat(" Predictors   :", x$n_pred, "\n")
  cat(" Factors      :", x$n_fac,  "\n")
  cat("\nLeading eigenvalues:\n"); print(x$eigvals)
  if (!is.null(x$beta_summary)) {
    cat("\nSlope summary (sPCA):\n"); print(x$beta_summary)
  }
  if (!is.null(x$gmm_stat)) {
    cat(sprintf("\nGMM statistic (RRA): %.4f  p-value: %.4f\n",
                x$gmm_stat$stat, x$gmm_stat$pvalue))
  }
  invisible(x)
}

#' @export
plot.sdim_fit <- function(x, index = NULL, ...) {
  K   <- ncol(x$factors)
  T   <- nrow(x$factors)
  idx <- if (is.null(index)) seq_len(T) else index
  op  <- graphics::par(mfrow = c(K, 1), mar = c(3, 4, 2, 1))
  on.exit(graphics::par(op))
  for (k in seq_len(K)) {
    graphics::plot(idx, x$factors[, k], type = "l",
                   ylab = paste0("F", k), xlab = "")
    graphics::title(main = sprintf("%s — Factor %d", toupper(x$method), k))
  }
  invisible(x)
}

#' @export
print.sdim_list <- function(x, ...) {
  cat(sprintf("<sdim_list: %d method(s)>\n\n", length(x)))
  methods <- names(x)
  header  <- sprintf("%-8s %6s %6s %6s %12s", "method", "T", "N", "nfac", "eigval[1]")
  cat(header, "\n")
  cat(strrep("-", nchar(header)), "\n")
  for (m in methods) {
    fit <- x[[m]]
    cat(sprintf("%-8s %6d %6d %6d %12.4f\n",
                m,
                nrow(fit$factors),
                ncol(fit$residuals),
                ncol(fit$factors),
                fit$eigvals[1]))
  }
  invisible(x)
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "sdim_fit")'
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add R/sdim_fit.R tests/testthat/test-sdim_fit.R
git commit -m "feat: add sdim_fit S3 class with print, summary, plot methods"
```

---

## Task 4: `pca_est()`

**Files:**
- Create: `R/pca_est.R`
- Create: `tests/testthat/test-pca_est.R`

- [ ] **Step 1: Write failing tests**

Create `tests/testthat/test-pca_est.R`:

```r
test_that("pca_est returns sdim_fit with correct dimensions", {
  set.seed(1)
  X <- matrix(rnorm(60 * 6), 60, 6)
  fit <- pca_est(X = X, nfac = 3L)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "pca")
  expect_equal(dim(fit$factors), c(60L, 3L))
  expect_equal(dim(fit$lambda),  c(6L,  3L))
  expect_length(fit$eigvals, 3L)
})

test_that("pca_est factors are orthogonal", {
  set.seed(2)
  X   <- matrix(rnorm(80 * 8), 80, 8)
  fit <- pca_est(X = X, nfac = 3L)
  FtF <- crossprod(fit$factors)
  off_diag <- FtF[upper.tri(FtF)]
  expect_equal(off_diag, rep(0, 3), tolerance = 1e-8)
})

test_that("pca_est gamma parameter changes factors", {
  set.seed(3)
  X    <- matrix(rnorm(50 * 5), 50, 5)
  fit1 <- pca_est(X = X, nfac = 2L, gamma = -1)
  fit2 <- pca_est(X = X, nfac = 2L, gamma = 10)
  expect_false(isTRUE(all.equal(fit1$factors, fit2$factors)))
})

test_that("pca_est accepts NULL target without error", {
  set.seed(4)
  X <- matrix(rnorm(40 * 4), 40, 4)
  expect_no_error(pca_est(target = NULL, X = X, nfac = 2L))
})

test_that("pca_est ve2 and residuals are consistent", {
  set.seed(5)
  X   <- matrix(rnorm(50 * 5), 50, 5)
  fit <- pca_est(X = X, nfac = 2L)
  expect_equal(fit$ve2, rowMeans(fit$residuals^2))
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "pca_est")'
```

- [ ] **Step 3: Create `R/pca_est.R`**

```r
#' PCA factor extraction
#'
#' @param target Ignored; accepted for API uniformity with other estimators.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of factors to extract.
#' @param gamma Numeric scalar controlling mean adjustment in the second-moment
#'   matrix. `gamma = -1` (default) gives the sample covariance (traditional
#'   PCA). `gamma = 10` and `gamma = 1` give the Lettau-Ludvigson variants
#'   from He et al. (2023).
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references He, Huang, Li, Zhou (2023) \doi{10.1287/mnsc.2022.4428}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' fit <- pca_est(X = X, nfac = 3)
#' print(fit)
#' @export
pca_est <- function(target = NULL, X, nfac, gamma = -1) {
  # Use a dummy single-column target when NULL so .validate_inputs can run
  X_chk <- .as_numeric_matrix(X)
  if (is.null(target)) target <- matrix(0, nrow(X_chk), 1L)
  inp   <- .validate_inputs(target, X, nfac)
  G     <- inp$X
  K     <- inp$nfac
  T_obs <- nrow(G)

  mu <- colMeans(G)
  C  <- crossprod(G) / T_obs + gamma * outer(mu, mu)

  ev  <- eigen(C, symmetric = TRUE)
  ord <- order(ev$values, decreasing = TRUE)
  E_k <- ev$vectors[, ord[seq_len(K)], drop = FALSE]
  factors   <- G %*% E_k                          # T x K
  lambda    <- crossprod(G, factors) / T_obs       # L x K  (G-space loadings)
  # G-space residuals: G - factors %*% t(lambda) is T x L for all methods
  residuals <- G - tcrossprod(factors, t(lambda))
  ve2       <- rowMeans(residuals^2)
  eigvals   <- ev$values[ord[seq_len(K)]]

  structure(
    list(method = "pca", factors = factors, lambda = lambda,
         residuals = residuals, eigvals = eigvals, ve2 = ve2,
         call = match.call(), gamma = gamma,
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         gmm_stat = NULL, pls_weights = NULL),
    class = "sdim_fit"
  )
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "pca_est")'
```

- [ ] **Step 5: Commit**

```bash
git add R/pca_est.R tests/testthat/test-pca_est.R
git commit -m "feat: add pca_est() returning sdim_fit"
```

---

## Task 5: `pls_est()`

**Files:**
- Create: `R/pls_est.R`
- Create: `tests/testthat/test-pls_est.R`

- [ ] **Step 1: Write failing tests**

Create `tests/testthat/test-pls_est.R`:

```r
test_that("pls_est returns sdim_fit with correct dimensions", {
  set.seed(1)
  X   <- matrix(rnorm(60 * 6), 60, 6)
  Y   <- matrix(rnorm(60 * 4), 60, 4)
  fit <- pls_est(target = Y, X = X, nfac = 2L)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "pls")
  expect_equal(dim(fit$factors),     c(60L, 2L))
  expect_equal(dim(fit$lambda),      c(6L,  2L))
  expect_equal(dim(fit$pls_weights), c(6L,  2L))
  expect_length(fit$eigvals, 2L)
})

test_that("pls_est first factor maximises covariance with target", {
  # The first PLS component maximises cov(t, Y) over unit-norm X-weights.
  # Check: the covariance from fit >= covariance from a random weight.
  set.seed(2)
  X   <- matrix(rnorm(80 * 5), 80, 5)
  Y   <- matrix(rnorm(80 * 3), 80, 3)
  fit <- pls_est(target = Y, X = X, nfac = 1L)
  t1  <- fit$factors[, 1]
  cov_pls    <- sum(abs(cov(t1, Y)))
  set.seed(99)
  w_rand <- rnorm(5); w_rand <- w_rand / sqrt(sum(w_rand^2))
  t_rand <- X %*% w_rand
  cov_rand   <- sum(abs(cov(t_rand, Y)))
  expect_gt(cov_pls, cov_rand)
})

test_that("pls_est eigvals are positive", {
  set.seed(3)
  X   <- matrix(rnorm(50 * 4), 50, 4)
  Y   <- matrix(rnorm(50 * 3), 50, 3)
  fit <- pls_est(target = Y, X = X, nfac = 2L)
  expect_true(all(fit$eigvals > 0))
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "pls_est")'
```

- [ ] **Step 3: Create `R/pls_est.R`**

```r
#' PLS factor extraction (NIPALS algorithm)
#'
#' @param target Numeric matrix (T x N) of target variables (e.g., asset
#'   returns). A vector is coerced to a T x 1 matrix.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of PLS components to extract.
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references He, Huang, Li, Zhou (2023) \doi{10.1287/mnsc.2022.4428}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' Y <- matrix(rnorm(100 * 5), 100, 5)
#' fit <- pls_est(target = Y, X = X, nfac = 3)
#' print(fit)
#' @export
pls_est <- function(target, X, nfac) {
  inp   <- .validate_inputs(target, X, nfac)
  G     <- inp$X
  R     <- inp$target
  K     <- inp$nfac
  T_obs <- nrow(G)
  L     <- ncol(G)

  G_orig <- G
  G_defl <- G
  R_defl <- R

  factors <- matrix(0, T_obs, K)
  weights <- matrix(0, L,     K)

  for (k in seq_len(K)) {
    S    <- crossprod(G_defl, R_defl)          # L x N
    sv   <- svd(S, nu = 0, nv = 1)
    w_k  <- sv$v[, 1L]                         # L x 1
    t_k  <- G_defl %*% w_k                     # T x 1
    tt   <- drop(crossprod(t_k))
    G_defl <- G_defl - tcrossprod(t_k) %*% G_defl / tt
    R_defl <- R_defl - tcrossprod(t_k) %*% R_defl / tt
    factors[, k] <- t_k
    weights[, k] <- w_k
  }

  lambda    <- crossprod(G_orig, factors) / T_obs   # L x K (G-space loadings)
  # G-space residuals (T x L) — consistent with pca_est and rra_est
  residuals <- G_orig - tcrossprod(factors, t(lambda))
  ve2       <- rowMeans(residuals^2)
  eigvals   <- colSums(factors^2)   # squared L2-norm of each score vector

  structure(
    list(method = "pls", factors = factors, lambda = lambda,
         residuals = residuals, eigvals = eigvals, ve2 = ve2,
         call = match.call(), pls_weights = weights,
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         gmm_stat = NULL, gamma = NULL),
    class = "sdim_fit"
  )
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "pls_est")'
```

- [ ] **Step 5: Commit**

```bash
git add R/pls_est.R tests/testthat/test-pls_est.R
git commit -m "feat: add pls_est() via NIPALS algorithm"
```

---

## Task 6: Refactor `spca_est()`

**Files:**
- Modify: `R/spca_est.R`
- Modify: `tests/testthat/test-spca_est.R`

- [ ] **Step 1: Update tests for new class and matrix target**

Replace `tests/testthat/test-spca_est.R`:

```r
test_that("spca_est returns sdim_fit (not sdim_spca)", {
  set.seed(1)
  X   <- matrix(rnorm(100 * 8), 100, 8)
  y   <- rnorm(100)
  fit <- spca_est(target = y, X = X, nfac = 3L)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "spca")
})

test_that("spca_est dimensions are correct", {
  set.seed(1)
  X   <- matrix(rnorm(100 * 8), 100, 8)
  y   <- rnorm(100)
  fit <- spca_est(target = y, X = X, nfac = 3L)
  expect_equal(dim(fit$factors), c(100L, 3L))
  expect_length(fit$beta, 8L)
  expect_equal(dim(fit$lambda), c(8L, 3L))
  expect_equal(dim(fit$Xs),      c(100L, 8L))
  expect_equal(dim(fit$scaleXs), c(100L, 8L))
})

test_that("spca_est winsorize changes beta_scaled but not beta", {
  set.seed(2)
  X   <- matrix(rnorm(100 * 8), 100, 8)
  y   <- rnorm(100)
  fit_w  <- spca_est(y, X, 2L, winsorize = TRUE,  winsor_probs = c(5, 95))
  fit_nw <- spca_est(y, X, 2L, winsorize = FALSE)
  expect_equal(fit_w$beta, fit_nw$beta)
  # beta_scaled may differ when extreme slopes exist
})

test_that("spca_est accepts matrix target (averages slopes)", {
  set.seed(3)
  X   <- matrix(rnorm(60 * 5), 60, 5)
  Y   <- matrix(rnorm(60 * 3), 60, 3)
  expect_no_error(spca_est(target = Y, X = X, nfac = 2L))
  fit <- spca_est(target = Y, X = X, nfac = 2L)
  expect_length(fit$beta, 5L)
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "spca_est")'
```

Expected: `expect_s3_class(fit, "sdim_fit")` fails because current class is `sdim_spca`; matrix-target test errors because current code calls `as.numeric(target)` which drops the matrix.

- [ ] **Step 3: Refactor `R/spca_est.R`**

```r
#' Scaled PCA factor extraction
#'
#' Implements scaled principal component analysis (sPCA): predictors are
#' standardized, each is scaled by its univariate predictive slope on the
#' target, and principal components are extracted from the scaled predictors.
#'
#' When \code{target} is a T x N matrix, slopes are computed for each column
#' and averaged element-wise before scaling — a practical extension of the
#' original univariate formulation.
#'
#' @param target Numeric vector (T) or matrix (T x N). For a single target
#'   use a vector; for multivariate use a matrix.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of factors to extract.
#' @param winsorize Logical; if \code{TRUE}, winsorize absolute slope estimates
#'   before scaling.
#' @param winsor_probs Numeric vector of length 2 giving percentile bounds
#'   (0–100 scale). Used only when \code{winsorize = TRUE}.
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references Huang, Jiang, Li, Tong, Zhou (2022) \doi{10.1287/mnsc.2021.4020}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' y <- rnorm(100)
#' fit <- spca_est(target = y, X = X, nfac = 3)
#' print(fit)
#' @export
spca_est <- function(target, X, nfac,
                     winsorize = FALSE, winsor_probs = c(0, 99)) {
  inp  <- .validate_inputs(target, X, nfac)
  R    <- inp$target    # T x N (N=1 for vector input)
  G    <- inp$X
  K    <- inp$nfac
  Xs   <- .standardize_matrix(G)

  # Compute slopes for each column of R, then average
  beta_mat <- vapply(seq_len(ncol(R)), function(j) {
    vapply(seq_len(ncol(Xs)), function(i) {
      unname(stats::lm.fit(cbind(1, Xs[, i]), R[, j])$coefficients[2])
    }, numeric(1))
  }, numeric(ncol(Xs)))

  beta <- if (is.matrix(beta_mat)) rowMeans(beta_mat) else beta_mat

  beta_scaled <- beta
  if (isTRUE(winsorize))
    beta_scaled <- sign(beta) * .winsor(abs(beta), winsor_probs)

  scaleXs  <- sweep(Xs, 2, beta_scaled, `*`)
  pc_out   <- .pc_T(scaleXs, K)

  residuals <- pc_out$ehat
  ve2       <- pc_out$ve2

  structure(
    list(method = "spca", factors = pc_out$fhat, lambda = pc_out$lambda,
         residuals = residuals, eigvals = pc_out$ss, ve2 = ve2,
         call = match.call(), beta = beta, beta_scaled = beta_scaled,
         Xs = Xs, scaleXs = scaleXs,
         gmm_stat = NULL, pls_weights = NULL, gamma = NULL),
    class = "sdim_fit"
  )
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "spca_est")'
```

- [ ] **Step 5: Commit**

```bash
git add R/spca_est.R tests/testthat/test-spca_est.R
git commit -m "refactor: spca_est returns sdim_fit; support matrix target"
```

---

## Task 7: `rra_est()`

**Files:**
- Create: `R/rra_est.R`
- Create: `tests/testthat/test-rra_est.R`

- [ ] **Step 1: Write failing tests**

Create `tests/testthat/test-rra_est.R`:

```r
test_that("rra_est returns sdim_fit with correct dimensions", {
  set.seed(1)
  X   <- matrix(rnorm(60 * 6), 60, 6)
  Y   <- matrix(rnorm(60 * 5), 60, 5)
  fit <- rra_est(target = Y, X = X, nfac = 2L)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "rra")
  expect_equal(dim(fit$factors), c(60L, 2L))
  expect_equal(dim(fit$lambda),  c(6L,  2L))
  expect_length(fit$eigvals, 2L)
})

test_that("rra_est gmm_stat has stat and pvalue", {
  set.seed(2)
  X   <- matrix(rnorm(50 * 5), 50, 5)
  Y   <- matrix(rnorm(50 * 4), 50, 4)
  fit <- rra_est(target = Y, X = X, nfac = 1L)
  expect_named(fit$gmm_stat, c("stat", "pvalue"))
  expect_true(fit$gmm_stat$pvalue >= 0 && fit$gmm_stat$pvalue <= 1)
})

test_that("rra_est restrict = TRUE requires alpha_bound", {
  set.seed(3)
  X <- matrix(rnorm(40 * 4), 40, 4)
  Y <- matrix(rnorm(40 * 3), 40, 3)
  expect_error(rra_est(Y, X, 1L, restrict = TRUE), "alpha_bound")
})

test_that("rra_est restrict = TRUE runs with valid alpha_bound", {
  set.seed(4)
  X <- matrix(rnorm(50 * 5), 50, 5)
  Y <- matrix(rnorm(50 * 4), 50, 4)
  expect_no_error(rra_est(Y, X, 2L, restrict = TRUE, alpha_bound = rep(0, 4)))
})

test_that("rra_est residuals are G-space (T x L)", {
  set.seed(5)
  X   <- matrix(rnorm(40 * 4), 40, 4)
  Y   <- matrix(rnorm(40 * 3), 40, 3)
  fit <- rra_est(target = Y, X = X, nfac = 1L)
  # residuals are in G-space (T x L), consistent with all other methods
  expect_equal(dim(fit$residuals), c(40L, 4L))
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "rra_est")'
```

- [ ] **Step 3: Create `R/rra_est.R`**

```r
#' RRA factor extraction (Reduced-Rank Approach)
#'
#' Implements the two-step iteratively re-weighted GMM of He et al. (2023).
#' In step 1, identity weighting matrices are used to obtain preliminary
#' factors and residuals. In step 2, the weighting matrices are updated to
#' the inverse diagonal residual covariances and the estimation is repeated.
#'
#' @param target Numeric matrix (T x N) of target asset returns.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of factors to extract.
#' @param restrict Logical; if \code{TRUE}, use the pricing-error restricted
#'   variant (pre-specified intercepts; no Frisch-Waugh annihilation).
#' @param alpha_bound Numeric vector of length N giving pre-specified pricing
#'   errors. Required when \code{restrict = TRUE}.
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references He, Huang, Li, Zhou (2023) \doi{10.1287/mnsc.2022.4428}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' Y <- matrix(rnorm(100 * 5), 100, 5)
#' fit <- rra_est(target = Y, X = X, nfac = 3)
#' print(fit)
#' @export
rra_est <- function(target, X, nfac, restrict = FALSE, alpha_bound = NULL) {
  inp   <- .validate_inputs(target, X, nfac)
  R_orig <- inp$target
  G      <- inp$X
  K      <- inp$nfac
  T_obs  <- nrow(G)
  L      <- ncol(G)
  N      <- ncol(R_orig)

  if (isTRUE(restrict)) {
    if (is.null(alpha_bound) || length(alpha_bound) != N)
      stop("`alpha_bound` must be a numeric vector of length ncol(target) ",
           "when restrict = TRUE.", call. = FALSE)
    R <- R_orig - matrix(alpha_bound, T_obs, N, byrow = TRUE)
  } else {
    R <- R_orig
  }

  Z     <- cbind(1, G)           # T x (L+1)
  X_int <- matrix(1, T_obs, 1)  # T x 1
  annihilate <- !restrict

  # One GMM step: given W1 (N x N), W2 ((L+1) x (L+1)), return Phi and eigvals
  .gmm_step <- function(W1, W2) {
    P0 <- Z %*% W2 %*% t(Z)                                  # T x T
    if (annihilate) {
      XtP0X <- drop(crossprod(X_int, P0 %*% X_int))
      P <- P0 - (P0 %*% X_int) %*% (t(X_int) %*% P0) / XtP0X
    } else {
      P <- P0
    }
    Q        <- crossprod(G, P %*% G) / T_obs^2              # L x L
    Q_nh     <- .mat_neghalf(Q)                              # Q^(-1/2)
    GtPR     <- crossprod(G, P %*% R) / T_obs^2             # L x N
    A        <- t(Q_nh) %*% GtPR %*% W1 %*% t(GtPR) %*% Q_nh  # L x L
    ea       <- eigen(A, symmetric = TRUE)
    ord      <- order(ea$values, decreasing = TRUE)
    Phi      <- Q_nh %*% ea$vectors[, ord[seq_len(K)], drop = FALSE]
    list(Phi = Phi, eigvals = ea$values[ord], P0 = P0, P = P)
  }

  # Step 1 — identity weights
  step1 <- .gmm_step(diag(N), diag(L + 1L))
  Phi1  <- step1$Phi
  Gstar <- G %*% Phi1                                         # T x K
  Beta  <- solve(crossprod(Gstar, step1$P %*% Gstar),
                 crossprod(Gstar, step1$P %*% R))             # K x N
  Theta <- Phi1 %*% Beta                                      # L x N
  XtP0X <- drop(crossprod(X_int, step1$P0 %*% X_int))
  Alpha_hat <- t(crossprod(X_int, step1$P0 %*% (R - G %*% Theta)) / XtP0X) # N x 1
  U     <- R - X_int %*% t(Alpha_hat) - G %*% Theta          # T x N
  S1    <- diag(diag(crossprod(U)  / T_obs))                  # N x N diagonal
  S2    <- diag(diag(crossprod(Z)  / T_obs))                  # (L+1) x (L+1)

  # Step 2 — updated weights
  step2   <- .gmm_step(solve(S1), solve(S2))
  factors <- G %*% step2$Phi                                  # T x K

  lambda    <- crossprod(G, factors) / T_obs      # L x K (G-space loadings)
  # G-space residuals (T x L) — consistent with pca_est, pls_est, spca_est
  residuals <- G - tcrossprod(factors, t(lambda))
  ve2       <- rowMeans(residuals^2)
  eigvals   <- step2$eigvals[seq_len(K)]
  gmm_stat  <- list(stat   = eigvals[1],
                    pvalue = stats::pchisq(eigvals[1], df = N - K,
                                           lower.tail = FALSE))

  structure(
    list(method = "rra", factors = factors, lambda = lambda,
         residuals = residuals, eigvals = eigvals, ve2 = ve2,
         call = match.call(), gmm_stat = gmm_stat,
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         pls_weights = NULL, gamma = NULL),
    class = "sdim_fit"
  )
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "rra_est")'
```

- [ ] **Step 5: Commit**

```bash
git add R/rra_est.R tests/testthat/test-rra_est.R
git commit -m "feat: add rra_est() two-step GMM estimator"
```

---

## Task 8: `sdim()` wrapper and `compare()`

**Files:**
- Create: `R/sdim.R`
- Create: `tests/testthat/test-sdim.R`

- [ ] **Step 1: Write failing tests**

Create `tests/testthat/test-sdim.R`:

```r
test_that("sdim returns sdim_list with all four methods", {
  set.seed(1)
  X   <- matrix(rnorm(60 * 6), 60, 6)
  Y   <- matrix(rnorm(60 * 5), 60, 5)
  out <- sdim(target = Y, X = X, nfac = 2L)
  expect_s3_class(out, "sdim_list")
  expect_named(out, c("rra", "spca", "pls", "pca"))
  for (m in names(out)) expect_s3_class(out[[m]], "sdim_fit")
})

test_that("sdim respects methods argument", {
  set.seed(2)
  X   <- matrix(rnorm(50 * 5), 50, 5)
  Y   <- matrix(rnorm(50 * 3), 50, 3)
  out <- sdim(Y, X, 2L, methods = c("pca", "pls"))
  expect_named(out, c("pca", "pls"))
})

test_that("sdim passes pca_args to pca_est", {
  set.seed(3)
  X    <- matrix(rnorm(50 * 5), 50, 5)
  Y    <- matrix(rnorm(50 * 3), 50, 3)
  out1 <- sdim(Y, X, 2L, methods = "pca", pca_args = list(gamma = -1))
  out2 <- sdim(Y, X, 2L, methods = "pca", pca_args = list(gamma = 10))
  expect_false(isTRUE(all.equal(out1$pca$factors, out2$pca$factors)))
})

test_that("compare returns data frame with correct structure", {
  set.seed(4)
  X   <- matrix(rnorm(60 * 5), 60, 5)
  Y   <- matrix(rnorm(60 * 4), 60, 4)
  out <- sdim(Y, X, 2L)
  cmp <- compare(out)
  expect_s3_class(cmp, "data.frame")
  expect_named(cmp, c("method", "r2", "mape", "rmse"))
  expect_equal(nrow(cmp), 4L)
})

test_that("compare works on plain named list of sdim_fit", {
  set.seed(5)
  X   <- matrix(rnorm(50 * 5), 50, 5)
  Y   <- matrix(rnorm(50 * 3), 50, 3)
  lst <- list(pca = pca_est(Y, X, 2L), pls = pls_est(Y, X, 2L))
  expect_no_error(compare(lst))
})

test_that("compare r2 is not greater than 1", {
  set.seed(6)
  X   <- matrix(rnorm(60 * 5), 60, 5)
  Y   <- matrix(rnorm(60 * 4), 60, 4)
  cmp <- compare(sdim(Y, X, 2L))
  expect_true(all(cmp$r2 <= 1))
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
Rscript -e 'devtools::test(filter = "sdim")'
```

- [ ] **Step 3: Create `R/sdim.R`**

```r
#' Run all four factor extraction methods
#'
#' Convenience wrapper that calls \code{\link{pca_est}}, \code{\link{pls_est}},
#' \code{\link{spca_est}}, and \code{\link{rra_est}} and returns all results
#' as a named list.
#'
#' @param target Numeric vector or matrix (T x N).
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of factors to extract.
#' @param methods Character vector; subset of
#'   \code{c("rra", "spca", "pls", "pca")}. Defaults to all four.
#' @param pca_args  Named list of additional arguments passed to
#'   \code{pca_est}.
#' @param pls_args  Named list of additional arguments passed to
#'   \code{pls_est}.
#' @param spca_args Named list of additional arguments passed to
#'   \code{spca_est}.
#' @param rra_args  Named list of additional arguments passed to
#'   \code{rra_est}.
#'
#' @return A named list of class \code{"sdim_list"} with one \code{sdim_fit}
#'   element per requested method.
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' Y <- matrix(rnorm(100 * 5), 100, 5)
#' out <- sdim(target = Y, X = X, nfac = 3)
#' print(out)
#' compare(out)
#' @export
sdim <- function(target, X, nfac,
                 methods   = c("rra", "spca", "pls", "pca"),
                 pca_args  = list(),
                 pls_args  = list(),
                 spca_args = list(),
                 rra_args  = list()) {

  known <- c("rra", "spca", "pls", "pca")
  bad   <- setdiff(methods, known)
  if (length(bad))
    stop("Unknown method(s): ", paste(bad, collapse = ", "),
         ". Must be one of: ", paste(known, collapse = ", "), ".", call. = FALSE)

  estimators <- list(
    pca  = function() do.call(pca_est,  c(list(target = target, X = X, nfac = nfac), pca_args)),
    pls  = function() do.call(pls_est,  c(list(target = target, X = X, nfac = nfac), pls_args)),
    spca = function() do.call(spca_est, c(list(target = target, X = X, nfac = nfac), spca_args)),
    rra  = function() do.call(rra_est,  c(list(target = target, X = X, nfac = nfac), rra_args))
  )

  results <- lapply(methods, function(m) estimators[[m]]())
  names(results) <- methods
  structure(results, class = c("sdim_list", "list"))
}

#' Compare factor extraction methods
#'
#' Computes in-sample fit metrics across a set of \code{sdim_fit} objects.
#'
#' @param x An \code{sdim_list} (output of \code{\link{sdim}}) or a named
#'   list of \code{sdim_fit} objects.
#' @param metrics Character vector; subset of \code{c("r2", "mape", "rmse")}.
#' @param ... Ignored.
#'
#' @return A data frame with one row per method.
#' @examples
#' set.seed(1)
#' X   <- matrix(rnorm(100 * 8), 100, 8)
#' Y   <- matrix(rnorm(100 * 5), 100, 5)
#' out <- sdim(target = Y, X = X, nfac = 3)
#' compare(out)
#' @export
compare <- function(x, ...) UseMethod("compare")

#' @export
compare.sdim_list <- function(x, metrics = c("r2", "mape", "rmse"), ...) {
  .compare_impl(x, metrics)
}

#' @export
compare.list <- function(x, metrics = c("r2", "mape", "rmse"), ...) {
  if (!all(vapply(x, inherits, logical(1), "sdim_fit")))
    stop("All elements of `x` must be `sdim_fit` objects.", call. = FALSE)
  .compare_impl(x, metrics)
}

#' @export
compare.default <- function(x, ...) {
  stop("`x` must be an `sdim_list` or a named list of `sdim_fit` objects.",
       call. = FALSE)
}

# All sdim_fit objects store G-space (T x L) residuals, so compare() is
# always dimensionally consistent without needing to reconstruct the target.
# R² = fraction of G's column-demeaned variation explained by the factors.
.compare_impl <- function(fits, metrics) {
  rows <- lapply(names(fits), function(m) {
    fit   <- fits[[m]]
    resid <- fit$residuals                             # T x L
    recon <- tcrossprod(fit$factors, t(fit$lambda))    # T x L
    G_hat <- recon + resid                             # T x L (= original G)
    ss_res <- sum(resid^2)
    ss_tot <- sum(sweep(G_hat, 2, colMeans(G_hat))^2)
    r2   <- 1 - ss_res / ss_tot
    mape <- mean(abs(resid))
    rmse <- sqrt(mean(resid^2))
    row  <- data.frame(method = m, stringsAsFactors = FALSE)
    if ("r2"   %in% metrics) row$r2   <- r2
    if ("mape" %in% metrics) row$mape <- mape
    if ("rmse" %in% metrics) row$rmse <- rmse
    row
  })
  do.call(rbind, rows)
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
Rscript -e 'devtools::test(filter = "sdim")'
```

- [ ] **Step 5: Commit**

```bash
git add R/sdim.R tests/testthat/test-sdim.R
git commit -m "feat: add sdim() wrapper and compare() generic"
```

---

## Task 9: NAMESPACE and documentation

**Files:**
- Modify: `NAMESPACE`
- Modify: `R/*.R` (ensure all roxygen2 tags are correct)

- [ ] **Step 1: Run `devtools::document()`**

```bash
Rscript -e 'devtools::document()'
```

Expected: `NAMESPACE` regenerated, `.Rd` files created in `man/`.

- [ ] **Step 2: Check NAMESPACE contains all required entries**

Open `NAMESPACE` and verify these lines are present:

```
export(compare)
export(pca_est)
export(pls_est)
export(rra_est)
export(sdim)
export(spca_est)
S3method(compare,default)
S3method(compare,list)
S3method(compare,sdim_list)
S3method(plot,sdim_fit)
S3method(print,sdim_fit)
S3method(print,sdim_list)
S3method(print,summary.sdim_fit)
S3method(summary,sdim_fit)
importFrom(graphics,lines)
importFrom(graphics,mtext)
importFrom(graphics,par)
importFrom(graphics,plot)
importFrom(graphics,title)
importFrom(stats,cov)
importFrom(stats,lm.fit)
importFrom(stats,pchisq)
importFrom(stats,quantile)
importFrom(stats,sd)
```

- [ ] **Step 3: Run full test suite**

```bash
Rscript -e 'devtools::test()'
```

Expected: all tests pass, 0 failures.

- [ ] **Step 4: Run `R CMD check`**

```bash
Rscript -e 'devtools::check()'
```

Expected: 0 errors, 0 warnings. Fix any NOTEs about missing `@importFrom` declarations by adding them to the relevant function's roxygen block.

- [ ] **Step 5: Commit**

```bash
git add NAMESPACE man/
git commit -m "docs: regenerate NAMESPACE and man pages via roxygen2"
```

---

## Task 10: Vignette

**Files:**
- Create: `vignettes/sdim.Rmd`
- Create: `data/ff_example.rda` (offline fallback data)
- Modify: `DESCRIPTION` (confirm `VignetteBuilder: knitr`)

- [ ] **Step 1: Create `data-raw/make_ff_example.R`**

```bash
mkdir -p data-raw data
```

Create `data-raw/make_ff_example.R` with the following content:

```r
set.seed(42)
ff_example <- list(
  X = matrix(rnorm(120 * 6), 120, 6,
             dimnames = list(NULL, c("Mkt.RF","SMB","HML","RMW","CMA","Mom"))),
  Y = matrix(rnorm(120 * 5), 120, 5,
             dimnames = list(NULL, paste0("P", 1:5))),
  description = "Simulated Fama-French style data for offline vignette builds."
)
save(ff_example, file = "data/ff_example.rda", compress = "xz")
cat("Saved data/ff_example.rda\n")
```

Then run it:

```bash
Rscript data-raw/make_ff_example.R
```

Expected: `Saved data/ff_example.rda`.

- [ ] **Step 2: Create `vignettes/sdim.Rmd`**

Create the file with this skeleton (fill in the mathematical details from the two source papers):

````markdown
---
title: "Factor Extraction via Scaled PCA and Reduced-Rank Approaches"
author: "YOUR NAME"
output:
  rmarkdown::html_vignette:
    toc: true
vignette: >
  %\VignetteIndexEntry{Factor Extraction via Scaled PCA and Reduced-Rank Approaches}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r setup, include = FALSE}
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(sdim)
```

## Introduction

[Describe the two papers and the motivation for the package.]

## Methods

### Principal Component Analysis (PCA)
[Math from He et al. 2023]

### Partial Least Squares (PLS)
[Math from He et al. 2023]

### Scaled PCA (sPCA)
[Math from Huang et al. 2022, doi:10.1287/mnsc.2021.4020]

### Reduced-Rank Approach (RRA)
[Math from He et al. 2023, doi:10.1287/mnsc.2022.4428]

## Package Overview

```{r api-example}
set.seed(1)
X <- matrix(rnorm(100 * 6), 100, 6)
Y <- matrix(rnorm(100 * 4), 100, 4)

fit_rra <- rra_est(target = Y, X = X, nfac = 2)
print(fit_rra)
summary(fit_rra)
```

## Simulation Study

```{r simulation}
set.seed(123)
T <- 200; L <- 20; N <- 10; K <- 3

Lambda_true <- matrix(rnorm(L * K), L, K)
F_true      <- matrix(rnorm(T * K), T, K)
E           <- matrix(rnorm(T * L, sd = 0.5), T, L)
X_sim       <- F_true %*% t(Lambda_true) + E

B_true      <- matrix(rnorm(K * N), K, N)
eps         <- matrix(rnorm(T * N, sd = 0.3), T, N)
Y_sim       <- F_true %*% B_true + eps

out <- sdim(target = Y_sim, X = X_sim, nfac = K)
compare(out)
```

## Real Data Application

```{r real-data, eval = requireNamespace("frenchdata", quietly = TRUE)}
# Download Fama-French data (requires internet + frenchdata package)
# [code to fetch FF25 portfolios and FF5+Mom factors]
```

```{r real-data-fallback, eval = !requireNamespace("frenchdata", quietly = TRUE)}
# Offline fallback: use bundled simulated data
data(ff_example, package = "sdim")
out_ff <- sdim(target = ff_example$Y, X = ff_example$X, nfac = 3)
compare(out_ff)
```

## Conclusion

[Summarise the package and its contribution.]
````

- [ ] **Step 3: Verify vignette builds**

```bash
Rscript -e 'devtools::build_vignettes()'
```

Expected: builds without errors.

- [ ] **Step 4: Commit**

```bash
git add vignettes/ data/
git commit -m "docs: add vignette skeleton and offline fallback dataset"
```

---

## Task 11: Final `R CMD check`

- [ ] **Step 1: Run full check**

```bash
Rscript -e 'devtools::check()'
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 2: Fix any remaining issues**

Common issues to watch for:
- `@importFrom` missing for any base R function used in S3 methods (e.g., `graphics::par`, `graphics::title`)
- `@examples` missing or erroring on any exported function
- `LazyData: false` in DESCRIPTION with no `data/` directory will produce a NOTE — add `LazyData: false` if data is not used in the main package (only vignette)

- [ ] **Step 3: Final commit**

```bash
git add -u
git commit -m "chore: pass R CMD check with 0 errors, 0 warnings, 0 notes"
```
