# Shared internal helpers for sdim estimators.
# All functions are prefixed with a dot and not exported.

.validate_inputs <- function(target, X, nfac) {

  target <- as.matrix(target)
  X <- .as_numeric_matrix(X)

  if (nrow(X) != nrow(target))
    stop("`target` and `X` must have the same number of rows.", call. = FALSE)

  if (!is.numeric(nfac) || length(nfac) != 1L || is.na(nfac) || nfac < 1L)
    stop("`nfac` must be a positive integer.", call. = FALSE)

  nfac <- as.integer(nfac)

  if (nfac > min(nrow(X), ncol(X)))
    stop("`nfac` cannot exceed min(nrow(X), ncol(X)).", call. = FALSE)

  list(target = target, X = X, nfac = nfac)

}

.as_numeric_matrix <- function(x) {

  if (is.data.frame(x)) x <- as.matrix(x)
  if (!is.matrix(x))   stop("`X` must be a matrix or data frame.", call. = FALSE)
  if (!is.numeric(x))  stop("`X` must be numeric.", call. = FALSE)

  x

}

.standardize_matrix <- function(y) {

  y   <- as.matrix(y)
  mu  <- colMeans(y, na.rm = TRUE)
  sdv <- apply(y, 2, stats::sd, na.rm = TRUE)

  if (any(is.na(sdv) | sdv == 0))
    stop("All columns of `X` must have nonzero finite standard deviation.", call. = FALSE)

  out <- sweep(y, 2, mu, `-`)
  sweep(out, 2, sdv, `/`)

}

.winsor <- function(x, p) {

  if (!is.numeric(x) || length(p) != 2L)
    stop("Invalid inputs to `.winsor()`.", call. = FALSE)

  if (p[1] < 0 || p[1] > 100 || p[2] < 0 || p[2] > 100 || p[1] > p[2])
    stop("`winsor_probs` must satisfy 0 <= left <= right <= 100.", call. = FALSE)

  q  <- as.numeric(stats::quantile(x, probs = p / 100, na.rm = TRUE, type = 1))
  y  <- x
  i1 <- x < q[1];  i2 <- x > q[2]

  y[i1] <- q[1]
  y[i2] <- q[2]

  y

}

.pc_T <- function(y, nfac) {

  y <- as.matrix(y)
  bigt <- nrow(y)
  s <- base::svd(y %*% t(y))
  idx <- seq_len(nfac)
  fhat <- s$u[, idx, drop = FALSE] * sqrt(bigt)
  lambda <- t(y) %*% fhat / bigt
  ehat <- y - fhat %*% t(lambda)
  list(ehat = ehat, fhat = fhat, lambda = lambda, ve2 = rowMeans(ehat ^ 2), ss = s$d[idx])

}

# Compute Q^(-1/2) via eigendecomposition (base R, no external packages).
# Q must be symmetric positive definite.
.mat_neghalf <- function(Q) {

  ev <- eigen(Q, symmetric = TRUE)

  if (any(ev$values <= 0))
    stop("`.mat_neghalf()` requires a symmetric positive definite matrix.", call. = FALSE)

  ev$vectors %*% diag(ev$values ^ (-0.5), nrow = length(ev$values)) %*% t(ev$vectors)

}
