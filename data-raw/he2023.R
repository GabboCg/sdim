# data-raw/he2023.R
# Generates he2023_* datasets from the He et al. (2023) replication package.
# Run from the package root (sdim/) with source("data-raw/he2023.R").
# Requires: readxl

if (!requireNamespace("readxl", quietly = TRUE))
  stop("Package 'readxl' is needed to run this script. Install it with install.packages('readxl').")

xl <- "../refs/replication_package_MS-FIN-21-01990/data/Portfolio_ret.xlsx"

stopifnot(file.exists(xl))

# Helper: yyyymm integer -> Date (first of month)
ym_to_date <- function(x) as.Date(paste0(as.integer(x), "01"), "%Y%m%d")

# ---- he2023_factors (Anomaly sheet) ---------------------------------------
# All five non-Dacheng sheets share an identical two-row header:
#   Excel row 1: NA + numeric column indices (1, 2, 3, ...)
#   Excel row 2: actual labels (MKT, SMB, HML, ... / Agric, Food, ...)
# skip = 1 skips the index row; readxl uses row 2 as column headers.
raw <- readxl::read_excel(xl, sheet = "Anomaly", skip = 1)
nms <- gsub("\\\\", "", colnames(raw))   # strip backslash from 5 factor names
colnames(raw) <- nms

he2023_factors <- data.frame(
  date = ym_to_date(raw[[1]]),
  lapply(raw[-1], as.numeric),
  check.names = FALSE
)

# ---- FF industry portfolios -----------------------------------------------
# FF5 sheet intentionally omitted (different sample period, not used as estimator input).
for (sh in c("FF5", "FF48vw", "FF30vw", "FF17vw", "FF48ew")) {

  if (sh == "FF5") {

    raw <- readxl::read_excel(xl, sheet = sh, skip = 0)

  } else {

    raw <- readxl::read_excel(xl, sheet = sh, skip = 1)

  }

  colnames(raw)[1] <- "ym"

  df <- data.frame(
    date = ym_to_date(raw$ym),
    lapply(raw[-1], as.numeric),
    check.names = FALSE
  )

  assign(paste0("he2023_", tolower(sh)), df)

}

# ---- he2023_dacheng202 ----------------------------------------------------
# Sheet has two header rows: row 1 = group labels (sparse), row 2 = within-group indices.

raw       <- readxl::read_excel(xl, sheet = "Dacheng202vw", col_names = FALSE)
data_rows <- raw[-(1:2), ]

ym_col    <- as.integer(data_rows[[1]])
ret_cols  <- lapply(data_rows[-1], as.numeric)
names(ret_cols) <- sprintf("p%03d", seq_along(ret_cols))

he2023_dacheng202 <- data.frame(
  date = ym_to_date(ym_col),
  ret_cols,
  check.names = FALSE
)

# ---- Save all datasets ----------------------------------------------------
if (!dir.exists("data")) dir.create("data")

datasets <- c("he2023_factors", "he2023_ff5", "he2023_ff48vw", "he2023_ff30vw", "he2023_ff17vw", "he2023_ff48ew", "he2023_dacheng202")

for (nm in datasets) {

  save(list = nm, file = paste0("data/", nm, ".rda"), envir = environment(), compress = "xz")

}

message("Done. Run devtools::document() to update NAMESPACE if needed.")
