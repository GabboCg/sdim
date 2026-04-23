#' Scaled PCA factor extraction
#'
#' Implements scaled principal component analysis (sPCA): predictors are first
#' standardized, then each standardized predictor is scaled by its univariate
#' predictive slope on the target, and finally principal components are
#' extracted from the scaled predictors.
#'
#' @param target A numeric vector of length \code{T_reg} (\code{T_reg <= T}).
#' @param X A numeric matrix or data frame with \code{T} rows and \code{N}
#'   columns. When \code{length(target) < nrow(X)}, the first
#'   \code{length(target)} rows of the standardized \code{X} are used for the
#'   scaling regression while all \code{T} rows are used for standardization
#'   and factor extraction. This matches the out-of-sample workflow in
#'   Huang et al. (2022), where the predictive regression
#'   \code{y_{t+1} ~ X_t} uses fewer rows than the full training window.
#' @param nfac A positive integer giving the number of factors to extract.
#' @param winsorize Logical; if \code{TRUE}, winsorize absolute slope estimates
#'   before scaling predictors.
#' @param winsor_probs Numeric vector of length 2 giving winsorization
#'   percentiles. Used only when \code{winsorize = TRUE}.
#'
#' @return An object of class \code{"sdim_spca"} with components:
#' \describe{
#'   \item{factors}{A \code{T x nfac} matrix of extracted sPCA factors.}
#'   \item{beta}{A numeric vector of predictor-specific predictive slopes.}
#'   \item{beta_scaled}{A numeric vector of scaling coefficients actually used.}
#'   \item{col_means}{Column means of \code{X} (used by \code{predict}).}
#'   \item{col_sds}{Column standard deviations of \code{X} (used by \code{predict}).}
#'   \item{Xs}{The standardized predictor matrix.}
#'   \item{scaleXs}{The scaled standardized predictor matrix.}
#'   \item{lambda}{The estimated loading matrix.}
#'   \item{residuals}{Residual matrix from the PCA reconstruction step.}
#'   \item{ve2}{Average squared residual by row.}
#'   \item{eigvals}{Singular values from the decomposition of \code{scaleXs \%*\% t(scaleXs)}.}
#'   \item{call}{The matched function call.}
#' }
#'
#' @details
#' The function follows the MATLAB implementation of Huang, Jiang, Li, Tong,
#' and Zhou (2022).
#'
#' @references Huang, D., Jiang, F., Li, K., Tong, G., and Zhou, G. (2022).
#'   Scaled PCA: A New Approach to Dimension Reduction.
#'   \emph{Management Science}, 68(3), 1678--1695.
#'   \doi{10.1287/mnsc.2021.4020}
#'
#' @examples
#' set.seed(123)
#' X <- matrix(rnorm(200 * 10), nrow = 200, ncol = 10)
#' y <- rnorm(200)
#'
#' fit <- spca_est(target = y, X = X, nfac = 3)
#' dim(fit$factors)
#' head(fit$beta)
#'
#' # Predictive alignment: target has fewer rows than X
#' fit2 <- spca_est(target = y[1:199], X = X, nfac = 3)
#' dim(fit2$factors)  # 200 x 3 (factors for all T rows)
#'
#' @export
spca_est <- function(target, X, nfac, winsorize = FALSE, winsor_probs = c(0, 99)) {

  target <- as.numeric(target)
  X <- .as_numeric_matrix(X)

  T_full <- nrow(X)
  T_reg  <- length(target)

  if (T_reg > T_full) {

    stop("`target` cannot have more observations than `X`.", call. = FALSE)

  }

  if (!is.numeric(nfac) || length(nfac) != 1L || is.na(nfac)) {

    stop("`nfac` must be one positive integer.", call. = FALSE)

  }

  nfac <- as.integer(nfac)

  if (nfac < 1L) {

    stop("`nfac` must be at least 1.", call. = FALSE)

  }

  if (nfac > min(T_full, ncol(X))) {

    stop("`nfac` cannot exceed min(nrow(X), ncol(X)).", call. = FALSE)

  }

  # Standardize ALL rows of X
  col_means <- colMeans(X, na.rm = TRUE)
  col_sds   <- apply(X, 2, stats::sd, na.rm = TRUE)
  Xs <- .standardize_matrix(X)

  # Scaling regression uses the first T_reg rows of Xs
  Xs_reg <- Xs[seq_len(T_reg), , drop = FALSE]

  beta <- vapply(
    seq_len(ncol(Xs_reg)),
    FUN.VALUE = numeric(1),
    FUN = function(j) {

      fit_j <- stats::lm.fit(x = cbind(1, Xs_reg[, j]), y = target)
      unname(fit_j$coefficients[2])

    }
  )

  beta_scaled <- beta

  if (isTRUE(winsorize)) {

    beta_scaled <- .winsor(abs(beta_scaled), winsor_probs)

  }

  # Scale ALL rows of Xs by betas, then extract factors from all T rows
  scaleXs <- sweep(Xs, 2, beta_scaled, `*`)
  pc_out  <- .pc_T(scaleXs, nfac)

  structure(
    list(
      factors = pc_out$fhat,
      beta = beta,
      beta_scaled = beta_scaled,
      col_means = col_means,
      col_sds = col_sds,
      Xs = Xs,
      scaleXs = scaleXs,
      lambda = pc_out$lambda,
      residuals = pc_out$ehat,
      ve2 = pc_out$ve2,
      eigvals = pc_out$ss,
      call = match.call()
    ),
    class = "sdim_spca"
  )

}

## S3 methods -----------------------------------------------------------------

#' Project new data onto estimated sPCA factor loadings
#'
#' Standardizes \code{newdata} using the training column means and standard
#' deviations, scales by the estimated (possibly winsorized) regression slopes,
#' and projects onto the sPCA loadings.
#'
#' @param object An object of class \code{"sdim_spca"}.
#' @param newdata A numeric matrix or data frame with the same number of
#'   columns as the original predictor matrix.
#' @param ... Additional arguments (currently ignored).
#'
#' @return A numeric matrix of projected factors with \code{nrow(newdata)} rows
#'   and \code{ncol(object$factors)} columns.
#'
#' @export
predict.sdim_spca <- function(object, newdata, ...) {

  newdata <- .as_numeric_matrix(newdata)

  if (ncol(newdata) != length(object$col_means)) {
    stop(sprintf(
      "`newdata` has %d columns but the model expects %d.",
      ncol(newdata), length(object$col_means)
    ), call. = FALSE)
  }

  # Standardize using training parameters
  Xs_new <- sweep(newdata, 2, object$col_means, `-`)
  Xs_new <- sweep(Xs_new, 2, object$col_sds, `/`)

  # Scale by estimated betas
  Xs_scaled <- sweep(Xs_new, 2, object$beta_scaled, `*`)

  # Project onto loadings
  Xs_scaled %*% object$lambda %*% solve(crossprod(object$lambda))

}

#' @export
print.sdim_spca <- function(x, ...) {

  cat("<sdim_spca>\n")
  cat(" Observations :", nrow(x$Xs), "\n")
  cat(" Predictors   :", ncol(x$Xs), "\n")
  cat(" Factors      :", ncol(x$factors), "\n")

  invisible(x)

}

#' @export
summary.sdim_spca <- function(object, ...) {

  K       <- ncol(object$factors)
  eigvals <- object$eigvals[seq_len(K)]
  ve      <- 100 * eigvals / sum(object$eigvals)

  out <- list(
    call         = object$call,
    n_obs        = nrow(object$Xs),
    n_pred       = ncol(object$Xs),
    n_fac        = K,
    beta_summary = stats::quantile(object$beta, probs = c(0, 0.25, 0.5, 0.75, 1)),
    eigvals      = eigvals,
    ve           = ve
  )

  class(out) <- "summary.sdim_spca"
  out

}

#' @export
print.summary.sdim_spca <- function(x, ...) {

  rule <- strrep("-", 40)

  cat("Scaled Principal Component Analysis (sPCA)\n")
  cat(rule, "\n")
  cat("Call: "); print(x$call)

  cat("\nDimensions\n")
  cat(rule, "\n")
  cat(sprintf(" %-16s %d\n", "Observations",  x$n_obs))
  cat(sprintf(" %-16s %d\n", "Predictors",    x$n_pred))
  cat(sprintf(" %-16s %d\n", "Factors",       x$n_fac))

  cat("\nEigenvalues\n")
  cat(rule, "\n")
  fnames <- paste0("F", seq_len(x$n_fac))
  ev_tbl <- rbind(Eigenvalue = round(x$eigvals, 4),
                  `Var. expl. (%)` = round(x$ve, 2))
  colnames(ev_tbl) <- fnames
  print(ev_tbl, quote = FALSE)

  cat("\nOLS slope summary (beta)\n")
  cat(rule, "\n")
  print(round(x$beta_summary, 6))

  invisible(x)

}
