test_that("pca_est returns sdim_fit with correct dimensions", {

  set.seed(42)

  X <- matrix(rnorm(60 * 6), 60, 6)
  fit <- pca_est(X = X, nfac = 3L)
  expect_s3_class(fit, "sdim_fit")
  expect_equal(fit$method, "pca")
  expect_equal(dim(fit$factors), c(60L, 3L))
  expect_equal(dim(fit$lambda),  c(6L,  3L))
  expect_length(fit$eigvals, 3L)

})

test_that("pca_est demeaned factors are orthogonal", {

  set.seed(42)

  # G * E (raw) is not orthogonal in general; demeaning recovers orthogonality
  # because E diagonalises the *covariance* (mean-adjusted) matrix.
  X   <- matrix(rnorm(80 * 8), 80, 8)
  fit <- pca_est(X = X, nfac = 3L)
  Fc  <- scale(fit$factors, center = TRUE, scale = FALSE)
  FtF <- crossprod(Fc)
  off_diag <- FtF[upper.tri(FtF)]
  expect_equal(off_diag, rep(0, 3), tolerance = 1e-8)

})

test_that("pca_est gamma parameter changes factors", {

  set.seed(42)

  X    <- matrix(rnorm(50 * 5), 50, 5)
  fit1 <- pca_est(X = X, nfac = 2L, gamma = -1)
  fit2 <- pca_est(X = X, nfac = 2L, gamma = 10)
  expect_false(isTRUE(all.equal(fit1$factors, fit2$factors)))

})

test_that("pca_est accepts NULL target without error", {

  set.seed(42)

  X <- matrix(rnorm(40 * 4), 40, 4)
  expect_no_error(pca_est(target = NULL, X = X, nfac = 2L))

})

test_that("pca_est ve2 and residuals are consistent", {

  set.seed(42)

  X   <- matrix(rnorm(50 * 5), 50, 5)
  fit <- pca_est(X = X, nfac = 2L)
  expect_equal(fit$ve2, rowMeans(fit$residuals ^ 2))

})
