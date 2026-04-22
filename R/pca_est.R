#' PCA factor extraction
#'
#' @param target Ignored; accepted for API uniformity with other estimators.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of factors to extract.
#' @param gamma Numeric scalar controlling mean adjustment in the second-moment
#'   matrix. `gamma = -1` (default) gives the sample covariance (traditional
#'   PCA). `gamma = 10` and `gamma = 1` give the Lettau-Ludvigson variants
#'   from He et al. (2023).
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   *Management Science*, 69(9).
#'   \doi{10.1287/mnsc.2022.4428}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' fit <- pca_est(X = X, nfac = 3)
#' print(fit)
#' @export
pca_est <- function(target = NULL, X, nfac, gamma = -1) {

  # Use a dummy single-column target when NULL so .validate_inputs can run
  if (is.null(target)) target <- matrix(0, NROW(X), 1L)

  inp   <- .validate_inputs(target, X, nfac)
  G     <- inp$X
  K     <- inp$nfac
  T_obs <- nrow(G)

  mu  <- colMeans(G)
  C   <- crossprod(G) / T_obs + gamma * outer(mu, mu)

  # eigen(..., symmetric=TRUE) returns eigenvalues in decreasing order
  ev  <- eigen(C, symmetric = TRUE)
  E_k <- ev$vectors[, seq_len(K), drop = FALSE]
  # Matlab: pcaf = G * E * inv(E'E) = G * E (eigenvectors are orthonormal).
  # Factors use raw G, not mean-centred G, matching func_3pca.m.
  factors   <- G %*% E_k                        # T x K
  lambda    <- crossprod(G, factors) / T_obs    # L x K  (G-space loadings)
  residuals <- G - factors %*% t(lambda)        # T x L
  ve2       <- rowMeans(residuals ^ 2)
  eigvals   <- ev$values[seq_len(K)]

  structure(
    list(method = "pca", factors = factors, lambda = lambda,
         eigvecs = E_k,
         residuals = residuals, eigvals = eigvals, ve2 = ve2,
         call = match.call(), gamma = gamma,
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         gmm_stat = NULL, pls_weights = NULL),
    class = "sdim_fit"
  )

}
