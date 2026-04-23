## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(sdim)

# Align dates: he2023_factors ends 12 months earlier than portfolio datasets
he2023_ff48 <- he2023_ff48vw[1:516, -1] / 100 - he2023_ff5$RF[127:642] / 100
G <- he2023_factors[1:516, -1] / 100

# First 6 columns are Fama-French 5 + momentum
f5 <- G[, 1:6]

## -----------------------------------------------------------------------------
nfact   <- c(1, 3, 5, 6, 10)
methods <- c("FF", "PCA", "PLS", "RRA")

total_r2 <- matrix(NA, nrow = length(methods), ncol = length(nfact))
rownames(total_r2) <- methods
colnames(total_r2) <- paste(nfact, "factors")

for (j in seq_along(nfact)) {

  k <- nfact[j]

  if (k <= 6) {
    total_r2["FF", j] <- eval_factors(he2023_ff48, f5[, 1:k])["TotalR2"]
  }

  fit_pca <- pca_est(target = he2023_ff48, X = G, nfac = k)
  total_r2["PCA", j] <- eval_factors(he2023_ff48, fit_pca$factors)["TotalR2"]

  fit_pls <- pls_est(target = he2023_ff48, X = G, nfac = k)
  total_r2["PLS", j] <- eval_factors(he2023_ff48, fit_pls$factors)["TotalR2"]

  fit_rra <- rra_est(target = he2023_ff48, X = G, nfac = k)
  total_r2["RRA", j] <- eval_factors(he2023_ff48, fit_rra$factors)["TotalR2"]

}

## -----------------------------------------------------------------------------
round(total_r2, 2)

