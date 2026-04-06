test_that("spca_est returns expected dimensions", {

  set.seed(42)

  X <- matrix(rnorm(100 * 8), 100, 8)
  y <- rnorm(100)

  fit <- spca_est(y, X, nfac = 3)

  expect_s3_class(fit, "sdim_spca")
  expect_equal(dim(fit$factors), c(100, 3))
  expect_length(fit$beta, 8)
  expect_equal(dim(fit$lambda), c(8, 3))

})
