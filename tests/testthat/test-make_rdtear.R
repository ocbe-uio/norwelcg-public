# test-make_rdtear.R — proportional-odds GLMM with G-computed grade
# probabilities (make_rdtear.R) on simulated ordinal data with a known OR.

here::i_am("tests/testthat/test-make_rdtear.R")
source(here::here("R", "make_rd", "rd_helpers.R"))
source(here::here("R", "make_rd", "make_rdtear.R"))

arms <- c("WHO partograph", "LCG")

test_that("analyse_ord recovers a known odds ratio; grade probabilities are coherent", {
  withr::local_seed(99)
  n <- 4000
  site <- sample(1:8, n, TRUE)
  trt <- sample(0:1, n, TRUE)
  u <- stats::rnorm(8, 0, 0.3)[site]
  # latent logistic: P(Y <= j) = plogis(alpha_j - 0.5 * trt - u)
  alpha <- c(0, 1.2, 3.8, 6.5)
  lat <- 0.5 * trt + u + stats::rlogis(n)
  y <- findInterval(lat, alpha)
  dt <- tibble::tibble(AVAL = y, SITEID = sprintf("S%d", site),
                       STEP = factor(sample(1:12, n, TRUE), levels = 1:12),
                       TRT01P = factor(arms[trt + 1], levels = arms))
  cfg <- list(analysis = list(covariates = list(), gh_nodes = 15))
  res <- analyse_ord(dt, cfg)
  expect_equal(res$or, exp(0.5), tolerance = 0.15)
  expect_equal(sum(res[paste0("p", 0:4, "_ref")]), 1, tolerance = 1e-8)
  expect_equal(sum(res[paste0("p", 0:4, "_int")]), 1, tolerance = 1e-8)
  expect_equal(res$oasis_ref, res$p3_ref + res$p4_ref, tolerance = 1e-8)
  expect_gt(res$oasis_rd, 0)                  # higher grades with OR > 1
  expect_true(res$oasis_rd_lcl < res$oasis_rd && res$oasis_rd < res$oasis_rd_ucl)
})

test_that("analyse_ord still returns estimates when the cluster SD collapses to 0", {
  withr::local_seed(7)
  n <- 3000
  trt <- sample(0:1, n, TRUE)
  y <- findInterval(0.4 * trt + stats::rlogis(n), c(0, 1.2, 3.8, 6.5))
  dt <- tibble::tibble(AVAL = y, SITEID = sprintf("S%d", sample(1:8, n, TRUE)),
                       STEP = factor(sample(1:12, n, TRUE), levels = 1:12),
                       TRT01P = factor(arms[trt + 1], levels = arms))
  res <- analyse_ord(dt, list(analysis = list(covariates = list(), gh_nodes = 15)))
  expect_true(is.finite(res$or) && is.finite(res$oasis_rd_se))
  expect_equal(res$or, exp(0.4), tolerance = 0.15)
})
