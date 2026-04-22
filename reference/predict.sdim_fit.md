# Project new data onto estimated factor loadings

Project new data onto estimated factor loadings

## Usage

``` r
# S3 method for class 'sdim_fit'
predict(object, newdata, ...)
```

## Arguments

- object:

  An object of class `"sdim_fit"`.

- newdata:

  A numeric matrix or data frame with the same number of columns as the
  original predictor matrix.

- ...:

  Additional arguments (currently ignored).

## Value

A numeric matrix of projected factors with `nrow(newdata)` rows and
`ncol(object$factors)` columns.
