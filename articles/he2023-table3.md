# Replicating He et al. (2023)

This vignette replicates Table 3 from He, Huang, Li, and Zhou (2023),
“Shrinking Factor Dimension: A Reduced-Rank Approach,” *Management
Science*, 69(9).

The table reports the total adjusted \\R^2\\ (%) of pricing 48
Fama-French value-weighted industry portfolios using factors extracted
by four methods: the Fama-French factors directly (FF), PCA, PLS, and
RRA.

## Setup

``` r
library(sdim)

# Align dates: he2023_factors ends 12 months earlier than portfolio datasets
he2023_ff48 <- he2023_ff48vw[1:516, -1] / 100 - he2023_ff5$RF[127:642] / 100
G <- he2023_factors[1:516, -1] / 100

# First 6 columns are Fama-French 5 + momentum
f5 <- G[, 1:6]
```

## Replication

``` r
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
```

## Results

``` r
round(total_r2, 2)
#>     1 factors 3 factors 5 factors 6 factors 10 factors
#> FF      51.39     55.57     57.77     58.34         NA
#> PCA     16.74     20.49     29.91     33.13      40.78
#> PLS     23.42     47.19     58.97     61.10      64.28
#> RRA     54.60     61.11     64.75     65.38      67.40
```

The RRA consistently achieves the highest total \\R^2\\ across all
factor counts, confirming the main finding of He et al. (2023): the
reduced-rank approach effectively shrinks factor dimension while
retaining pricing information.

## References

He, J., Huang, J., Li, F., and Zhou, G. (2023). Shrinking Factor
Dimension: A Reduced-Rank Approach. *Management Science*, 69(9). DOI:
[10.1287/mnsc.2022.4563](https://doi.org/10.1287/mnsc.2022.4563)
