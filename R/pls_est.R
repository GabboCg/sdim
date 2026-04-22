#' PLS factor extraction (Matlab-faithful NIPALS algorithm)
#'
#' @param target Numeric matrix (T x N) of target variables (e.g., asset
#'   returns). A vector is coerced to a T x 1 matrix.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of PLS components to extract.
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   *Management Science*, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' Y <- matrix(rnorm(100 * 5), 100, 5)
#' fit <- pls_est(target = Y, X = X, nfac = 3)
#' print(fit)
#' @export
pls_est <- function(target, X, nfac) {

  inp   <- .validate_inputs(target, X, nfac)
  G     <- inp$X        # T x L  (raw factor proxies)
  R     <- inp$target   # T x N
  K     <- inp$nfac
  T_obs <- nrow(G)
  L     <- ncol(G)

  # ---- centre G and R (mirrors Matlab plsregress intercept = true) ----------
  muG <- colMeans(G)
  muR <- colMeans(R)
  G0  <- sweep(G, 2L, muG, "-")
  R0  <- sweep(R, 2L, muR, "-")

  Xloadings <- matrix(0, L, K)
  Weights   <- matrix(0, L, K)
  V         <- matrix(0, L, K)   # Gram-Schmidt orthogonalised X-loadings

  Cov <- crossprod(G0, R0)       # L x N  cross-covariance

  for (i in seq_len(K)) {

    sv  <- svd(Cov, nu = 1L, nv = 0L)
    ri  <- sv$u[, 1L, drop = FALSE]    # L x 1  left singular vector

    ti     <- G0 %*% ri
    normti <- sqrt(sum(ti^2))
    ti     <- ti / normti

    Xloadings[, i] <- drop(crossprod(G0, ti))
    Weights[, i]   <- drop(ri / normti)

    # Gram-Schmidt orthogonalise new X-loading against previous ones
    vi <- Xloadings[, i, drop = FALSE]
    if (i > 1L) {
      for (rep_idx in 1:2) {
        for (j in seq_len(i - 1L)) {
          vj <- V[, j, drop = FALSE]
          vi <- vi - vj * drop(crossprod(vj, vi))
        }
      }
    }
    vi       <- vi / sqrt(sum(vi^2))
    V[, i]   <- drop(vi)

    # Deflate cross-covariance
    Vi  <- V[, seq_len(i), drop = FALSE]
    Cov <- Cov - vi %*% crossprod(vi, Cov)
    Cov <- Cov - Vi %*% crossprod(Vi, Cov)

  }

  # ---- factors = raw G * W  (matching Matlab: plsf = G * stats.W) -----------
  factors   <- G %*% Weights               # T x K
  lambda    <- crossprod(G, factors) / T_obs   # L x K  (G-space loadings)
  residuals <- G - factors %*% t(lambda)       # T x L
  ve2       <- rowMeans(residuals^2)
  eigvals   <- colSums(factors^2)

  structure(
    list(method = "pls", factors = factors, lambda = lambda,
         residuals = residuals, eigvals = eigvals, ve2 = ve2,
         call = match.call(), pls_weights = Weights,
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         gmm_stat = NULL, gamma = NULL),
    class = "sdim_fit"
  )

}
