#' Standardize columns to zero mean and unit variance
#'
#' @param X A numeric matrix.
#'
#' @return A matrix with the same dimensions as \code{X}, where each column
#'   has been centred and scaled to unit variance.
#'
#' @examples
#' X <- matrix(rnorm(100), 20, 5)
#' Xs <- oos_standardize(X)
#' round(colMeans(Xs), 10)
#' round(apply(Xs, 2, sd), 10)
#'
#' @export
oos_standardize <- function(X) {

  mu  <- colMeans(X)
  sig <- apply(X, 2, stats::sd)
  sweep(sweep(X, 2, mu, `-`), 2, sig, `/`)

}

#' Select AR lag order by SIC (BIC)
#'
#' Selects the lag order for an autoregressive model of the horizon-\code{h}
#' target \eqn{y_{t,h}} by minimising the Schwarz Information Criterion.
#'
#' @param y Numeric vector of the target variable.
#' @param h Positive integer; forecast horizon. For \code{h = 1} the target is
#'   simply \code{y}.
#' @param p_max Maximum lag order to consider. The function evaluates
#'   \code{p = 0, 1, \ldots, p_max}.
#'
#' @return Integer: selected lag order. A value of 0 means the intercept-only
#'   model is preferred.
#'
#' @examples
#' y <- rnorm(200)
#' select_ar_lag_sic(y, h = 1, p_max = 4)
#'
#' @export
select_ar_lag_sic <- function(y, h, p_max) {

  TT  <- length(y)
  y_h <- vapply(seq_len(TT - (h - 1)),
                function(t) mean(y[t:(t + h - 1)]),
                numeric(1))

  y_raw <- y[seq_len(length(y_h))]
  y_h   <- y_h[(p_max + 1):length(y_h)]

  best_sic <- Inf
  best_p   <- 0L

  for (p in 0:p_max) {

    n <- length(y_h)

    if (p == 0L) {

      ZZ <- matrix(1, n, 1)

    } else {

      y_lags <- do.call(cbind, lapply(1:p, function(j) {
        y_raw[(p_max - (j - 1)):(TT - j - (h - 1))]
      }))
      y_lags <- y_lags[seq_len(n), , drop = FALSE]
      ZZ     <- cbind(1, y_lags)

    }

    a_hat <- solve(crossprod(ZZ), crossprod(ZZ, y_h))
    e_hat <- y_h - ZZ %*% a_hat
    k     <- length(a_hat)
    sic   <- n * log(sum(e_hat^2) / n) + log(n) * k

    if (sic < best_sic) {
      best_sic <- sic
      best_p   <- p
    }

  }

  best_p

}

#' Estimate AR(p) model
#'
#' Fits an autoregressive model of order \code{p} for the horizon-\code{h}
#' target and returns the OLS coefficients and residuals.
#'
#' @param y Numeric vector of the target variable.
#' @param h Positive integer; forecast horizon.
#' @param p Non-negative integer; AR lag order.
#'
#' @return A list with components:
#' \describe{
#'   \item{a_hat}{Coefficient vector (intercept first).}
#'   \item{res}{Residual vector.}
#' }
#'
#' @examples
#' y <- arima.sim(list(ar = 0.7), n = 200)
#' ar_fit <- estimate_ar_res(y, h = 1, p = 1)
#' ar_fit$a_hat
#'
#' @export
estimate_ar_res <- function(y, h, p) {

  TT  <- length(y)
  y_h <- vapply(seq_len(TT - (h - 1)),
                function(t) mean(y[t:(t + h - 1)]),
                numeric(1))

  y_h_dep <- y_h[(p + 1):length(y_h)]

  if (p > 0L) {

    y_lags <- do.call(cbind, lapply(1:p, function(j) {
      y[(p - (j - 1)):(TT - j - (h - 1))]
    }))
    y_lags <- y_lags[seq_len(length(y_h_dep)), , drop = FALSE]
    ZZ     <- cbind(1, y_lags)

  } else {

    ZZ <- matrix(1, length(y_h_dep), 1)

  }

  a_hat <- solve(crossprod(ZZ), crossprod(ZZ, y_h_dep))
  res   <- y_h_dep - ZZ %*% a_hat

  list(a_hat = a_hat, res = as.numeric(res))

}

#' Estimate ARDL(p1, p2) model
#'
#' Fits an autoregressive distributed lag model for the horizon-\code{h}
#' target, with \code{p1} lags of \code{y} and \code{p2} lags of additional
#' regressors \code{z} (e.g., extracted factors).
#'
#' @param y Numeric vector of the target variable.
#' @param z Numeric matrix of additional regressors (e.g., factor estimates).
#' @param h Positive integer; forecast horizon.
#' @param p Integer vector of length 2: \code{c(p1, p2)} where \code{p1} is
#'   the number of AR lags and \code{p2} the number of \code{z} lags.
#'
#' @return Coefficient vector (intercept, AR lags, then z lags).
#'
#' @examples
#' y <- rnorm(200)
#' z <- matrix(rnorm(200 * 3), 200, 3)
#' coefs <- estimate_ardl_multi(y, z, h = 1, p = c(1, 1))
#' coefs
#'
#' @export
estimate_ardl_multi <- function(y, z, h, p) {

  TT    <- length(y)
  sz    <- ncol(z)
  p1    <- p[1]
  p2    <- p[2]
  p_max <- max(p1, p2)

  y_h <- vapply(seq_len(TT - (h - 1)),
                function(t) mean(y[t:(t + h - 1)]),
                numeric(1))

  y_h <- y_h[(p_max + 1):length(y_h)]
  n   <- length(y_h)

  y_lags <- do.call(cbind, lapply(1:p_max, function(j) {
    y[(p_max - (j - 1)):(TT - j - (h - 1))]
  }))
  y_lags <- y_lags[seq_len(n), , drop = FALSE]

  z_lags <- do.call(cbind, lapply(1:p_max, function(j) {
    z[(p_max - (j - 1)):(TT - j - (h - 1)), , drop = FALSE]
  }))
  z_lags <- z_lags[seq_len(n), , drop = FALSE]

  if (p1 == 0L) {

    ZZ <- cbind(1, z_lags[, seq_len(p2 * sz), drop = FALSE])

  } else {

    ZZ <- cbind(1,
                y_lags[, seq_len(p1), drop = FALSE],
                z_lags[, seq_len(p2 * sz), drop = FALSE])

  }

  solve(crossprod(ZZ), crossprod(ZZ, y_h))

}
