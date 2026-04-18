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
#'
#' @return An object of class \code{"sdim_fit"} with fields:
#'   \code{factors} (T x K), \code{lambda} (L x K characteristic loadings,
#'   i.e. Gamma in Kelly et al.), \code{eigvals} (factor variances),
#'   \code{call}, \code{method = "ipca"}, \code{nfac}.
#' @references Kelly, Pruitt, Su (2019) \doi{10.1016/j.jfineco.2019.05.001}
#' @examples
#' set.seed(1)
#' ret <- matrix(rnorm(50 * 10) / 100, 50, 10)
#' Z   <- array(rnorm(50 * 10 * 4), dim = c(50, 10, 4))
#' fit <- ipca_est(ret, Z, nfac = 2)
#' print(fit)
#' @export
ipca_est <- function(ret, Z, nfac, max_iter = 100, tol = 1e-6) {

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
    if (length(obs) < nfac)
      stop(sprintf(
        "Time period %d has %d observed assets, fewer than nfac = %d.",
        t, length(obs), nfac), call. = FALSE)
    ret_list[[t]] <- ret[t, obs]
    z_list[[t]]   <- matrix(Z[t, obs, ], nrow = length(obs), ncol = n_char)
  }

  # --- Call Rcpp ALS ---
  res <- ipca_als_cpp(ret_list, z_list, K = nfac,
                      max_iter = max_iter, tol = tol)

  structure(
    list(method  = "ipca",
         call    = cl,
         factors = res[["F"]],
         lambda  = res[["Gamma"]],
         eigvals = as.numeric(res[["sv"]]),
         nfac    = nfac),
    class = "sdim_fit"
  )
}
