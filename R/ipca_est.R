#' IPCA factor extraction
#'
#' @param ret Numeric matrix (T x N) of asset returns. Use \code{NA} for
#'   missing observations (unbalanced panel).
#' @param Z Numeric array (T x N x L) of asset characteristics. \code{NA}s
#'   must mirror \code{ret} exactly.
#' @param nfac Positive integer; number of latent factors K to extract.
#' @param max_iter Maximum ALS iterations (default 100).
#' @param tol Convergence tolerance on Frobenius norm of loading change
#'   (default 1e-6).
#' @param factor_mean Character scalar specifying how the factor mean is
#'   modelled. One of \code{"zero"} (default, no mean adjustment),
#'   \code{"constant"} (time-series average), \code{"VAR1"} (VAR(1) with
#'   intercept), \code{"macro"} (regression on macro predictors), or
#'   \code{"forecombo"} (OLS combination of VAR1 + macro).
#'
#' @return An object of class \code{"sdim_fit"} with fields:
#'   \code{factors} (T x K), \code{lambda} (L x K characteristic loadings,
#'   i.e. Gamma in Kelly et al.), \code{eigvals} (factor variances),
#'   \code{factor_mean} (character scalar), \code{call},
#'   \code{method = "ipca"}, \code{nfac}.
#'   If \code{factor_mean = "constant"}: also \code{mu} (length-K mean vector).
#'   If \code{factor_mean = "VAR1"}: also \code{var_coef} (K x K),
#'   \code{var_intercept} (length-K), \code{var_resid} ((T-1) x K).
#' @references Kelly, Pruitt, Su (2019) \doi{10.1016/j.jfineco.2019.05.001}
#' @examples
#' set.seed(1)
#' ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
#' Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
#' fit <- ipca_est(ret, Z, nfac = 2)
#' print(fit)
#' @export
ipca_est <- function(ret, Z, nfac, max_iter = 100, tol = 1e-6,
                     factor_mean = "zero") {

  cl <- match.call()

  # --- Input validation ---
  if (!is.matrix(ret) || !is.numeric(ret))
    stop("`ret` must be a numeric matrix.", call. = FALSE)

  if (!is.array(Z) || length(dim(Z)) != 3L || !is.numeric(Z))
    stop("`Z` must be a 3-dimensional numeric array.", call. = FALSE)

  t_obs    <- nrow(ret)
  n_assets <- ncol(ret)
  n_char   <- dim(Z)[3L]

  if (dim(Z)[1L] != t_obs || dim(Z)[2L] != n_assets)
    stop(
      "`Z` dimensions [T, N, L] must match `ret` dimensions [T, N].",
      call. = FALSE
    )

  if (!is.numeric(nfac) || length(nfac) != 1L || is.na(nfac) || nfac < 1L)
    stop("`nfac` must be a positive integer.", call. = FALSE)
  nfac <- as.integer(nfac)

  if (nfac > n_char)
    stop(
      "`nfac` cannot exceed the number of characteristics L.",
      call. = FALSE
    )

  if (nfac > t_obs)
    stop(
      "`nfac` cannot exceed the number of time periods T.",
      call. = FALSE
    )

  if (nfac > n_assets)
    stop("`nfac` cannot exceed the number of assets N.", call. = FALSE)

  if (!is.numeric(max_iter) || length(max_iter) != 1L ||
        is.na(max_iter) || max_iter < 1L)
    stop("`max_iter` must be a positive integer.", call. = FALSE)
  max_iter <- as.integer(max_iter)

  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol <= 0)
    stop("`tol` must be a positive number.", call. = FALSE)

  valid_fm <- c("zero", "constant", "VAR1", "macro", "forecombo")
  if (!is.character(factor_mean) || length(factor_mean) != 1L ||
        !factor_mean %in% valid_fm)
    stop(
      "`factor_mean` must be one of \"zero\", \"constant\", \"VAR1\", \"macro\", or \"forecombo\".",
      call. = FALSE
    )

  # Check NAs mirror between ret and Z
  na_ret <- is.na(ret)
  for (l in seq_len(n_char)) {
    if (!identical(na_ret, is.na(Z[, , l])))
      stop(
        "NAs in `Z` must mirror NAs in `ret` (same positions).",
        call. = FALSE
      )
  }

  # Build per-period lists; validate N_t >= K
  ret_list <- vector("list", t_obs)
  z_list   <- vector("list", t_obs)
  for (t in seq_len(t_obs)) {
    obs <- which(!is.na(ret[t, ]))
    if (length(obs) < nfac) {
      msg <- sprintf(
        "Time period %d has %d observed assets, fewer than nfac = %d.",
        t, length(obs), nfac
      )
      stop(msg, call. = FALSE)
    }
    ret_list[[t]] <- ret[t, obs]
    z_list[[t]]   <- matrix(Z[t, obs, ], nrow = length(obs), ncol = n_char)
  }

  # --- Call Rcpp ALS ---
  res <- ipca_als_cpp(ret_list, z_list, K = nfac,
                      max_iter = max_iter, tol = tol)

  # --- Post-ALS: factor mean ---
  extra <- list()

  if (factor_mean %in% c("macro", "forecombo"))
    stop(
      sprintf("`factor_mean = '%s'` is not yet implemented.", factor_mean),
      call. = FALSE
    )

  if (factor_mean == "constant") {
    extra$mu <- colMeans(res[["F"]])
  }

  if (factor_mean == "VAR1") {
    f_mat <- res[["F"]]
    if (nrow(f_mat) <= nfac + 1L)
      stop(
        "`factor_mean = 'VAR1'` requires T > nfac + 1 time periods.",
        call. = FALSE
      )
    y_mat <- f_mat[-1L, , drop = FALSE]
    x_mat <- cbind(1, f_mat[-nrow(f_mat), , drop = FALSE])
    xtx   <- crossprod(x_mat)
    xty   <- crossprod(x_mat, y_mat)
    b_hat <- tryCatch(
      solve(xtx, xty),
      error = function(e) {
        solve(xtx + 1e-8 * diag(nrow(xtx)), xty)
      }
    )
    extra$var_intercept <- b_hat[1L, ]
    extra$var_coef      <- b_hat[-1L, , drop = FALSE]
    extra$var_resid     <- y_mat - x_mat %*% b_hat
  }

  structure(
    c(list(method      = "ipca",
           call        = cl,
           factors     = res[["F"]],
           lambda      = res[["Gamma"]],
           eigvals     = as.numeric(res[["sv"]]),
           nfac        = nfac,
           factor_mean = factor_mean),
      extra),
    class = "sdim_fit"
  )
}
