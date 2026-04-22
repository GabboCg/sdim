# Project new data onto estimated sPCA factor loadings

Standardizes `newdata` using the training column means and standard
deviations, scales by the estimated (possibly winsorized) regression
slopes, and projects onto the sPCA loadings.

## Usage

``` r
# S3 method for class 'sdim_spca'
predict(object, newdata, ...)
```

## Arguments

- object:

  An object of class `"sdim_spca"`.

- newdata:

  A numeric matrix or data frame with the same number of columns as the
  original predictor matrix.

- ...:

  Additional arguments (currently ignored).

## Value

A numeric matrix of projected factors with `nrow(newdata)` rows and
`ncol(object$factors)` columns.
