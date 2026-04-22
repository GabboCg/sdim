# PLS factor extraction (Matlab-faithful NIPALS algorithm)

PLS factor extraction (Matlab-faithful NIPALS algorithm)

## Usage

``` r
pls_est(target, X, nfac)
```

## Arguments

- target:

  Numeric matrix (T x N) of target variables (e.g., asset returns). A
  vector is coerced to a T x 1 matrix.

- X:

  Numeric matrix or data frame (T x L) of factor proxies.

- nfac:

  Positive integer; number of PLS components to extract.

## Value

An object of class `"sdim_fit"`.

## References

He, Huang, Li, Zhou (2023)
[doi:10.1287/mnsc.2022.4428](https://doi.org/10.1287/mnsc.2022.4428)

## Examples

``` r
set.seed(1)
X <- matrix(rnorm(100 * 8), 100, 8)
Y <- matrix(rnorm(100 * 5), 100, 5)
fit <- pls_est(target = Y, X = X, nfac = 3)
print(fit)
#> <sdim_fit [pls]>
#>  Observations : 100 
#>  Predictors   : 8 
#>  Factors      : 3 
```
