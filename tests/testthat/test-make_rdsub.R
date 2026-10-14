# test-make_rdsub.R — Robson subgroup analysis of the primary endpoint
# (make_rdsub.R) on simulated data with a known effect in one group.

here::i_am("tests/testthat/test-make_rdsub.R")
source(here::here("R", "make_rd", "rd_helpers.R"))
source(here::here("R", "make_rd", "make_rdsub.R"))
source(here::here("R", "external", "functions.R"))

arms <- c("WHO partograph", "LCG")

test_that("make_rdsub combines small groups and recovers group-specific differences", {
  withr::local_seed(5)
  n <- 12000
  rob <- sample(c("Robson group 1", "Robson group 2", "Robson group 5",
                  "Robson group 10"), n, TRUE, prob = c(0.45, 0.45, 0.06, 0.04))
  trt <- factor(sample(arms, n, TRUE), levels = arms)
  lcg <- trt == arms[2]
  # CS risk: group 1 5% in both arms; group 2 10% vs 15%; small groups 20%
  p <- dplyr::case_when(rob == "Robson group 1" ~ 0.05,
                        rob == "Robson group 2" ~ ifelse(lcg, 0.15, 0.10),
                        .default = 0.20)
  adeff <- tibble::tibble(
    USUBJID = sprintf("W%05d", seq_len(n)), PARAMCD = "ICS", PASFL = "Y",
    SITEID = sprintf("S%02d", sample(1:8, n, TRUE)),
    STEP = factor(sample(1:12, n, TRUE), levels = 1:12),
    TRT01P = trt, ROBSON = rob, AVAL = as.numeric(stats::runif(n) < p)
  )
  # group 10 (~96 CS) stays; group 5 has ~140 CS: raise the threshold so that
  # both small groups are combined
  cfg <- list(analysis = list(covariates = list(categorical = list("ROBSON")),
                              gh_nodes = 15, subgroup = list(min_events = 200)))
  tmp <- withr::local_tempdir()
  env <- environment(make_rdsub)
  path_rd_orig <- get("path_rd", envir = env)
  withr::defer(assign("path_rd", path_rd_orig, envir = env))
  assign("path_rd", function(...) fs::path(tmp, "rd", ...), envir = env)

  res <- make_rdsub(adeff, cfg)
  expect_equal(res$group, c("Robson group 1", "Robson group 2", "Combined small groups"))
  expect_equal(res$groups_combined[3], "Robson group 10; Robson group 5")
  expect_equal(sum(res$n), nrow(adeff))   # primary set: the whole PAS (SAP v0.9)
  g1 <- res[res$group == "Robson group 1", ]
  g2 <- res[res$group == "Robson group 2", ]
  expect_true(g1$rd_lcl < 0 && 0 < g1$rd_ucl)
  expect_equal(g2$rd, 0.05, tolerance = 0.4)
  expect_gt(g2$rd_lcl, 0)
  expect_lt(res$p_interaction[1], 0.01)
  expect_true(fs::file_exists(fs::path(tmp, "rd", "rdsub.rds")))
})
