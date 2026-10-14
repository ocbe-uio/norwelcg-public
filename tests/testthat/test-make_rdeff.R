# test-make_rdeff.R — the dichotomous-endpoint layer (rd_helpers.R,
# make_rdeff.R) on a synthetic stepped-wedge fixture with known truth. Real
# cross-variable structure is destroyed in the anonymised copy, so model logic
# is validated here, not there.

here::i_am("tests/testthat/test-make_rdeff.R")
source(here::here("R", "make_rd", "rd_helpers.R"))
source(here::here("R", "make_rd", "make_rdeff.R"))
source(here::here("R", "helpers", "filters.R"))
source(here::here("R", "external", "functions.R"))

arms <- c("WHO partograph", "LCG")
test_cfg <- list(analysis = list(popfl = "PASFL", ni_margin = 0.015,
                                 covariates = list(), gh_nodes = 15))

# Stepped wedge: 10 clusters x 12 steps; cluster s is WHO in steps <= s, in
# transition in step s + 1 and on the LCG from step s + 2 (SAP Figure 1).
make_sw_fixture <- function(n_per_cell = 25, p_ctr = 0.10, or_int = 1,
                            sd_cluster = 0.3, seed = 1349) {
  withr::with_seed(seed, {
    u <- stats::rnorm(10, 0, sd_cluster)
    g <- tidyr::expand_grid(site = 1:10, step = 1:12, i = seq_len(n_per_cell))
    period <- ifelse(g$step <= g$site, "control",
                     ifelse(g$step == g$site + 1, "transition", "intervention"))
    trt <- as.integer(period == "intervention")
    eta <- stats::qlogis(p_ctr) + log(or_int) * trt + u[g$site]
    tibble::tibble(
      USUBJID = sprintf("SYN-%05d", seq_len(nrow(g))),
      SITEID  = sprintf("S%02d", g$site),
      STEP    = factor(g$step, levels = 1:12),
      TRT01P  = factor(dplyr::case_when(period == "control" ~ arms[1],
                                        period == "intervention" ~ arms[2]),
                       levels = arms),
      AVAL    = stats::rbinom(nrow(g), 1, stats::plogis(eta)),
      FASFL = "Y", PASFL = ifelse(period == "transition", "N", "Y"),
      TRNSFL = ifelse(period == "transition", "Y", "N"),
      VDSFL = "Y", ANL01FL = "Y",
      EXPOSN = ifelse(period == "intervention", g$step - (g$site + 2) + 1L,
                      ifelse(period == "control", 0L, NA_integer_)),
      ATYPE = "BIN", APOP = "PAS", DTYPE = ""
    )
  })
}

test_that("gh_rule integrates Gaussian moments exactly", {
  g <- gh_rule(15)
  expect_equal(sum(g$w), sqrt(pi))
  expect_equal(sum(g$w * g$x^2), sqrt(pi) / 2)
  expect_equal(sum(g$w * g$x^4), 3 * sqrt(pi) / 4)
})

test_that("ni_tests implements the SAP 2.1 fixed sequence", {
  r <- ni_tests(0, 0.005, 0.015)
  expect_equal(r$p_ni, stats::pnorm(-3))
  expect_true(r$ni_concl)
  expect_false(r$sup_concl)                  # upper limit 0.0098 > 0
  expect_true(ni_tests(-0.02, 0.005, 0.015)$sup_concl)
  expect_false(ni_tests(0.02, 0.005, 0.015)$ni_concl)
  expect_false(ni_tests(0.02, 0.005, 0.015)$sup_concl)
})

test_that("prep_covars builds 2-df splines, missing indicators and a missing level", {
  withr::local_seed(3)
  robson <- c(rep(c("r1", "r2"), 49), NA, "r1")
  cfg <- list(analysis = list(covariates = list(categorical = "ROBSON",
                                                continuous = "AGE")))
  # 15 missing: median + indicator
  dt <- tibble::tibble(AGE = c(stats::rnorm(85, 30, 5), rep(NA, 15)), ROBSON = robson)
  pc <- prep_covars(dt, cfg)
  expect_setequal(pc$terms, c("C_ROBSON", "S_AGE_1", "S_AGE_2", "M_AGE"))
  expect_true("(missing)" %in% levels(pc$data$C_ROBSON))
  expect_equal(sum(pc$data$M_AGE), 15)
  expect_identical(prep_covars(dt, cfg, adjust = FALSE)$terms, character())

  # fewer than min_indicator missing: median only, no indicator (SAP 4.1.3)
  dt2 <- tibble::tibble(AGE = c(stats::rnorm(98, 30, 5), NA, NA), ROBSON = robson)
  expect_false("M_AGE" %in% prep_covars(dt2, cfg)$terms)
  cfg2 <- cfg
  cfg2$analysis$covariates$min_indicator <- 2
  expect_true("M_AGE" %in% prep_covars(dt2, cfg2)$terms)
})

test_that("drop_aliased removes linearly dependent covariate columns", {
  dt <- tibble::tibble(S_A_1 = as.numeric(1:10),
                       M_A = c(rep(0, 5), rep(1, 5)),
                       M_B = c(rep(0, 5), rep(1, 5)))
  expect_setequal(drop_aliased(dt, c("S_A_1", "M_A", "M_B")), c("S_A_1", "M_A"))
  expect_setequal(drop_aliased(dt, c("S_A_1", "M_A")), c("S_A_1", "M_A"))
})

test_that("gcomp_bin equals predict() for a GLM and the Monte Carlo integral for a GLMM", {
  dat <- make_sw_fixture(sd_cluster = 0.6, seed = 11)
  dt <- dat[dat$PASFL == "Y", ]
  dt$TRT01P <- droplevels(dt$TRT01P)
  dt$SITEID <- factor(dt$SITEID)
  glmfit <- fit_bin(dt, c("TRT01P", "STEP", "SITEID"), random = FALSE)
  gc <- gcomp_bin(glmfit, dt)
  for (a in arms) {
    nd <- dt
    nd$TRT01P <- factor(a, levels = arms)
    expect_equal(gc$res[[a]]$risk, mean(predict(glmfit, nd, type = "response")))
  }
  mer <- fit_bin(dt, c("TRT01P", "STEP"))
  gm <- gcomp_bin(mer, dt)
  nd <- dt
  nd$TRT01P <- factor(arms[1], levels = arms)
  eta <- stats::predict(mer, nd, re.form = NA)
  withr::local_seed(5)
  u <- stats::rnorm(4000, 0, gm$sigma)
  mc <- mean(stats::plogis(outer(eta, u, "+")))
  expect_equal(gm$res[[arms[1]]]$risk, mc, tolerance = 1e-3)
})

test_that("analyse_bin recovers a null effect and reports arm counts", {
  dat <- make_sw_fixture()
  dt <- dat[dat$PASFL == "Y", ]
  res <- analyse_bin(dt, test_cfg, ni = TRUE)
  expect_equal(res$n, nrow(dt))
  expect_equal(res$n_ref + res$n_int, res$n)
  expect_equal(res$ev_ref, sum(dt$AVAL[dt$TRT01P == arms[1]]))
  expect_lt(abs(res$rd), 0.03)
  expect_true(res$rd_lcl < res$rd && res$rd < res$rd_ucl)
  expect_equal(res$risk_int - res$risk_ref, res$rd, tolerance = 1e-8)
  expect_equal(res$risk_int / res$risk_ref, res$rr, tolerance = 1e-8)
  expect_true(res$p_ni >= 0 && res$p_ni <= 1)
})

test_that("analyse_bin detects a harmful effect and does not conclude NI", {
  dat <- make_sw_fixture(or_int = 2, seed = 2071)
  res <- analyse_bin(dat[dat$PASFL == "Y", ], test_cfg, ni = TRUE)
  expect_gt(res$rd, 0.03)
  expect_gt(res$rr, 1.3)
  expect_false(res$ni_concl)
})

test_that("analyse_bin survives a degenerate endpoint with a note", {
  dat <- make_sw_fixture()
  dat$AVAL <- 0
  res <- analyse_bin(dat[dat$PASFL == "Y", ], test_cfg)
  expect_true(!"rd" %in% names(res) || is.na(res$rd) || nzchar(res$note))
})

test_that("make_rdeff runs the primary, sensitivity, supplementary and secondary analyses", {
  dat <- make_sw_fixture(n_per_cell = 12)
  adeff <- dplyr::bind_rows(
    dat |> dplyr::mutate(PARAMCD = "ICS", PARAM = "Intrapartum CS", PARCAT1 = "PRIMARY"),
    dat |> dplyr::mutate(PARAMCD = "SVD", PARAM = "Spontaneous vaginal",
                         PARCAT1 = "SECONDARY WOMEN", AVAL = 1 - AVAL)
  )
  tmp <- withr::local_tempdir()
  env <- environment(make_rdeff)
  path_rd_orig <- get("path_rd", envir = env)
  withr::defer(assign("path_rd", path_rd_orig, envir = env))
  assign("path_rd", function(...) fs::path(tmp, "rd", ...), envir = env)

  res <- make_rdeff(adeff, test_cfg)
  expect_setequal(unique(res$analysis),
                  c("PRIMARY", "SENS1 UNADJUSTED", "SENS2 FIXED CLUSTER",
                    "SUPP1 TRANSITION AS WHO PARTOGRAPH", "SUPP2 EXPOSURE TIME",
                    "SECONDARY"))
  # SAP v0.9: the primary is the whole PAS (all CS from 4 cm, no principal stratum)
  pas <- sum(dat$PASFL == "Y")
  expect_equal(res$n[res$analysis %in% c("PRIMARY", "SENS1 UNADJUSTED",
                                         "SENS2 FIXED CLUSTER")], rep(pas, 3))
  # transition women enter SUPP1 as WHO partograph: the whole FAS
  expect_equal(res$n[res$analysis == "SUPP1 TRANSITION AS WHO PARTOGRAPH"],
               sum(dat$FASFL == "Y"))
  expect_equal(sum(res$analysis == "SUPP2 EXPOSURE TIME"), 2)
  expect_equal(res$n[res$analysis == "SECONDARY"], pas)
  expect_equal(res$population[res$analysis == "SECONDARY"], "PAS")
  # NI tests only on the primary estimand (primary + sensitivity)
  expect_true(all(!is.na(res$p_ni[res$analysis %in% c("PRIMARY", "SENS1 UNADJUSTED",
                                                      "SENS2 FIXED CLUSTER")])))
  expect_true(all(is.na(res$p_ni[res$analysis == "SECONDARY"])))
  expect_true(fs::file_exists(fs::path(tmp, "rd", "rdeff.rds")))
})
