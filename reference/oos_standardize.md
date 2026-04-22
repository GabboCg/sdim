# Standardize columns to zero mean and unit variance

Standardize columns to zero mean and unit variance

## Usage

``` r
oos_standardize(X)
```

## Arguments

- X:

  A numeric matrix.

## Value

A matrix with the same dimensions as `X`, where each column has been
centred and scaled to unit variance.

## Examples

``` r
X <- matrix(rnorm(100), 20, 5)
Xs <- oos_standardize(X)
round(colMeans(Xs), 10)
#> [1] 0 0 0 0 0
round(apply(Xs, 2, sd), 10)
#> [1] 1 1 1 1 1
```
