# test-make_rdtte.R — time from 4 cm to vaginal delivery (make_rdtte.R): the
# restricted mean time without vaginal delivery (CS = the full horizon) by a
# linear mixed model, on simulated data with a known difference.

here::i_am("tests/testthat/test-make_rdtte.R")
source(here::here("R", "make_rd", "rd_helpers.R"))
source(here::here("R", "make_rd", "make_rdtte.R"))
source(here::here("R", "external", "functions.R"))

arms <- c("WHO partograph", "LCG")
H <- 36
# CS risk 8% vs 6%; time from 4 cm to vaginal delivery Weibull(1.3, 7 h) vs
# Weibull(1.3, 6 h)
gen <- function(n, lcg) {
  cs <- stats::runif(n) < ifelse(lcg, 0.06, 0.08)
  t <- stats::rweibull(n, shape = 1.3, scale = ifelse(lcg, 6, 7))
  list(cs = cs, t = t, y = ifelse(cs, H, pmin(t, H)))
}
truth <- withr::with_seed(99, {
  mean(gen(2e6, TRUE)$y) - mean(gen(2e6, FALSE)$y)
})

test_that("make_rdtte recovers the restricted-mean difference and reports all analyses", {
  withr::local_seed(21)
  n <- 6000
  adeff <- tibble::tibble(
    USUBJID = sprintf("W%05d", seq_len(n)), PARAMCD = "ICS", PASFL = "Y",
    SITEID = sprintf("S%02d", sample(1:8, n, TRUE)),
    STEP = factor(sample(1:12, n, TRUE), levels = 1:12),
    TRT01P = factor(sample(arms, n, TRUE), levels = arms)
  )
  g <- gen(n, adeff$TRT01P == arms[2])
  adeff$MODE <- ifelse(g$cs, "CS", "SVD")
  adeff$AVAL <- as.numeric(g$cs)
  # two imputations of the 4 cm time: the true time with small noise; CS have none
  imp0 <- dplyr::bind_rows(lapply(1:2, function(j) {
    tibble::tibble(USUBJID = adeff$USUBJID[!g$cs], IMPN = j,
                   T0 = g$t[!g$cs] * exp(stats::rnorm(sum(!g$cs), 0, 0.02)),
                   T0IMPFL = "Y")
  }))
  cfg <- list(analysis = list(covariates = list(), gh_nodes = 15,
                              tte = list(origin_cm = 4, horizon = H,
                                         supp_horizons = c(24, 48),
                                         supportive_hours = c(6, 12), cif_step_min = 30)))
  tmp <- withr::local_tempdir()
  env <- environment(make_rdtte)
  path_rd_orig <- get("path_rd", envir = env)
  withr::defer(assign("path_rd", path_rd_orig, envir = env))
  assign("path_rd", function(...) fs::path(tmp, "rd", ...), envir = env)

  res <- make_rdtte(imp0, adeff, cfg)
  r <- res$results
  expect_setequal(unique(r$analysis),
                  c("SECONDARY", "SENS1 UNADJUSTED", "SENS2 FIXED CLUSTER, HC3",
                    "SUPPLEMENTARY", "COMPONENT", "SUPPORTIVE"))
  main <- r[r$analysis == "SECONDARY", ]
  expect_lt(main$estimate, 0)                  # faster and fewer CS with the LCG
  expect_true(main$lcl < truth && truth < main$ucl)
  expect_equal(main$estimate, truth, tolerance = 0.25)
  # the arm means are restricted means (between 0 and H)
  expect_true(all(c(main$est_ref, main$est_int) > 0 & c(main$est_ref, main$est_int) < H))
  expect_equal(main$est_int - main$est_ref, main$estimate)
  # the unadjusted and fixed-cluster HC3 analyses agree closely here
  for (a in c("SENS1 UNADJUSTED", "SENS2 FIXED CLUSTER, HC3")) {
    expect_equal(r$estimate[r$analysis == a], main$estimate, tolerance = 0.1)
  }
  expect_equal(sort(r$horizon[r$analysis == "SUPPLEMENTARY"]), c(24, 48))
  # component: P(vaginal delivery) difference ~ +2 pp; duration among VD shorter
  pvd <- r[grepl("^Probability", r$measure), ]
  expect_equal(pvd$estimate, 0.02, tolerance = 0.5)
  vds <- r[r$analysis == "COMPONENT" & r$population == "VDS", ]
  expect_lt(vds$estimate, 0)
  expect_equal(vds$n, sum(!g$cs))
  # supportive: more vaginal deliveries within 6 and 12 h with the LCG
  expect_true(all(r$estimate[r$analysis == "SUPPORTIVE"] > 0))
  # cumulative incidence: non-decreasing, within [0, 1], plateau ~ P(VD)
  cif <- res$cif
  for (a in arms) {
    ca <- cif$cif[cif$TRT01P == a]
    expect_true(all(diff(ca) >= 0) && ca[1] == 0 && max(ca) <= 1)
  }
  expect_equal(max(cif$cif[cif$TRT01P == arms[1]]), mean(!g$cs[adeff$TRT01P == arms[1]]),
               tolerance = 0.01)
  expect_true(fs::file_exists(fs::path(tmp, "rd", "rdtte.rds")))
})

test_that("hc3_vcov matches the textbook HC3 formula", {
  withr::local_seed(3)
  x <- stats::rnorm(200); g <- factor(sample(letters[1:3], 200, TRUE))
  y <- 1 + x + stats::rnorm(200, 0, 0.5 + abs(x))
  fit <- stats::lm(y ~ x + g)
  X <- stats::model.matrix(fit); e <- stats::residuals(fit); h <- stats::hatvalues(fit)
  B <- solve(crossprod(X))
  ref <- B %*% t(X) %*% diag(e^2 / (1 - h)^2) %*% X %*% B
  expect_equal(unname(hc3_vcov(fit)), unname(ref))
})
