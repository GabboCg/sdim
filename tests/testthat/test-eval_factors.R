test_that("eval_factors returns named vector with correct elements", {

  set.seed(42)
  ret <- matrix(rnorm(80 * 6) / 100, 80, 6)
  X   <- matrix(rnorm(80 * 8), 80, 8)
  fit <- pca_est(X = X, nfac = 3L)
  out <- eval_factors(ret = ret, factors = fit$factors)

  expect_named(out, c("RMSPE", "TotalR2", "SR", "A2R"))
  expect_length(out, 4L)
  expect_true(all(is.finite(out)))

})

test_that("eval_factors TotalR2 is higher with more factors", {

  set.seed(42)
  # Create returns with genuine factor structure so R2 is monotone in K
  F_true <- matrix(rnorm(80 * 5), 80, 5)
  B      <- matrix(rnorm(6 * 5), 6, 5)
  ret    <- F_true %*% t(B) / 10 + matrix(rnorm(80 * 6) / 100, 80, 6)

  X   <- matrix(rnorm(80 * 8), 80, 8)
  f1  <- matrix(F_true[, 1], 80, 1)
  f5  <- F_true

  r1 <- eval_factors(ret = ret, factors = f1)
  r5 <- eval_factors(ret = ret, factors = f5)

  expect_gt(r5[["TotalR2"]], r1[["TotalR2"]])

})

test_that("eval_factors RMSPE is non-negative", {

  set.seed(42)
  ret <- matrix(rnorm(60 * 4) / 100, 60, 4)
  X   <- matrix(rnorm(60 * 6), 60, 6)
  fit <- pls_est(target = ret, X = X, nfac = 2L)
  out <- eval_factors(ret = ret, factors = fit$factors)

  expect_gte(out[["RMSPE"]], 0)

})
