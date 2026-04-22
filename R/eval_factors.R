#' Evaluate extracted factors against target returns
#'
#' Computes the two performance measures from He, Huang, Li, Zhou (2023),
#' Section 2.4: Total adj-\eqn{R^2} (Equation 19) and root-mean-squared
#' pricing error (RMSPE, Equation 20).
#'
#' @param ret Numeric matrix or data frame (T x N) of excess returns for the
#'   target portfolios.
#' @param factors Numeric matrix (T x K) of extracted factors, e.g.
#'   \code{fit$factors} from \code{\link{pca_est}}, \code{\link{pls_est}}, or
#'   \code{\link{rra_est}}.
#'
#' @return A named numeric vector with four elements:
#' \describe{
#'   \item{RMSPE}{Root-mean-squared pricing error (percent). Average over
#'     assets of the per-asset RMSE of \eqn{R_{it} - \hat\beta_i' f_t}
#'     (intercept excluded from the fitted value), as in Equation 20.
#'     Multiplied by 100 when \code{ret} is in decimal units.}
#'   \item{TotalR2}{Total adjusted \eqn{R^2} (percent), as in Equation 19.}
#'   \item{SR}{Mean absolute alpha-to-residual-volatility ratio (Sharpe
#'     ratio of pricing errors).}
#'   \item{A2R}{Mean absolute alpha-to-mean-return ratio.}
#' }
#'
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#'
#' @examples
#' set.seed(1)
#' ret <- matrix(rnorm(100 * 10) / 100, 100, 10)
#' X   <- matrix(rnorm(100 * 8), 100, 8)
#' fit <- pca_est(X = X, nfac = 3)
#' eval_factors(ret = ret, factors = fit$factors)
#' @export
eval_factors <- function(ret, factors) {

  ret     <- as.matrix(ret)
  factors <- as.matrix(factors)

  K <- ncol(factors)
  N <- ncol(ret)
  T_obs <- nrow(ret)

  res  <- matrix(NA_real_, N, 5L)
  rmse <- numeric(N)

  FF <- factors
  X  <- cbind(1, FF)

  for (i in seq_len(N)) {

    ri   <- ret[, i]
    b    <- qr.solve(X, ri)
    yhat <- drop(X %*% b)

    adj     <- (T_obs - 1L) / (T_obs - 1L - K)
    res_ri2 <- sum((ri - yhat) ^ 2) * adj
    ri2     <- sum(ri ^ 2)
    alpha   <- b[1L]
    sig_res <- sd(ri - yhat)
    rbar    <- mean(ri)

    # Eq. 20: R_it - hat_beta' f_t  (no intercept in fitted value)
    rmse[i] <- sqrt(mean((ri - FF %*% b[-1L]) ^ 2))

    res[i, ] <- c(res_ri2, ri2, alpha, sig_res, rbar)

  }

  rmspe    <- 100 * mean(rmse)
  total_r2 <- 100 * (1 - sum(res[, 1L]) / sum(res[, 2L]))
  sr       <- mean(abs(res[, 3L] / res[, 4L]))
  a2r      <- mean(abs(res[, 3L] / res[, 5L]))

  result <- c(RMSPE = rmspe, TotalR2 = total_r2, SR = sr, A2R = a2r)
  structure(result, class = "sdim_eval", n_port = N, n_fac = K)

}

#' @export
print.sdim_eval <- function(x, ...) {

  rule <- strrep("-", 40)
  lbl  <- function(s, w = 16) paste0(s, strrep(" ", w - nchar(s, type = "chars")))

  cat("Factor Evaluation\n")
  cat(rule, "\n")
  cat(sprintf(" %s %d\n", lbl("Portfolios"), attr(x, "n_port")))
  cat(sprintf(" %s %d\n", lbl("Factors"),    attr(x, "n_fac")))

  cat("\nPerformance (He et al., 2023, \u00a72.4)\n")
  cat(rule, "\n")
  cat(sprintf(" %s %8.4f  (%%)\n", lbl("RMSPE"),             unclass(x)[["RMSPE"]]))
  cat(sprintf(" %s %8.4f  (%%)\n", lbl("Total adj-R\u00b2"), unclass(x)[["TotalR2"]]))
  cat(sprintf(" %s %8.4f\n",       lbl("SR"),                 unclass(x)[["SR"]]))
  cat(sprintf(" %s %8.4f\n",       lbl("A2R"),                unclass(x)[["A2R"]]))

  invisible(x)

}

#' @export
`[.sdim_eval` <- function(x, i) {
  unclass(x)[i]
}
