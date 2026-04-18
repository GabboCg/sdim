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
