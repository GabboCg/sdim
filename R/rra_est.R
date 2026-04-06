#' Reduced-Rank Approach (RRA) factor extraction
#'
#' Implements the two-step GMM estimator of He, Huang, Li, and Zhou (2023).
#' Factor proxies \code{X} are rotated to maximise explanatory power for the
#' target return matrix \code{target}, using diagonal GMM weighting matrices.
#'
#' @param target Numeric matrix (T x N) of target variables (e.g., asset
#'   returns). A vector is coerced to a T x 1 matrix.
#' @param X Numeric matrix or data frame (T x L) of factor proxies.
#' @param nfac Positive integer; number of RRA factors to extract.
#' @param compute_stat Logical; if \code{TRUE}, compute the GMM J-test
#'   statistic for overidentifying restrictions. Returned as \code{NULL}
#'   when \code{FALSE} (default) or when degrees of freedom <= 0.
#'
#' @return An object of class \code{"sdim_fit"}.
#' @references He, Huang, Li, Zhou (2023) \doi{10.1287/mnsc.2022.4428}
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(100 * 8), 100, 8)
#' Y <- matrix(rnorm(100 * 5), 100, 5)
#' fit <- rra_est(target = Y, X = X, nfac = 3)
#' print(fit)
#' @export
rra_est <- function(target, X, nfac, compute_stat = FALSE) {

  inp   <- .validate_inputs(target, X, nfac)
  G     <- inp$X
  R     <- inp$target
  K     <- inp$nfac
  T_obs <- nrow(G)
  L     <- ncol(G)
  N     <- ncol(R)
  M     <- L + 1L

  X_int <- matrix(1, T_obs, 1L)
  Z <- cbind(X_int, G)

  # Step 1
  W1 <- diag(N)
  W2 <- diag(M)

  P0 <- Z %*% W2 %*% t(Z)
  P <- P0 - P0 %*% X_int %*% solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0

  Q <- t(G) %*% P %*% G / T_obs ^ 2
  Qnh <- tryCatch(
    .mat_neghalf(Q),
    error = function(e) stop(
      "Q = G'PG/T^2 is not positive definite; check that X has full ",
      "column rank, nfac < ncol(X), and nfac <= ncol(target).",
      call. = FALSE
    )
  )

  cross <- t(G) %*% P %*% R / T_obs ^ 2
  A <- Qnh %*% cross %*% W1 %*% t(cross) %*% Qnh

  ev  <- eigen(A, symmetric = TRUE)
  E_k <- ev$vectors[, seq_len(K), drop = FALSE]
  Phi <- Qnh %*% E_k
  Gstar <- G %*% Phi

  # Residuals for weight update
  Beta  <- solve(t(Gstar) %*% P %*% Gstar) %*% t(Gstar) %*% P %*% R
  Theta <- Phi %*% Beta
  Alpha <- solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0 %*% (R - G %*% Theta)

  U <- R - X_int %*% Alpha - G %*% Theta

  S1 <- diag(diag(t(U) %*% U / T_obs))
  S2 <- diag(diag(t(Z) %*% Z / T_obs))

  # Step 2
  W1 <- solve(S1)
  W2 <- solve(S2)

  P0 <- Z %*% W2 %*% t(Z)
  P  <- P0 - P0 %*% X_int %*% solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0

  Q <- t(G) %*% P %*% G / T_obs ^ 2

  Qnh <- tryCatch(
    .mat_neghalf(Q),
    error = function(e) stop(
      "Q = G'PG/T^2 is not positive definite in step 2; check that X has ",
      "full column rank, nfac < ncol(X), and nfac <= ncol(target).",
      call. = FALSE
    )
  )

  cross <- t(G) %*% P %*% R / T_obs ^ 2
  A <- Qnh %*% cross %*% W1 %*% t(cross) %*% Qnh

  ev <- eigen(A, symmetric = TRUE)
  E_k <- ev$vectors[, seq_len(K), drop = FALSE]
  Phi <- Qnh %*% E_k
  Gstar <- G %*% Phi

  # Step 2 residuals (reused in J-stat block)
  Beta  <- solve(t(Gstar) %*% P %*% Gstar) %*% t(Gstar) %*% P %*% R
  Theta <- Phi %*% Beta
  Alpha <- solve(t(X_int) %*% P0 %*% X_int) %*% t(X_int) %*% P0 %*% (R - G %*% Theta)
  U <- R - X_int %*% Alpha - G %*% Theta

  # Standard output
  factors   <- Gstar
  lambda    <- crossprod(G, factors) / T_obs
  # G-space residuals (T x L), consistent with pca_est / pls_est
  residuals <- G - factors %*% t(lambda)
  ve2       <- rowMeans(residuals ^ 2)
  eigvals   <- ev$values[seq_len(K)]

  # GMM J-stat
  gmm_stat <- NULL
  if (isTRUE(compute_stat)) {

    g  <- t(Z) %*% U / T_obs
    J  <- T_obs * sum(diag(t(g) %*% solve(S2) %*% g %*% solve(S1)))
    df <- (N - K) * (L - K)

    gmm_stat <- if (df > 0L)
      list(stat = J, df = df,
           pvalue = stats::pchisq(J, df = df, lower.tail = FALSE))
    else
      NULL

  }

  structure(
    list(method = "rra", factors = factors, lambda = lambda,
         residuals = residuals, eigvals = eigvals, ve2 = ve2,
         call = match.call(), gmm_stat = gmm_stat,
         beta = NULL, beta_scaled = NULL, Xs = NULL, scaleXs = NULL,
         pls_weights = NULL, gamma = NULL),
    class = "sdim_fit"
  )

}
