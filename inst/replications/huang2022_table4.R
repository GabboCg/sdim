## ============================================================================
## Replication of Table 4 from Huang, Jiang, Li, Tong, and Zhou (2022)
## "Scaled PCA: A New Approach to Dimension Reduction", Management Science
##
## Target: IP growth (exact replication: PCA = 7.88%, sPCA = 13.17%)
## Methods: AR benchmark (SIC lag), PCA (sdim::pca_est), sPCA (sdim::spca_est)
## ============================================================================

devtools::load_all(".", quiet = TRUE)

# ---------- 1. Load data -----------------------------------------------------

data(huang2022_macro)  # 720 x 123 matrix of transformed FRED-MD predictors
data(huang2022_ip)     # 720-vector of IP growth (dlog IP, 196001-201912)

Z    <- huang2022_macro
y_ip <- huang2022_ip

cat("Predictors Z:", nrow(Z), "x", ncol(Z), "\n")
cat("IP growth y:", length(y_ip), "\n")

# ---------- 2. Out-of-sample forecasting loop ---------------------------------

run_oos <- function(y, Z, h = 1, p_max = 1, nfac_max = 5) {

  TT <- length(y)
  M  <- (1984 - 1959) * 12  # initial in-sample: Jan 1960 - Dec 1984
  N  <- TT - M

  FC_AR    <- rep(NA, N - (h - 1))
  FC_PCA   <- matrix(NA, N - (h - 1), nfac_max)
  FC_sPCA  <- matrix(NA, N - (h - 1), nfac_max)
  actual_y <- rep(NA, N - (h - 1))

  pb <- txtProgressBar(min = 0, max = N - (h - 1), style = 3)

  for (n in seq_len(N - (h - 1))) {

    # Actual value
    actual_y[n] <- mean(y[(M + n):(M + n + h - 1)])

    # Training data
    y_n  <- y[1:(M + n - 1)]
    Z_n  <- Z[1:(M + n - 1), ]
    Zs_n <- .oos_standardize(Z_n)

    T_n   <- length(y_n)
    y_n_h <- vapply(seq_len(T_n - (h - 1)),
                    function(t) mean(y_n[t:(t + h - 1)]),
                    numeric(1))

    # AR benchmark with SIC lag selection
    p_ar <- .select_ar_lag_sic(y_n, h, p_max)

    if (p_ar > 0) {

      ar_out   <- .estimate_ar_res(y_n, h, p_ar)
      y_n_last <- rev(y_n[(T_n - p_ar + 1):T_n])
      FC_AR[n] <- sum(c(1, y_n_last) * ar_out$a_hat)

    } else {

      FC_AR[n] <- mean(y_n)

    }

    # PCA factors via sdim::pca_est
    pca_fit <- pca_est(X = Zs_n, nfac = nfac_max)
    z_pc_n  <- predict(pca_fit, Zs_n)

    # sPCA factors via sdim::spca_est (predictive alignment + winsorization)
    spca_fit <- spca_est(
      target       = y_n_h[2:length(y_n_h)],
      X            = Z_n,
      nfac         = nfac_max,
      winsorize    = TRUE,
      winsor_probs = c(0, 90)
    )
    z_trans_n <- predict(spca_fit, Z_n)

    # Forecast with ARDL for each number of factors
    for (cc in seq_len(nfac_max)) {

      for (jj in 1:2) {

        z_factor_n <- if (jj == 1) {
          z_pc_n[, 1:cc, drop = FALSE]
        } else {
          z_trans_n[, 1:cc, drop = FALSE]
        }

        p_ardl <- c(p_ar, 1)

        if (p_ar > 0) {

          c_hat    <- .estimate_ardl_multi(y_n, z_factor_n, h, p_ardl)
          y_n_last <- rev(y_n[(T_n - p_ar + 1):T_n])
          fc       <- sum(c(1, y_n_last, z_factor_n[T_n, ]) * c_hat)

        } else {

          dep   <- y_n_h[2:length(y_n_h)]
          reg   <- cbind(1, z_factor_n[1:(length(y_n_h) - 1 - (h - 1)), 1:cc])
          c_hat <- stats::lm.fit(x = reg, y = dep)$coefficients
          fc    <- sum(c(1, z_factor_n[T_n, 1:cc]) * c_hat)

        }

        if (jj == 1) FC_PCA[n, cc]  <- fc
        if (jj == 2) FC_sPCA[n, cc] <- fc

      }

    }

    setTxtProgressBar(pb, n)

  }

  close(pb)

  # Compute R^2_OS for each number of factors
  r2_pca  <- numeric(nfac_max)
  r2_spca <- numeric(nfac_max)

  for (cc in seq_len(nfac_max)) {

    sse_ar   <- sum((actual_y - FC_AR) ^ 2)
    sse_pca  <- sum((actual_y - FC_PCA[, cc]) ^ 2)
    sse_spca <- sum((actual_y - FC_sPCA[, cc]) ^ 2)
    r2_pca[cc]  <- 100 * (1 - sse_pca / sse_ar)
    r2_spca[cc] <- 100 * (1 - sse_spca / sse_ar)

  }

  list(
    r2_pca = r2_pca, r2_spca = r2_spca, actual = actual_y,
    fc_ar = FC_AR, fc_pca = FC_PCA, fc_spca = FC_sPCA
  )

}

# ---------- 3. Run for IP growth (h=1) ----------------------------------------

cat("\n=== IP Growth (h=1, p_max=1) ===\n")
res_ip <- run_oos(y_ip, Z, h = 1, p_max = 1, nfac_max = 5)

# ---------- 4. Summary table -------------------------------------------------

cat("\n\n")
cat("=================================================================\n")
cat("  Table 4 Replication: Out-of-Sample R^2_OS (%)\n")
cat("  Huang, Jiang, Li, Tong, and Zhou (2022, Management Science)\n")
cat("=================================================================\n\n")

cat("R^2_OS by number of factors (IP growth):\n")
cat(sprintf("  K  %8s %8s\n", "PCA", "sPCA"))
cat(strrep("-", 26), "\n")

for (k in seq_along(res_ip$r2_pca)) {

  cat(sprintf("  %d  %8.2f %8.2f\n", k, res_ip$r2_pca[k], res_ip$r2_spca[k]))

}

cat(strrep("-", 26), "\n")
