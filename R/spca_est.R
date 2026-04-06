#' Scaled PCA factor extraction
#'
#' Implements scaled principal component analysis (sPCA): predictors are first
#' standardized, then each standardized predictor is scaled by its univariate
#' predictive slope on the target, and finally principal components are
#' extracted from the scaled predictors.
#'
#' @param target A numeric vector of length `T`.
#' @param X A numeric matrix or data frame with `T` rows and `N` columns.
#' @param nfac A positive integer giving the number of factors to extract.
#' @param winsorize Logical; if `TRUE`, winsorize absolute slope estimates
#'   before scaling predictors.
#' @param winsor_probs Numeric vector of length 2 giving winsorization
#'   percentiles. Used only when `winsorize = TRUE`.
#'
#' @return An object of class `"sdim_spca"` with components:
#' \describe{
#'   \item{factors}{A `T x nfac` matrix of extracted sPCA factors.}
#'   \item{beta}{A numeric vector of predictor-specific predictive slopes.}
#'   \item{beta_scaled}{A numeric vector of scaling coefficients actually used.}
#'   \item{Xs}{The standardized predictor matrix.}
#'   \item{scaleXs}{The scaled standardized predictor matrix.}
#'   \item{lambda}{The estimated loading matrix.}
#'   \item{residuals}{Residual matrix from the PCA reconstruction step.}
#'   \item{ve2}{Average squared residual by row.}
#'   \item{eigvals}{Singular values from the decomposition of `scaleXs %*% t(scaleXs)`.}
#'   \item{call}{The matched function call.}
#' }
#'
#' @details
#' The function follows the MATLAB implementation supplied by the user, with
#' package-style input checking and a structured return object.
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
#' @export
spca_est <- function(target, X, nfac, winsorize = FALSE, winsor_probs = c(0, 99)) {

  target <- as.numeric(target)
  X <- .as_numeric_matrix(X)

  if (length(target) != nrow(X)) {

    stop("`target` and `X` must have the same number of observations.", call. = FALSE)

  }

  if (!is.numeric(nfac) || length(nfac) != 1L || is.na(nfac)) {

    stop("`nfac` must be one positive integer.", call. = FALSE)

  }

  nfac <- as.integer(nfac)

  if (nfac < 1L) {

    stop("`nfac` must be at least 1.", call. = FALSE)

  }

  if (nfac > min(nrow(X), ncol(X))) {

    stop("`nfac` cannot exceed min(nrow(X), ncol(X)).", call. = FALSE)

  }

  Xs <- .standardize_matrix(X)

  beta <- vapply(
    seq_len(ncol(Xs)),
    FUN.VALUE = numeric(1),
    FUN = function(j) {

      fit_j <- stats::lm.fit(x = cbind(1, Xs[, j]), y = target)
      unname(fit_j$coefficients[2])

    }
  )

  beta_scaled <- beta

  if (isTRUE(winsorize)) {

    beta_scaled <- .winsor(abs(beta_scaled), winsor_probs)

  }

  scaleXs <- sweep(Xs, 2, beta_scaled, `*`)
  pc_out <- .pc_T(scaleXs, nfac)

  structure(
    list(
      factors = pc_out$fhat,
      beta = beta,
      beta_scaled = beta_scaled,
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

  cat("Scaled PCA (sPCA)\n")
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
