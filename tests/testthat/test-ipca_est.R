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
