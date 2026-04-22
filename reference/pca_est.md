# PCA factor extraction

PCA factor extraction

## Usage

``` r
pca_est(target = NULL, X, nfac, gamma = -1)
```

## Arguments

- target:

  Ignored; accepted for API uniformity with other estimators.

- X:

  Numeric matrix or data frame (T x L) of factor proxies.

- nfac:

  Positive integer; number of factors to extract.

- gamma:

  Numeric scalar controlling mean adjustment in the second-moment
  matrix. \`gamma = -1\` (default) gives the sample covariance
  (traditional PCA). \`gamma = 10\` and \`gamma = 1\` give the
  Lettau-Ludvigson variants from He et al. (2023).

## Value

An object of class `"sdim_fit"`.

## References

He, J., Huang, J., Li, F., and Zhou, G. (2023). Shrinking Factor
Dimension: A Reduced-Rank Approach. \*Management Science\*, 69(9).
[doi:10.1287/mnsc.2022.4428](https://doi.org/10.1287/mnsc.2022.4428)

## Examples

``` r
set.seed(1)
X <- matrix(rnorm(100 * 8), 100, 8)
fit <- pca_est(X = X, nfac = 3)
print(fit)
#> <sdim_fit [pca]>
#>  Observations : 100 
#>  Predictors   : 8 
#>  Factors      : 3 
```
