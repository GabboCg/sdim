#' @export
print.sdim_fit <- function(x, ...) {

  if (x$method == "ipca") {
    cat(sprintf("<sdim_fit [%s]>\n", x$method))
    cat(" Observations    :", nrow(x$factors), "\n")
    cat(" Characteristics :", nrow(x$lambda),  "\n")
    cat(" Factors         :", ncol(x$factors), "\n")
    return(invisible(x))
  }

  cat(sprintf("<sdim_fit [%s]>\n", x$method))
  cat(" Observations :", nrow(x$factors), "\n")
  cat(" Predictors   :", nrow(x$lambda),  "\n")
  cat(" Factors      :", ncol(x$factors), "\n")
  invisible(x)

}

#' @export
summary.sdim_fit <- function(object, ...) {

  eigvals <- object$eigvals
  ve      <- 100 * eigvals / sum(eigvals)

  out <- list(
    call    = object$call,
    method  = object$method,
    n_obs   = nrow(object$factors),
    n_pred  = nrow(object$lambda),
    n_fac   = ncol(object$factors),
    eigvals = eigvals,
    ve      = ve
  )

  if (!is.null(object$gamma))
    out$gamma <- object$gamma
  if (!is.null(object$gmm_stat))
    out$gmm_stat <- object$gmm_stat

  class(out) <- "summary.sdim_fit"
  out

}

#' @export
print.summary.sdim_fit <- function(x, ...) {

  rule <- strrep("-", 40)

  method_label <- switch(x$method,
    pca  = "Principal Component Analysis (PCA)",
    pls  = "Partial Least Squares (PLS)",
    rra  = "Reduced-Rank Approach (RRA)",
    ipca = "Instrumented Principal Components Analysis (IPCA)",
    toupper(x$method)
  )

  cat(method_label, "\n")
  cat(rule, "\n")
  if (!is.null(x$call)) { cat("Call: "); print(x$call) }

  cat("\nDimensions\n")
  cat(rule, "\n")
  cat(sprintf(" %-16s %d\n", "Observations", x$n_obs))
  pred_label <- if (x$method == "ipca") "Characteristics" else "Predictors"
  cat(sprintf(" %-16s %d\n", pred_label, x$n_pred))
  cat(sprintf(" %-16s %d\n", "Factors",       x$n_fac))

  if (!is.null(x$gamma))
    cat(sprintf(" %-16s %g\n", "gamma (PCA)",  x$gamma))

  cat("\nEigenvalues\n")
  cat(rule, "\n")
  fnames <- paste0("F", seq_len(x$n_fac))
  ev_tbl <- rbind(Eigenvalue     = round(x$eigvals, 4),
                  `Var. expl. (%)` = round(x$ve, 2))
  colnames(ev_tbl) <- fnames
  print(ev_tbl, quote = FALSE)

  if (!is.null(x$gmm_stat)) {

    cat("\nGMM overidentification test\n")
    cat(rule, "\n")
    cat(sprintf(" %-16s %.4f\n", "J statistic", x$gmm_stat$stat))
    cat(sprintf(" %-16s %d\n",   "df",           x$gmm_stat$df))
    cat(sprintf(" %-16s %.4f\n", "p-value",      x$gmm_stat$pvalue))

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
