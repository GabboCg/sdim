#' Grunfeld (1958) investment dataset
#'
#' Panel data on gross investment for 11 US firms over 20 years (1935--1954),
#' originally from Grunfeld (1958). This is a classic panel dataset used for
#' validating the IPCA estimator against the Python \code{ipca} package
#' (Kelly, Pruitt, Su, 2019).
#'
#' @format A data.frame with 220 rows and 5 variables:
#' \describe{
#'   \item{firm}{Character; firm name (11 unique firms).}
#'   \item{year}{Integer; year of observation (1935--1954).}
#'   \item{invest}{Numeric; gross investment (millions of dollars).}
#'   \item{value}{Numeric; market value of the firm (millions of dollars).}
#'   \item{capital}{Numeric; stock of plant and equipment (millions of dollars).}
#' }
#' @source Grunfeld, Y. (1958). The Determinants of Corporate Investment.
#'   Ph.D. thesis, Department of Economics, University of Chicago.
#'   Loaded from the \code{statsmodels} Python package
#'   (\code{statsmodels.datasets.grunfeld}).
#' @references Kelly, B. T., Pruitt, S., and Su, Y. (2019).
#'   Characteristics are Covariances: A Unified Model of Risk and Return.
#'   \emph{Journal of Financial Economics}, 134(3), 501--524.
#'   \doi{10.1016/j.jfineco.2019.05.001}
#' @keywords datasets
#' @examples
#' head(grunfeld)
#'
#' # Reshape for ipca_est(): T x N matrix and T x N x L array
#' firms <- sort(unique(grunfeld$firm))
#' years <- sort(unique(grunfeld$year))
#' N <- length(firms)
#' TT <- length(years)
#'
#' ret <- matrix(NA, TT, N)
#' Z   <- array(NA, dim = c(TT, N, 2))
#' for (i in seq_along(firms)) {
#'   idx <- grunfeld$firm == firms[i]
#'   ret[, i]  <- grunfeld$invest[idx]
#'   Z[, i, 1] <- grunfeld$value[idx]
#'   Z[, i, 2] <- grunfeld$capital[idx]
#' }
#'
#' fit <- ipca_est(ret, Z, nfac = 1)
#' print(fit)
"grunfeld"

#' Factor proxies from He, Huang, Li, Zhou (2023)
#'
#' Monthly returns on 70 factor proxies from the replication package of He,
#' Huang, Li, Zhou (2023): the five Fama-French factors (MKT, SMB, HML, RMW,
#' CMA) plus 65 anomaly-based long-short portfolios. Used as factor proxies
#' (\code{X}) in the RRA, PLS, and PCA estimators.
#'
#' @format A data.frame with 516 rows and 71 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{MKT}{Market excess return (percent).}
#'   \item{SMB}{Small-minus-big size factor (percent).}
#'   \item{HML}{High-minus-low value factor (percent).}
#'   \item{RMW}{Robust-minus-weak profitability factor (percent).}
#'   \item{CMA}{Conservative-minus-aggressive investment factor (percent).}
#'   \item{...}{65 additional anomaly-based long-short factors (percent).}
#' }
#' @note The sample period ends 2016-12-01, twelve months earlier than the
#'   portfolio datasets (\code{he2023_ff48vw}, etc., which end 2017-12-01).
#'   Align dates before passing \code{he2023_factors} as \code{X} and any
#'   portfolio dataset as \code{target}.
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_factors[, 1:5])
"he2023_factors"

#' Fama-French 48-industry value-weighted portfolios from He, Huang, Li, Zhou (2023)
#'
#' Monthly value-weighted returns on the 48 Fama-French industry portfolios from
#' the replication package of He, Huang, Li, Zhou (2023). Used as the target
#' return matrix (\code{target}) in the RRA, PLS, and PCA estimators.
#'
#' @format A data.frame with 528 rows and 49 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{Agric}{Agriculture portfolio return (percent).}
#'   \item{Food}{Food products portfolio return (percent).}
#'   \item{...}{46 additional industry portfolio returns (percent).}
#' }
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_ff48vw[, 1:5])
"he2023_ff48vw"

#' Fama-French 30-industry value-weighted portfolios from He, Huang, Li, Zhou (2023)
#'
#' Monthly value-weighted returns on the 30 Fama-French industry portfolios from
#' the replication package of He, Huang, Li, Zhou (2023). Used as the target
#' return matrix (\code{target}) in the RRA, PLS, and PCA estimators.
#'
#' @format A data.frame with 528 rows and 31 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{Food}{Food products portfolio return (percent).}
#'   \item{...}{29 additional industry portfolio returns (percent).}
#' }
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_ff30vw[, 1:5])
"he2023_ff30vw"

#' Fama-French 17-industry value-weighted portfolios from He, Huang, Li, Zhou (2023)
#'
#' Monthly value-weighted returns on the 17 Fama-French industry portfolios from
#' the replication package of He, Huang, Li, Zhou (2023). Used as the target
#' return matrix (\code{target}) in the RRA, PLS, and PCA estimators.
#'
#' @format A data.frame with 528 rows and 18 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{Food}{Food products portfolio return (percent).}
#'   \item{...}{16 additional industry portfolio returns (percent).}
#' }
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_ff17vw[, 1:5])
"he2023_ff17vw"

#' Fama-French 48-industry equal-weighted portfolios from He, Huang, Li, Zhou (2023)
#'
#' Monthly equal-weighted returns on the 48 Fama-French industry portfolios from
#' the replication package of He, Huang, Li, Zhou (2023). Used as the target
#' return matrix (\code{target}) in the RRA, PLS, and PCA estimators.
#'
#' @format A data.frame with 528 rows and 49 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{Agric}{Agriculture portfolio return (percent).}
#'   \item{Food}{Food products portfolio return (percent).}
#'   \item{...}{46 additional industry portfolio returns (percent).}
#' }
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_ff48ew[, 1:5])
"he2023_ff48ew"

#' Dacheng 202-portfolio value-weighted returns from He, Huang, Li, Zhou (2023)
#'
#' Monthly value-weighted returns on 202 portfolios (from Dacheng Xiu's
#' replication data) from the replication package of He, Huang, Li, Zhou (2023).
#' Used as the target return matrix (\code{target}) in the RRA, PLS, and PCA
#' estimators. Columns are named sequentially \code{p001}--\code{p202}.
#'
#' @format A data.frame with 552 rows and 203 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{p001}{Portfolio 1 return (percent).}
#'   \item{p002}{Portfolio 2 return (percent).}
#'   \item{...}{Portfolios p003 through p202 (percent).}
#' }
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_dacheng202[, 1:5])
"he2023_dacheng202"

#' Fama-French 5-factor data from He, Huang, Li, Zhou (2023)
#'
#' Monthly Fama-French 5-factor returns plus momentum and liquidity, from the
#' replication package of He, Huang, Li, Zhou (2023). The risk-free rate
#' (\code{RF}) column is used in the replication scripts to convert gross
#' returns to excess returns.
#'
#' @format A data.frame with 652 rows and 9 variables:
#' \describe{
#'   \item{date}{First day of each month, class \code{Date}.}
#'   \item{Mkt-RF}{Market excess return (percent).}
#'   \item{SMB}{Small-minus-big size factor (percent).}
#'   \item{HML}{High-minus-low value factor (percent).}
#'   \item{RMW}{Robust-minus-weak profitability factor (percent).}
#'   \item{CMA}{Conservative-minus-aggressive investment factor (percent).}
#'   \item{RF}{Risk-free rate (percent).}
#'   \item{FFMOM}{Fama-French momentum factor (percent).}
#'   \item{Pastor_Liq}{Pastor-Stambaugh liquidity factor (percent).}
#' }
#' @note Sample period is 1963-07-01 to 2017-10-01 (652 months). Row 127
#'   corresponds to 1974-01-01, aligning with the start of
#'   \code{he2023_factors}. To extract the matching RF series use
#'   \code{he2023_ff5$RF[127:642]}.
#' @source He, Huang, Li, Zhou (2023) replication package,
#'   \url{https://pubsonline.informs.org/doi/10.1287/mnsc.2022.4563}.
#' @references He, J., Huang, J., Li, F., and Zhou, G. (2023).
#'   Shrinking Factor Dimension: A Reduced-Rank Approach.
#'   \emph{Management Science}, 69(9).
#'   \doi{10.1287/mnsc.2022.4563}
#' @keywords datasets
#' @examples
#' head(he2023_ff5)
"he2023_ff5"
