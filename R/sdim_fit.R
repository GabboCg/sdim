#' @export
print.sdim_fit <- function(x, ...) {

  cat(sprintf("<sdim_fit [%s]>\n", x$method))
  cat(" Observations :", nrow(x$factors), "\n")
  cat(" Predictors   :", nrow(x$lambda),  "\n")
  cat(" Factors      :", ncol(x$factors), "\n")
  invisible(x)

}

#' @export
summary.sdim_fit <- function(object, ...) {

  out <- list(
    call    = object$call,
    method  = object$method,
    n_obs   = nrow(object$factors),
    n_pred  = nrow(object$lambda),
    n_fac   = ncol(object$factors),
    eigvals = object$eigvals
  )

  if (!is.null(object$beta))
    out$beta_summary <- stats::quantile(object$beta, probs = c(0, .25, .5, .75, 1))
  if (!is.null(object$gmm_stat))
    out$gmm_stat <- object$gmm_stat

  class(out) <- "summary.sdim_fit"
  out

}

#' @export
print.summary.sdim_fit <- function(x, ...) {

  if (!is.null(x$call)) { cat("Call:\n"); print(x$call) }
  cat("\nModel size:\n")
  cat(" Observations :", x$n_obs,  "\n")
  cat(" Predictors   :", x$n_pred, "\n")
  cat(" Factors      :", x$n_fac,  "\n")
  cat("\nLeading eigenvalues:\n"); print(x$eigvals)

  if (!is.null(x$beta_summary)) {

    cat("\nSlope summary (sPCA):\n"); print(x$beta_summary)

  }

  if (!is.null(x$gmm_stat)) {

    cat(sprintf("\nGMM statistic (RRA): %.4f  p-value: %.4f\n", x$gmm_stat$stat, x$gmm_stat$pvalue))

  }

  invisible(x)

}

#' @export
plot.sdim_fit <- function(x, index = NULL, ...) {

  K     <- ncol(x$factors)
  n_obs <- nrow(x$factors)
  idx   <- if (is.null(index)) seq_len(n_obs) else index

  # Shrink margins as K grows so panels fit; x-axis only on bottom panel
  bot <- max(1.5, 3 - 0.3 * K)
  top <- max(0.5, 2 - 0.2 * K)
  op  <- graphics::par(mfrow = c(K, 1L), mar = c(top, 4, top, 0.5))
  on.exit(graphics::par(op))

  for (k in seq_len(K)) {

    xlab <- if (k == K) "index" else ""
    graphics::par(mar = c(if (k == K) bot else 0.5, 4, top, 0.5))
    graphics::plot(idx, x$factors[, k], type = "l",
                   ylab = paste0("F", k), xlab = xlab,
                   main = sprintf("%s  Factor %d", toupper(x$method), k))

  }

  invisible(x)

}

#' @export
print.sdim_list <- function(x, ...) {

  cat(sprintf("<sdim_list: %d method(s)>\n\n", length(x)))
  methods <- names(x)
  header  <- sprintf("%-8s %6s %6s %6s %12s", "method", "T", "N", "nfac", "eigval[1]")
  cat(header, "\n")
  cat(strrep("-", nchar(header)), "\n")

  for (m in methods) {

    fit <- x[[m]]
    cat(sprintf("%-8s %6d %6d %6d %12.4f\n",
                m,
                nrow(fit$factors),
                nrow(fit$lambda),
                ncol(fit$factors),
                fit$eigvals[1]))

  }

  invisible(x)

}
