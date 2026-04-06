test_that("rra_est returns sdim_fit with correct dimensions", {

  set.seed(42)

  X   <- matrix(rnorm(60 * 6), 60, 6)
  Y   <- matrix(rnorm(60 * 4), 60, 4)
  fit <- rra_est(target = Y, X = X, nfac = 2L)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "rra")
  expect_equal(dim(fit$factors), c(60L, 2L))
  expect_equal(dim(fit$lambda),  c(6L,  2L))
  expect_length(fit$eigvals, 2L)

})

test_that("rra_est eigvals are sorted descending", {

  set.seed(42)

  X   <- matrix(rnorm(80 * 5), 80, 5)
  Y   <- matrix(rnorm(80 * 3), 80, 3)
  fit <- rra_est(target = Y, X = X, nfac = 3L)
  expect_true(all(diff(fit$eigvals) <= 0))

})

test_that("rra_est compute_stat = TRUE returns valid J-stat", {

  # Fixture: N=4 > K=2, L=6 > K=2, so df = (4-2)*(6-2) = 8 > 0
  set.seed(42)

  X   <- matrix(rnorm(60 * 6), 60, 6)
  Y   <- matrix(rnorm(60 * 4), 60, 4)
  fit <- rra_est(target = Y, X = X, nfac = 2L, compute_stat = TRUE)
  expect_type(fit$gmm_stat, "list")
  expect_gt(fit$gmm_stat$stat, 0)
  expect_false(is.na(fit$gmm_stat$pvalue))
  expect_gte(fit$gmm_stat$pvalue, 0)
  expect_lte(fit$gmm_stat$pvalue, 1)
  expect_equal(fit$gmm_stat$df, (4L - 2L) * (6L - 2L))

})

test_that("rra_est compute_stat = FALSE (default) returns NULL gmm_stat", {

  set.seed(42)

  X   <- matrix(rnorm(50 * 5), 50, 5)
  Y   <- matrix(rnorm(50 * 3), 50, 3)
  fit <- rra_est(target = Y, X = X, nfac = 2L)
  expect_null(fit$gmm_stat)

})

test_that("rra_est ve2 and residuals are consistent", {

  set.seed(42)

  X   <- matrix(rnorm(50 * 5), 50, 5)
  Y   <- matrix(rnorm(50 * 3), 50, 3)
  fit <- rra_est(target = Y, X = X, nfac = 2L)
  expect_equal(fit$ve2, rowMeans(fit$residuals ^ 2))

})

test_that("rra_est compute_stat = TRUE returns NULL gmm_stat when df <= 0", {

  # K = N = 3, so df = (N-K)*(L-K) = 0 -> gmm_stat must be NULL
  set.seed(42)

  X   <- matrix(rnorm(60 * 5), 60, 5)
  Y   <- matrix(rnorm(60 * 3), 60, 3)
  fit <- rra_est(target = Y, X = X, nfac = 3L, compute_stat = TRUE)
  expect_null(fit$gmm_stat)

})
