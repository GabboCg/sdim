# Out-of-sample forecasting helpers for macroeconomic factor model evaluation.
# Used by the Huang et al. (2022) replication and general OOS exercises.
# All functions are internal (not exported).

# Standardize columns to zero mean, unit variance.
.oos_standardize <- function(X) {

  mu  <- colMeans(X)
  sig <- apply(X, 2, stats::sd)
  sweep(sweep(X, 2, mu, `-`), 2, sig, `/`)

}

# Select AR lag order by SIC/BIC.
#
# @param y Numeric vector of target variable.
# @param h Forecast horizon.
# @param p_max Maximum lag order to consider.
# @return Integer: selected lag order (0 means intercept-only).
.select_ar_lag_sic <- function(y, h, p_max) {

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

# Estimate AR(p) model and return coefficients and residuals.
#
# @param y Numeric vector of target variable.
# @param h Forecast horizon.
# @param p AR lag order (must be >= 1).
# @return List with `a_hat` (coefficient vector) and `res` (residual vector).
.estimate_ar_res <- function(y, h, p) {

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

# Estimate ARDL(p1, p2) model.
#
# @param y Numeric vector of target variable.
# @param z Numeric matrix of additional regressors (e.g., factors).
# @param h Forecast horizon.
# @param p Integer vector of length 2: c(p1, p2) where p1 = AR lags, p2 = z lags.
# @return Coefficient vector.
.estimate_ardl_multi <- function(y, z, h, p) {

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
