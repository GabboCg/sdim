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

  set.seed(42)

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

  set.seed(42)

  Y <- matrix(rnorm(50 * 8), 50, 8)
  out <- sdim:::.pc_T(Y, 3L)
  expect_equal(dim(out$fhat), c(50L, 3L))
  expect_equal(dim(out$lambda), c(8L, 3L))
  expect_length(out$ve2, 50L)

})

test_that(".as_numeric_matrix accepts numeric matrix", {

  X <- matrix(1:6, 2, 3) * 1.0
  expect_identical(sdim:::.as_numeric_matrix(X), X)

})

test_that(".as_numeric_matrix coerces data frame", {

  df <- data.frame(a = 1:5, b = 6:10)
  out <- sdim:::.as_numeric_matrix(df)
  expect_true(is.matrix(out))
  expect_true(is.numeric(out))

})

test_that(".as_numeric_matrix errors on non-matrix", {

  expect_error(sdim:::.as_numeric_matrix(list(1, 2)), "matrix or data frame")

})

test_that(".mat_neghalf inverts square root correctly", {

  set.seed(42)

  A <- matrix(rnorm(4 * 4), 4, 4)
  Q <- A %*% t(A) + diag(4)          # guaranteed SPD
  Qnh <- sdim:::.mat_neghalf(Q)
  # Qnh %*% Q %*% Qnh should equal identity
  expect_equal(Qnh %*% Q %*% Qnh, diag(4), tolerance = 1e-10)

})

test_that(".mat_neghalf errors on non-positive-definite matrix", {

  Q <- diag(c(1, 0, 1))              # zero eigenvalue
  expect_error(sdim:::.mat_neghalf(Q), "positive definite")

})
