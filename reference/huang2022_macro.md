# FRED-MD macro predictors from Huang, Jiang, Li, Tong, Zhou (2022)

Monthly observations on 123 macroeconomic variables from the FRED-MD
database (McCracken and Ng, 2016), spanning January 1960 to December
2019 (720 months). Variables are transformed for stationarity using the
transformation codes listed in the online data appendix of the paper.
Covers output and income, labour market, consumption, housing,
inventories and orders, money and credit, interest rates, exchange
rates, and prices.

## Usage

``` r
huang2022_macro
```

## Format

A numeric matrix with 720 rows and 123 columns. Each column is a
macroeconomic time series transformed for stationarity following
McCracken and Ng (2016). Column names correspond to FRED-MD mnemonics.
The `"dates"` attribute is an integer vector of dates in `YYYYMM` format
(196001 to 201912).

## Source

Replication package of Huang, Jiang, Li, Tong, and Zhou (2022),
available at
<https://pubsonline.informs.org/doi/10.1287/mnsc.2021.4020>.

## Note

This dataset is used together with
[`huang2022_ip`](https://gabbocg.github.io/sdim/reference/huang2022_ip.md)
in the replication of Table 4 from Huang et al. (2022). See the
replication script in `inst/replications/huang2022_table4.R`.

## References

Huang, D., Jiang, F., Li, K., Tong, G., and Zhou, G. (2022). Scaled PCA:
A New Approach to Dimension Reduction. *Management Science*, 68(3),
1678–1695.
[doi:10.1287/mnsc.2021.4020](https://doi.org/10.1287/mnsc.2021.4020)

McCracken, M. W. and Ng, S. (2016). FRED-MD: A Monthly Database for
Macroeconomic Research. *Journal of Business \\ Economic Statistics*,
34(4), 574–589.
[doi:10.1080/07350015.2015.1086655](https://doi.org/10.1080/07350015.2015.1086655)

## Examples

``` r
data(huang2022_macro)
dim(huang2022_macro)        # 720 x 123
#> [1] 720 123
head(colnames(huang2022_macro), 10)
#>                                                                         
#>             "RPI"         "W875RX1" "DPCERA3M086SBEA"       "CMRMTSPLx" 
#>                                                                         
#>         "RETAILx"          "INDPRO"         "IPFPNSS"         "IPFINAL" 
#>                                     
#>         "IPCONGD"        "IPDCONGD" 
```
