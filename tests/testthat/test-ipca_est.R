test_that("ipca_est returns sdim_fit with correct dimensions", {
  set.seed(42)
  T <- 50; N <- 15; L <- 5; K <- 2
  ret <- matrix(rnorm(T * N) / 100, T, N)
  Z   <- array(rnorm(T * N * L), dim = c(T, N, L))
  fit <- ipca_est(ret, Z, nfac = K)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "ipca")
  expect_equal(dim(fit$factors), c(T, K))
  expect_equal(dim(fit$lambda),  c(L, K))
  expect_length(fit$eigvals, K)
  expect_false(is.null(fit$call))
})

test_that("print.sdim_fit shows Characteristics for ipca", {
  set.seed(1)
  ret <- matrix(rnorm(40 * 8) / 100, 40, 8)
  Z   <- array(rnorm(40 * 8 * 4), dim = c(40, 8, 4))
  fit <- ipca_est(ret, Z, nfac = 2)
  out <- capture.output(print(fit))
  expect_true(any(grepl("Characteristics", out)))
  expect_false(any(grepl("Predictors", out)))
})

test_that("summary.sdim_fit shows Characteristics for ipca", {
  set.seed(1)
  ret <- matrix(rnorm(40 * 8) / 100, 40, 8)
  Z   <- array(rnorm(40 * 8 * 4), dim = c(40, 8, 4))
  fit <- ipca_est(ret, Z, nfac = 2)
  out <- capture.output(summary(fit))
  expect_true(any(grepl("Characteristics", out)))
  expect_true(any(grepl("IPCA", out)))
})

# ---------------------------------------------------------------------------
# Step 5.1: Input validation tests
# ---------------------------------------------------------------------------

test_that("ipca_est errors on non-matrix ret", {
  Z <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  expect_error(ipca_est(as.data.frame(matrix(1, 50, 10)), Z, nfac = 2),
               "`ret` must be a numeric matrix")
})

test_that("ipca_est errors on non-array Z", {
  ret <- matrix(rnorm(50 * 10), 50, 10)
  expect_error(ipca_est(ret, matrix(1, 50, 10), nfac = 2),
               "`Z` must be a 3-dimensional numeric array")
})

test_that("ipca_est errors on dimension mismatch", {
  ret <- matrix(rnorm(50 * 10), 50, 10)
  Z_bad <- array(rnorm(50 * 9 * 4), dim = c(50, 9, 4))
  expect_error(ipca_est(ret, Z_bad, nfac = 2),
               "dimensions")
})

test_that("ipca_est errors when nfac > L", {
  ret <- matrix(rnorm(50 * 10), 50, 10)
  Z   <- array(rnorm(50 * 10 * 3), dim = c(50, 10, 3))
  expect_error(ipca_est(ret, Z, nfac = 5),
               "`nfac` cannot exceed")
})

test_that("ipca_est errors when N_t < nfac", {
  set.seed(1)
  T <- 50; N <- 10; L <- 4; K <- 3
  ret <- matrix(rnorm(T * N) / 100, T, N)
  Z   <- array(rnorm(T * N * L), dim = c(T, N, L))
  ret[1, 3:N] <- NA
  Z[1, 3:N, ] <- NA
  expect_error(ipca_est(ret, Z, nfac = K),
               "fewer than nfac")
})

test_that("ipca_est errors when Z NAs don't mirror ret", {
  set.seed(1)
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  ret[1, 1] <- NA
  expect_error(ipca_est(ret, Z, nfac = 2),
               "NAs in `Z` must mirror")
})

# ---------------------------------------------------------------------------
# Step 5.2: Algorithm correctness tests
# ---------------------------------------------------------------------------

test_that("ipca_est recovers true factor structure up to rotation", {
  set.seed(123)
  T <- 200; N <- 50; L <- 6; K <- 2
  Gamma_true <- matrix(rnorm(L * K), L, K)
  F_true     <- matrix(rnorm(T * K), T, K)
  Z <- array(rnorm(T * N * L), dim = c(T, N, L))
  ret <- matrix(0, T, N)
  for (t in seq_len(T)) {
    Zt <- matrix(Z[t, , ], N, L)
    ret[t, ] <- Zt %*% Gamma_true %*% F_true[t, ] + rnorm(N, sd = 0.1)
  }
  fit <- ipca_est(ret, Z, nfac = K, max_iter = 200)
  GG_fit  <- fit$lambda %*% t(fit$lambda)
  GG_true <- Gamma_true %*% solve(t(Gamma_true) %*% Gamma_true) %*% t(Gamma_true)
  expect_lt(norm(GG_fit - GG_true, "F") / norm(GG_true, "F"), 0.3)
})

test_that("eval_factors works unchanged on ipca output", {
  set.seed(42)
  ret <- matrix(rnorm(60 * 12) / 100, 60, 12)
  Z   <- array(rnorm(60 * 12 * 4), dim = c(60, 12, 4))
  fit <- ipca_est(ret, Z, nfac = 2)
  expect_no_error(eval_factors(ret = ret, factors = fit$factors))
})

test_that("non-convergence triggers a warning", {
  set.seed(1)
  ret <- matrix(rnorm(40 * 10) / 100, 40, 10)
  Z   <- array(rnorm(40 * 10 * 4), dim = c(40, 10, 4))
  expect_warning(ipca_est(ret, Z, nfac = 2, max_iter = 1),
                 "did not converge")
})

# ---------------------------------------------------------------------------
# Step 5.3: Edge case tests
# ---------------------------------------------------------------------------

test_that("ipca_est works with nfac = 1", {
  set.seed(7)
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  fit <- suppressWarnings(ipca_est(ret, Z, nfac = 1))
  expect_equal(dim(fit$factors), c(50L, 1L))
  expect_equal(dim(fit$lambda),  c(4L,  1L))
})

test_that("ipca_est works with nfac = L (square Gamma)", {
  set.seed(8)
  L   <- 4
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * L), dim = c(50, 10, L))
  fit <- suppressWarnings(ipca_est(ret, Z, nfac = L))
  expect_equal(dim(fit$lambda), c(L, L))
})

test_that("ipca_est handles unbalanced panel (10% NAs)", {
  set.seed(99)
  T <- 60; N <- 20; L <- 4; K <- 2
  ret <- matrix(rnorm(T * N) / 100, T, N)
  Z   <- array(rnorm(T * N * L), dim = c(T, N, L))
  for (i in seq_len(floor(0.10 * T * N))) {
    t_idx <- sample(which(rowSums(!is.na(ret)) > K + 1), 1)
    n_idx <- sample(which(!is.na(ret[t_idx, ])), 1)
    ret[t_idx, n_idx] <- NA
    Z[t_idx, n_idx, ] <- NA
  }
  fit <- ipca_est(ret, Z, nfac = K)
  expect_equal(dim(fit$factors), c(T, K))
})

test_that("print.sdim_list works with mixed rra and ipca fits", {
  set.seed(5)
  X   <- matrix(rnorm(60 * 6), 60, 6)
  ret <- matrix(rnorm(60 * 10) / 100, 60, 10)
  Z   <- array(rnorm(60 * 10 * 6), dim = c(60, 10, 6))
  fit_rra  <- rra_est(target = ret, X = X, nfac = 2)
  fit_ipca <- ipca_est(ret, Z, nfac = 2)
  sdl <- structure(list(rra = fit_rra, ipca = fit_ipca), class = "sdim_list")
  expect_no_error(print(sdl))
})

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

test_that("factor_mean = 'VAR1' stores var_coef, var_intercept, var_resid", {
  set.seed(12)
  T <- 60; N <- 15; L <- 4; K <- 2
  ret <- matrix(rnorm(T * N) / 100, T, N)
  Z   <- array(rnorm(T * N * L), dim = c(T, N, L))
  fit <- ipca_est(ret, Z, nfac = K, factor_mean = "VAR1")
  expect_equal(fit$factor_mean, "VAR1")
  expect_equal(dim(fit$var_coef),  c(K, K))
  expect_length(fit$var_intercept, K)
  expect_equal(dim(fit$var_resid), c(T - 1L, K))
  expect_null(fit$mu)
})

test_that("factor_mean = 'VAR1' errors when T <= nfac + 1", {
  set.seed(13)
  K <- 2; T <- K + 1L
  ret <- matrix(rnorm(T * 10) / 100, T, 10)
  Z   <- array(rnorm(T * 10 * 4), dim = c(T, 10, 4))
  expect_error(
    ipca_est(ret, Z, nfac = K, factor_mean = "VAR1"),
    regexp = "T > nfac \\+ 1"
  )
})

test_that("factor_mean = 'macro' and 'forecombo' are not yet implemented", {
  set.seed(16)
  ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
  Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
  expect_error(
    ipca_est(ret, Z, nfac = 2, factor_mean = "macro"),
    regexp = "not yet implemented"
  )
  expect_error(
    ipca_est(ret, Z, nfac = 2, factor_mean = "forecombo"),
    regexp = "not yet implemented"
  )
})

test_that("print and summary show Factor mean for all three specs", {
  set.seed(15)
  ret <- matrix(rnorm(60 * 12) / 100, 60, 12)
  Z   <- array(rnorm(60 * 12 * 5), dim = c(60, 12, 5))

  for (fm in c("zero", "constant", "VAR1")) {
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
