test_that("he2023_factors has correct dimensions, date class, and date range", {

  expect_equal(nrow(he2023_factors), 516L)
  expect_equal(ncol(he2023_factors), 71L)
  expect_s3_class(he2023_factors$date, "Date")
  expect_equal(he2023_factors$date[1],   as.Date("1974-01-01"))
  expect_equal(he2023_factors$date[516], as.Date("2016-12-01"))
  expect_type(he2023_factors$MKT, "double")

  # Verify backslash stripping was applied
  expect_true("F_g7" %in% names(he2023_factors))
  expect_false(any(grepl("\\", names(he2023_factors), fixed = TRUE)))

})

test_that("he2023_dacheng202 has correct dimensions, column names, and date range", {

  expect_equal(nrow(he2023_dacheng202), 552L)
  expect_equal(ncol(he2023_dacheng202), 203L)
  expect_equal(names(he2023_dacheng202)[1],   "date")
  expect_equal(names(he2023_dacheng202)[2],   "p001")
  expect_equal(names(he2023_dacheng202)[203], "p202")
  expect_s3_class(he2023_dacheng202$date, "Date")
  expect_equal(he2023_dacheng202$date[1],   as.Date("1972-01-01"))
  expect_equal(he2023_dacheng202$date[552], as.Date("2017-12-01"))
  expect_type(he2023_dacheng202$p001, "double")
  expect_false(anyNA(he2023_dacheng202))

})

test_that("he2023_ff48vw has correct dimensions and date range", {

  expect_equal(nrow(he2023_ff48vw), 528L)
  expect_equal(ncol(he2023_ff48vw), 49L)
  expect_s3_class(he2023_ff48vw$date, "Date")
  expect_equal(he2023_ff48vw$date[1],   as.Date("1974-01-01"))
  expect_equal(he2023_ff48vw$date[528], as.Date("2017-12-01"))
  expect_type(he2023_ff48vw$Agric, "double")
  expect_false(anyNA(he2023_ff48vw))

})

test_that("he2023_ff30vw has correct dimensions and date range", {

  expect_equal(nrow(he2023_ff30vw), 528L)
  expect_equal(ncol(he2023_ff30vw), 31L)
  expect_s3_class(he2023_ff30vw$date, "Date")
  expect_equal(he2023_ff30vw$date[1],   as.Date("1974-01-01"))
  expect_equal(he2023_ff30vw$date[528], as.Date("2017-12-01"))
  expect_type(he2023_ff30vw$Food, "double")
  expect_false(anyNA(he2023_ff30vw))

})

test_that("he2023_ff17vw has correct dimensions and date range", {

  expect_equal(nrow(he2023_ff17vw), 528L)
  expect_equal(ncol(he2023_ff17vw), 18L)
  expect_s3_class(he2023_ff17vw$date, "Date")
  expect_equal(he2023_ff17vw$date[1],   as.Date("1974-01-01"))
  expect_equal(he2023_ff17vw$date[528], as.Date("2017-12-01"))
  expect_type(he2023_ff17vw$Food, "double")
  expect_false(anyNA(he2023_ff17vw))

})

test_that("he2023_ff48ew has correct dimensions and date range", {

  expect_equal(nrow(he2023_ff48ew), 528L)
  expect_equal(ncol(he2023_ff48ew), 49L)
  expect_s3_class(he2023_ff48ew$date, "Date")
  expect_equal(he2023_ff48ew$date[1],   as.Date("1974-01-01"))
  expect_equal(he2023_ff48ew$date[528], as.Date("2017-12-01"))
  expect_type(he2023_ff48ew$Agric, "double")
  expect_false(anyNA(he2023_ff48ew))

})

test_that("he2023_ff5 has correct dimensions, date range, and RF column", {

  expect_equal(nrow(he2023_ff5), 652L)
  expect_equal(ncol(he2023_ff5), 9L)
  expect_s3_class(he2023_ff5$date, "Date")
  expect_equal(he2023_ff5$date[1],   as.Date("1963-07-01"))
  expect_equal(he2023_ff5$date[652], as.Date("2017-10-01"))
  # Row 127 aligns with the start of he2023_factors (1974-01-01)
  expect_equal(he2023_ff5$date[127], as.Date("1974-01-01"))
  expect_true("RF" %in% names(he2023_ff5))
  expect_type(he2023_ff5$RF, "double")
  # RF column (used for excess-return construction) is complete
  expect_false(anyNA(he2023_ff5$RF))

})
