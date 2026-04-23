## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(sdim)

data(huang2022_macro)
data(huang2022_ip)

dim(huang2022_macro)
length(huang2022_ip)

## ----eval = FALSE-------------------------------------------------------------
# run_oos <- function(y, Z, h = 1, p_max = 1, nfac_max = 5) {
# 
#   TT <- length(y)
#   M  <- (1984 - 1959) * 12
#   NN <- TT - M
# 
#   FC_AR    <- rep(NA, NN - (h - 1))
#   FC_PCA   <- matrix(NA, NN - (h - 1), nfac_max)
#   FC_sPCA  <- matrix(NA, NN - (h - 1), nfac_max)
#   actual_y <- rep(NA, NN - (h - 1))
# 
#   for (n in seq_len(NN - (h - 1))) {
# 
#     actual_y[n] <- mean(y[(M + n):(M + n + h - 1)])
# 
#     y_n  <- y[1:(M + n - 1)]
#     Z_n  <- Z[1:(M + n - 1), ]
#     Zs_n <- oos_standardize(Z_n)
#     T_n  <- length(y_n)
# 
#     y_n_h <- vapply(
#       seq_len(T_n - (h - 1)),
#       function(t) mean(y_n[t:(t + h - 1)]),
#       numeric(1)
#     )
# 
#     # --- AR benchmark with SIC lag selection ---
#     p_ar <- select_ar_lag_sic(y_n, h, p_max)
# 
#     if (p_ar > 0L) {
# 
#       ar_out   <- estimate_ar_res(y_n, h, p_ar)
#       y_n_last <- rev(y_n[(T_n - p_ar + 1):T_n])
#       FC_AR[n] <- sum(c(1, y_n_last) * ar_out$a_hat)
# 
#     } else {
# 
#       FC_AR[n] <- mean(y_n)
# 
#     }
# 
#     # --- PCA factors ---
#     pca_fit <- pca_est(X = Zs_n, nfac = nfac_max)
#     z_pc_n  <- predict(pca_fit, Zs_n)
# 
#     # --- sPCA factors (predictive alignment + winsorization) ---
#     spca_fit <- spca_est(
#       target       = y_n_h[2:length(y_n_h)],
#       X            = Z_n,
#       nfac         = nfac_max,
#       winsorize    = TRUE,
#       winsor_probs = c(0, 90)
#     )
# 
#     z_trans_n <- predict(spca_fit, Z_n)
# 
#     # --- ARDL forecast for each number of factors ---
#     for (cc in seq_len(nfac_max)) {
# 
#       for (jj in 1:2) {
# 
#         z_f <- if (jj == 1) {
# 
#           z_pc_n[, 1:cc, drop = FALSE]
# 
#         } else {
# 
#           z_trans_n[, 1:cc, drop = FALSE]
# 
#         }
# 
#         p_ardl <- c(p_ar, 1)
# 
#         if (p_ar > 0L) {
# 
#           c_hat    <- estimate_ardl_multi(y_n, z_f, h, p_ardl)
#           y_n_last <- rev(y_n[(T_n - p_ar + 1):T_n])
#           fc       <- sum(c(1, y_n_last, z_f[T_n, ]) * c_hat)
# 
#         } else {
# 
#           dep   <- y_n_h[2:length(y_n_h)]
#           reg   <- cbind(1, z_f[1:(length(y_n_h) - 1 - (h - 1)), 1:cc])
#           c_hat <- lm.fit(x = reg, y = dep)$coefficients
#           fc    <- sum(c(1, z_f[T_n, 1:cc]) * c_hat)
# 
#         }
# 
#         if (jj == 1) FC_PCA[n, cc]  <- fc
#         if (jj == 2) FC_sPCA[n, cc] <- fc
# 
#       }
# 
#     }
# 
#   }
# 
#   # R²_OS for each number of factors
#   r2_pca <- r2_spca <- numeric(nfac_max)
#   sse_ar <- sum((actual_y - FC_AR)^2)
# 
#   for (cc in seq_len(nfac_max)) {
# 
#     r2_pca[cc]  <- 100 * (1 - sum((actual_y - FC_PCA[, cc])^2)  / sse_ar)
#     r2_spca[cc] <- 100 * (1 - sum((actual_y - FC_sPCA[, cc])^2) / sse_ar)
# 
#   }
# 
#   data.frame(K = seq_len(nfac_max), PCA = round(r2_pca, 2), sPCA = round(r2_spca, 2))
# 
# }
# 
# # Run
# res <- run_oos(huang2022_ip, huang2022_macro, h = 1, p_max = 1, nfac_max = 5)
# print(res)

