# Industrial production growth from Huang, Jiang, Li, Tong, Zhou (2022)

Monthly growth rate of U.S. industrial production, computed as the first
difference of the log IP index, spanning January 1960 to December 2019
(720 months). Used as the forecast target in the out-of-sample
replication of Table 4 from Huang et al. (2022).

## Usage

``` r
huang2022_ip
```

## Format

A numeric vector of length 720 containing monthly log-differences of the
Industrial Production Index. The `"dates"` attribute is an integer
vector of dates in `YYYYMM` format (196001 to 201912).

## Source

Replication package of Huang, Jiang, Li, Tong, and Zhou (2022),
available at
<https://pubsonline.informs.org/doi/10.1287/mnsc.2021.4020>.

## Note

The IP growth target is constructed from raw IP levels provided in the
authors' replication package, independently from the INDPRO series in
[`huang2022_macro`](https://gabbocg.github.io/sdim/reference/huang2022_macro.md)
(which uses the FRED-MD transformation code). The two series are
numerically identical for this variable.

See the replication script in `inst/replications/huang2022_table4.R`.

## References

Huang, D., Jiang, F., Li, K., Tong, G., and Zhou, G. (2022). Scaled PCA:
A New Approach to Dimension Reduction. *Management Science*, 68(3),
1678–1695.
[doi:10.1287/mnsc.2021.4020](https://doi.org/10.1287/mnsc.2021.4020)

## Examples

``` r
data(huang2022_ip)
length(huang2022_ip)   # 720
#> [1] 720
head(huang2022_ip)
#> [1]  0.025915554 -0.008936898 -0.009017487 -0.007961168 -0.001142501
#> [6] -0.012650248
```
