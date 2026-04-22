# Package index

## Factor Extraction

Core estimation functions for supervised dimension reduction.

- [`pca_est()`](https://gabbocg.github.io/sdim/reference/pca_est.md) :
  PCA factor extraction
- [`pls_est()`](https://gabbocg.github.io/sdim/reference/pls_est.md) :
  PLS factor extraction (Matlab-faithful NIPALS algorithm)
- [`spca_est()`](https://gabbocg.github.io/sdim/reference/spca_est.md) :
  Scaled PCA factor extraction
- [`rra_est()`](https://gabbocg.github.io/sdim/reference/rra_est.md) :
  Reduced-Rank Approach (RRA) factor extraction
- [`ipca_est()`](https://gabbocg.github.io/sdim/reference/ipca_est.md) :
  IPCA factor extraction

## Prediction

Project new data onto estimated factor loadings.

- [`predict(`*`<sdim_fit>`*`)`](https://gabbocg.github.io/sdim/reference/predict.sdim_fit.md)
  : Project new data onto estimated factor loadings
- [`predict(`*`<sdim_spca>`*`)`](https://gabbocg.github.io/sdim/reference/predict.sdim_spca.md)
  : Project new data onto estimated sPCA factor loadings

## Evaluation

Evaluate extracted factors.

- [`eval_factors()`](https://gabbocg.github.io/sdim/reference/eval_factors.md)
  : Evaluate extracted factors against target returns

## Datasets

Bundled datasets for replication and examples.

- [`he2023_dacheng202`](https://gabbocg.github.io/sdim/reference/he2023_dacheng202.md)
  : Dacheng 202-portfolio value-weighted returns from He, Huang, Li,
  Zhou (2023)
- [`he2023_factors`](https://gabbocg.github.io/sdim/reference/he2023_factors.md)
  : Factor proxies from He, Huang, Li, Zhou (2023)
- [`he2023_ff17vw`](https://gabbocg.github.io/sdim/reference/he2023_ff17vw.md)
  : Fama-French 17-industry value-weighted portfolios from He, Huang,
  Li, Zhou (2023)
- [`he2023_ff30vw`](https://gabbocg.github.io/sdim/reference/he2023_ff30vw.md)
  : Fama-French 30-industry value-weighted portfolios from He, Huang,
  Li, Zhou (2023)
- [`he2023_ff48ew`](https://gabbocg.github.io/sdim/reference/he2023_ff48ew.md)
  : Fama-French 48-industry equal-weighted portfolios from He, Huang,
  Li, Zhou (2023)
- [`he2023_ff48vw`](https://gabbocg.github.io/sdim/reference/he2023_ff48vw.md)
  : Fama-French 48-industry value-weighted portfolios from He, Huang,
  Li, Zhou (2023)
- [`he2023_ff5`](https://gabbocg.github.io/sdim/reference/he2023_ff5.md)
  : Fama-French 5-factor data from He, Huang, Li, Zhou (2023)
- [`huang2022_ip`](https://gabbocg.github.io/sdim/reference/huang2022_ip.md)
  : Industrial production growth from Huang, Jiang, Li, Tong, Zhou
  (2022)
- [`huang2022_macro`](https://gabbocg.github.io/sdim/reference/huang2022_macro.md)
  : FRED-MD macro predictors from Huang, Jiang, Li, Tong, Zhou (2022)
