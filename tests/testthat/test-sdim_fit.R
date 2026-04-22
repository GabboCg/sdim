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
  expect_output(print(summary(fit)), "Dimensions")

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

test_that("print.sdim_list prints table and returns invisibly", {

  fit1 <- make_fit(method = "pca", nfac = 2L)
  fit2 <- make_fit(method = "pls", nfac = 2L)
  lst  <- structure(list(pca = fit1, pls = fit2), class = "sdim_list")
  out  <- capture.output(ret <- print(lst))
  expect_identical(ret, lst)
  expect_true(any(grepl("pca", out, ignore.case = TRUE)))
  expect_true(any(grepl("pls", out, ignore.case = TRUE)))
  expect_true(any(grepl("method", out, ignore.case = TRUE)))

})
