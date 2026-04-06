test_that("pls_est returns sdim_fit with correct dimensions", {

  set.seed(42)

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

  # PLS maximises cov(X0 * w, Y0) over unit-norm w, where X0, Y0 are centred.
  # pls_weights stores ri/normti (not unit-norm); normalise before comparing.
  set.seed(42)

  X   <- matrix(rnorm(80 * 5), 80, 5)
  Y   <- matrix(rnorm(80 * 3), 80, 3)
  fit <- pls_est(target = Y, X = X, nfac = 1L)

  X0    <- scale(X, center = TRUE, scale = FALSE)
  w_pls <- fit$pls_weights[, 1]
  w_pls <- w_pls / sqrt(sum(w_pls^2))   # normalise to unit norm
  t1_c  <- X0 %*% w_pls
  cov_pls <- sum(abs(cov(t1_c, Y)))

  set.seed(99)
  w_rand   <- rnorm(5); w_rand <- w_rand / sqrt(sum(w_rand^2))
  t_rand_c <- X0 %*% w_rand
  cov_rand <- sum(abs(cov(t_rand_c, Y)))

  expect_gt(cov_pls, cov_rand)

})

test_that("pls_est eigvals are positive", {

  set.seed(42)

  X   <- matrix(rnorm(50 * 4), 50, 4)
  Y   <- matrix(rnorm(50 * 3), 50, 3)
  fit <- pls_est(target = Y, X = X, nfac = 2L)
  expect_true(all(fit$eigvals > 0))

})
