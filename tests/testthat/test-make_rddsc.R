# test-make_rddsc.R — descriptive reporting summaries on a small fixture.

here::i_am("tests/testthat/test-make_rddsc.R")
source(here::here("R", "make_rd", "make_rddsc.R"))
source(here::here("R", "helpers", "filters.R"))
source(here::here("R", "external", "functions.R"))

test_cfg <- list(analysis = list(popfl = "PASFL", tte = list(origin_cm = 4)))

arms <- c("WHO partograph", "LCG")
trt <- factor(rep(arms, c(6, 4)), levels = arms)

fix_adsl <- tibble::tibble(
  USUBJID = sprintf("S-%02d", 1:10), TRT01P = trt, PASFL = "Y",
  NORWAYFL = c("Y", "Y", "N", NA, "Y", "N", "Y", "N", "N", "Y"),
  COHABFL = "Y", HIEDUFL = "N", SMOKEFL = "N", SNUSFL = "N",
  DIABFL = "N", HTNFL = "N", PARITY = "p0", NULLIPFL = "Y",
  PREVCSFL = "N", FVDFL = "Y", SPONTFL = "Y", INDUCFL = "N", ROBSON = "1",
  ADMREAS = "x", SEX = "jente", TWINFL = "N", HOSPBIRC = "2000-3999",
  CONTINENT = "Europe", BWPCTC = "Appropriate (10th-90th percentile)", BWCAT = "3500-3999 g",
  AGE = 30, CONTRADM = 3, HEIGHT = 168,
  WGTPREG = c(60, 65, 70, 75, NA, 68, 72, 69, 71, 66),
  BMIPREG = 25, GA = 40, BWT = 3500, HDCIRC = 35
)

fix_adeff <- tibble::tibble(
  USUBJID = rep(fix_adsl$USUBJID, 4),
  TRT01P = rep(trt, 4), PASFL = "Y", VDSFL = "Y",
  PARAMCD = rep(c("CSREAS", "DYST1", "OASIS", "PHA"), each = 10),
  PARAM = rep(c("Main reason", "Dystocia 1", "Occurrence of OASIS",
                "Arterial cord pH"), each = 10),
  PARCAT1 = rep(c("DESCRIPTIVE", "DESCRIPTIVE", "SECONDARY WOMEN", "AUXILIARY"),
                each = 10),
  PARCAT2 = rep(c("CS CHARACTERISTICS", "OTHER", NA, NA), each = 10),
  ATYPE = rep(c("CAT", "BIN", "BIN", "NUM"), each = 10),
  APOP = rep(c("PAS", "PAS", "VDS", "PAS"), each = 10),
  AVALC = c(c("a", "a", "b", NA, "b", "a", "a", "b", NA, "a"),
            rep(NA_character_, 30)),
  AVAL = c(rep(NA_real_, 10), c(1, 0, 0, 1, 0, NA, 1, 0, 0, 1),
           c(0, 1, 0, 0, 1, 0, 0, 0, 1, NA), c(7.25, 7.30, 7.18, 7.22, NA,
           7.28, 7.31, 7.20, 7.26, 7.24)),
  # CSREAS applies to the CS only: women 4 and 9 (reason missing) are not CS
  ANL01FL = c("Y", "Y", "Y", "N", "Y", "Y", "Y", "Y", "N", "Y", rep("Y", 30))
)

fix_adlp <- tibble::tibble(
  USUBJID = rep(fix_adsl$USUBJID, each = 2), TRT01P = rep(trt, each = 2),
  PASFL = "Y", MODE = "SVD", CMN = rep(c(4, 10), 10),
  AVAL = c(6, 1, 5, 0.5, 4, 0.2, 8, 2, 3, 1, 7, 1, 5, 1, 4, 0.5, 90, 1, 6, 2),
  ANL01FL = c(rep("Y", 16), "N", "Y", "Y", "Y")
)

test_that("make_rddsc summarises baseline, endpoints and examinations by arm", {
  tmp <- withr::local_tempdir()
  env <- environment(make_rddsc)
  path_rd_orig <- get("path_rd", envir = env)
  withr::defer(assign("path_rd", path_rd_orig, envir = env))
  assign("path_rd", function(...) fs::path(tmp, "rd", ...), envir = env)

  res <- make_rddsc(fix_adsl, fix_adeff, fix_adlp, test_cfg)
  expect_named(res, c("baseline_cat", "baseline_cont", "endpoints",
                      "numeric", "exams", "t0obs"))

  # categorical baseline: NORWAYFL WHO partograph arm = 3 Y / 2 N / 1 missing,
  # flags shown as Yes/No
  nor <- res$baseline_cat[res$baseline_cat$variable == "NORWAYFL", ]
  expect_equal(nor$category, c("No", "Yes", "(missing)"))
  expect_equal(nor$n_ref, c(2, 3, 1))
  expect_equal(nor$pct_ref[nor$category == "Yes"], 60)
  expect_true(is.na(nor$pct_ref[nor$category == "(missing)"]))
  expect_true(all(c("HOSPBIRC", "INDUCFL") %in% res$baseline_cat$variable))
  # not in the SAP v0.9 baseline table: birthweight percentile, reason for
  # admission, contractions at admission, height (covariate only)
  expect_false(any(c("BWPCTC", "ADMREAS") %in% res$baseline_cat$variable))
  expect_false(any(c("CONTRADM", "HEIGHT") %in% res$baseline_cont$variable))

  # continuous baseline: reference arm first
  expect_equal(as.character(res$baseline_cont$TRT01P[1:2]), arms)
  # continuous baseline: WGTPREG control arm n = 5 with 1 missing
  h <- res$baseline_cont[res$baseline_cont$variable == "WGTPREG" &
                           res$baseline_cont$TRT01P == arms[1], ]
  expect_equal(h$n, 5)
  expect_equal(h$n_miss, 1)
  expect_equal(h$median, 68)

  # endpoints: AVALC categories for CSREAS among the women it applies to (the
  # two non-CS women with no reason are not counted as missing), AVAL 0/1 for
  # DYST1 (shown as No/Yes)
  cs <- res$endpoints[res$endpoints$PARAMCD == "CSREAS", ]
  expect_setequal(cs$category, c("a", "b"))
  expect_equal(cs$n_ref[cs$category == "a"], 3)
  dy <- res$endpoints[res$endpoints$PARAMCD == "DYST1", ]
  expect_equal(dy$category, c("No", "Yes", "(missing)"))
  expect_equal(dy$n_ref, c(3, 2, 1))

  # numeric endpoint: complete-case summary per arm
  ph <- res$numeric[res$numeric$PARAMCD == "PHA" & res$numeric$TRT01P == arms[1], ]
  expect_equal(ph$n, 5)
  expect_equal(ph$n_miss, 1)

  # observed time from the 4 cm examination to delivery (vaginal deliveries)
  expect_equal(sum(res$t0obs$n), sum(fix_adlp$CMN == 4 & fix_adlp$ANL01FL == "Y"))

  # examinations: analysis-flagged only (the 90 h exam is excluded)
  ex <- res$exams[res$exams$CMN == 4 & res$exams$TRT01P == arms[2], ]
  expect_equal(ex$n, 3)
  expect_equal(ex$median, 5)
  expect_true(fs::file_exists(fs::path(tmp, "rd", "rddsc.rds")))

  # an arm with no rows (LCG-form-only item): both arms' columns still present
  lcg_only <- fix_adeff[fix_adeff$PARAMCD == "CSREAS", ]
  lcg_only$ANL01FL <- ifelse(lcg_only$TRT01P == arms[2], "Y", "N")
  res2 <- make_rddsc(fix_adsl, dplyr::bind_rows(fix_adeff[fix_adeff$PARAMCD != "CSREAS", ],
                                               lcg_only), fix_adlp, test_cfg)
  e2 <- res2$endpoints[res2$endpoints$PARAMCD == "CSREAS", ]
  expect_true(all(c("n_ref", "pct_ref") %in% names(e2)) && all(e2$n_ref == 0))
})
