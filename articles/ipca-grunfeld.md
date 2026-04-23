# IPCA with the Grunfeld dataset

This vignette demonstrates the IPCA estimator using the Grunfeld (1958)
investment dataset, a classic panel of 11 US firms observed over 20
years (1935–1954). Results are validated against the Python `ipca`
package (Kelly, Pruitt, and Su, 2019).

## The IPCA model

Instrumented PCA extracts latent factors from panel data where
asset-specific characteristics serve as instruments. The model is

\\r\_{i,t} = \mathbf{z}\_{i,t}^\top \boldsymbol{\Gamma} \mathbf{f}\_t +
\varepsilon\_{i,t}\\

where \\r\_{i,t}\\ is the return (here, investment) of asset \\i\\ at
time \\t\\, \\\mathbf{z}\_{i,t}\\ is an \\L\\-vector of characteristics,
\\\boldsymbol{\Gamma}\\ is the \\L \times K\\ matrix of characteristic
loadings, and \\\mathbf{f}\_t\\ is the \\K\\-vector of latent factors.

Estimation alternates between solving for \\\mathbf{f}\_t\\ given
\\\boldsymbol{\Gamma}\\ and updating \\\boldsymbol{\Gamma}\\ given
\\\mathbf{f}\_t\\ (ALS), with an SVD normalization step to ensure
\\\boldsymbol{\Gamma}^\top \boldsymbol{\Gamma} = \mathbf{I}\_K\\.

## Data preparation

The Grunfeld dataset ships with **sdim**. The dependent variable is
gross investment (`invest`) and the two characteristics are market value
(`value`) and capital stock (`capital`).

``` r
library(sdim)

data(grunfeld)
str(grunfeld)
#> 'data.frame':    220 obs. of  5 variables:
#>  $ firm   : chr  "American Steel" "American Steel" "American Steel" "American Steel" ...
#>  $ year   : int  1935 1936 1937 1938 1939 1940 1941 1942 1943 1944 ...
#>  $ invest : num  2.94 5.64 10.23 4.05 3.33 ...
#>  $ value  : num  30.3 43.9 107 68.3 84.2 ...
#>  $ capital: num  52 52.9 54.5 59.7 61.7 ...
```

[`ipca_est()`](https://gabbocg.github.io/sdim/reference/ipca_est.md)
expects a \\T \times N\\ return matrix and a \\T \times N \times L\\
characteristics array:

``` r
firms <- sort(unique(grunfeld$firm))
years <- sort(unique(grunfeld$year))
N  <- length(firms)
TT <- length(years)

ret <- matrix(NA_real_, TT, N,
              dimnames = list(years, firms))
Z   <- array(NA_real_, dim = c(TT, N, 2),
             dimnames = list(years, firms, c("value", "capital")))

for (i in seq_along(firms)) {
  idx <- grunfeld$firm == firms[i]
  ret[, i]  <- grunfeld$invest[idx]
  Z[, i, 1] <- grunfeld$value[idx]
  Z[, i, 2] <- grunfeld$capital[idx]
}

cat("ret:", nrow(ret), "x", ncol(ret), "\n")
#> ret: 20 x 11
cat("Z:  ", paste(dim(Z), collapse = " x "), "\n")
#> Z:   20 x 11 x 2
```

## Fitting IPCA

Extract one latent factor:

``` r
fit <- ipca_est(ret, Z, nfac = 1)
print(fit)
#> <sdim_fit [ipca]>
#>  Observations    : 20 
#>  Characteristics : 2 
#>  Factors         : 1 
#>  Factor mean     : zero
summary(fit)
#> Instrumented Principal Components Analysis (IPCA) 
#> ---------------------------------------- 
#> Call: ipca_est(ret = ret, Z = Z, nfac = 1)
#> 
#> Dimensions
#> ---------------------------------------- 
#>  Observations     20
#>  Characteristics  2
#>  Factors          1
#>  Factor mean      zero
#> 
#> Eigenvalues
#> ---------------------------------------- 
#>                     F1
#> Eigenvalue       0.019
#> Var. expl. (%) 100.000
```

The returned object contains the characteristic loadings
(\\\boldsymbol{\Gamma}\\, stored as `lambda`) and the estimated factors:

``` r
# Gamma: how each characteristic maps to the factor
fit$lambda
#>           [,1]
#> [1,] 0.9916601
#> [2,] 0.1288805

# Factors over time
data.frame(year = years, factor = fit$factors[, 1])
#>    year     factor
#> 1  1935 0.10319684
#> 2  1936 0.08844895
#> 3  1937 0.08384966
#> 4  1938 0.08450699
#> 5  1939 0.07225234
#> 6  1940 0.09950682
#> 7  1941 0.12288401
#> 8  1942 0.14226238
#> 9  1943 0.11975320
#> 10 1944 0.11797240
#> 11 1945 0.10875619
#> 12 1946 0.13575212
#> 13 1947 0.15793483
#> 14 1948 0.16605454
#> 15 1949 0.14849233
#> 16 1950 0.15866343
#> 17 1951 0.15960074
#> 18 1952 0.17593792
#> 19 1953 0.19216956
#> 20 1954 0.21110659
```

## Validation against the Python `ipca` package

The Python `ipca` package implements the same ALS algorithm using the
Grunfeld dataset as its example. With `n_factors = 1` and no intercept,
the Python output is:

``` r
py_gamma   <- c(0.99166014, 0.12888046)
py_factors <- c(
  0.1031968381, 0.0884489515, 0.0838496628, 0.0845069923, 0.0722523449,
  0.0995068155, 0.1228840058, 0.1422623752, 0.1197532025, 0.1179724004,
  0.1087561863, 0.1357521189, 0.1579348267, 0.1660545375, 0.1484923276,
  0.1586634303, 0.1596007400, 0.1759379247, 0.1921695585, 0.2111065868
)
```

Compare loadings and factors (sign-aligned):

``` r
r_gamma <- as.numeric(fit$lambda)
r_factors <- as.numeric(fit$factors)

# Sign-align if needed
if (cor(r_gamma, py_gamma) < 0) {
  r_gamma   <- -r_gamma
  r_factors <- -r_factors
}

cat("Gamma max |diff|:  ", sprintf("%.2e", max(abs(r_gamma - py_gamma))), "\n")
#> Gamma max |diff|:   3.58e-09
cat("Factor max |diff|: ", sprintf("%.2e", max(abs(r_factors - py_factors))), "\n")
#> Factor max |diff|:  4.99e-11
cat("Factor correlation:", sprintf("%.10f", cor(r_factors, py_factors)), "\n")
#> Factor correlation: 1.0000000000
```

## Multiple factors

IPCA can also extract more than one factor. With \\K = 2\\ (both
characteristics contribute their own factor dimension):

``` r
fit2 <- ipca_est(ret, Z, nfac = 2)
summary(fit2)
#> Instrumented Principal Components Analysis (IPCA) 
#> ---------------------------------------- 
#> Call: ipca_est(ret = ret, Z = Z, nfac = 2)
#> 
#> Dimensions
#> ---------------------------------------- 
#>  Observations     20
#>  Characteristics  2
#>  Factors          2
#>  Factor mean      zero
#> 
#> Eigenvalues
#> ---------------------------------------- 
#>                     F1      F2
#> Eigenvalue      0.0073  0.0197
#> Var. expl. (%) 27.0200 72.9800
```

## References

Grunfeld, Y. (1958). The Determinants of Corporate Investment.
Ph.D. thesis, Department of Economics, University of Chicago.

Kelly, B. T., Pruitt, S., and Su, Y. (2019). Characteristics are
Covariances: A Unified Model of Risk and Return. *Journal of Financial
Economics*, 134(3), 501–524. DOI:
[10.1016/j.jfineco.2019.05.001](https://doi.org/10.1016/j.jfineco.2019.05.001)
