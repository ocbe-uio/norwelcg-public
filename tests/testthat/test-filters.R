here::i_am("tests/testthat/test-filters.R")
source(here::here("R", "helpers", "filters.R"))
`%||%` <- rlang::`%||%`

test_that("filter_pop keeps only rows in the analysis population", {
  cfg <- list(analysis = list(popfl = "FASFL"))
  d <- data.frame(FASFL = c("Y", "N", "Y"), x = 1:3)
  expect_equal(nrow(filter_pop(d, cfg)), 2)
})

test_that("filter_pop errors if the flag is missing", {
  cfg <- list(analysis = list(popfl = "FASFL"))
  expect_error(filter_pop(data.frame(x = 1:3), cfg), "not found")
})
