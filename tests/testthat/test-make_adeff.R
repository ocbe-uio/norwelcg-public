# test-make_adeff.R — endpoint derivations of make_adeff.R that are not visible
# in the models (review items 52, 65, 69): cord pH and base excess / deficit
# limits, OASIS, amniotomy counted at any dilatation, the characteristics of a
# CS of the second twin only, the denominators of the descriptive endpoints,
# and the LCG-only, gated shared decision-making items (operative delivery
# only, SAP v0.9).
# Synthetic fixture: every raw column make_adeff() reads, NA unless set.

here::i_am("tests/testthat/test-make_adeff.R")
source(here::here("R", "make_ad", "make_adeff.R"))
source(here::here("R", "helpers", "codelists.R"))
source(here::here("R", "external", "functions.R"))

codelists <- readr::read_csv(here::here("metadata", "codelists.csv"), comment = "#",
                             show_col_types = FALSE)
sdm <- readr::read_csv(here::here("metadata", "sdm_items.csv"), comment = "#",
                       show_col_types = FALSE, col_types = readr::cols(.default = "c"))
arms <- c("WHO partograph", "LCG")

src <- readLines(here::here("R", "make_ad", "make_adeff.R"))
cols <- unique(unlist(regmatches(src, gregexpr("(?<=d\\$)[A-Za-z0-9_]+", src, perl = TRUE))))
cols <- setdiff(cols, c("USUBJID", "MODE", "MODE1N", "ICSFL", "CXCSN", "FORMPER"))
cols <- c(cols, "samvalg_operativ_forlosning_tiltaket_utfort",
          "samvalg_operativ_forlosning_informert", "samvalg_ekstern_ctg_tiltaket_utfort",
          "stotteperson_partner", "cervix_apning_amniotomi")
cols <- unique(cols)
n <- 4
raw <- tibble::as_tibble(stats::setNames(rep(list(rep(NA, n)), length(cols)), cols))
set <- function(v, x) raw[[v]] <<- x
# 1 LCG, CS of twin 2 only; 2 WHO, CS of the first baby at 6 cm;
# 3 LCG, vaginal, continuous CTG, perineal support; 4 WHO, vaginal
set("fotal_fodselspresentasjon", c("bakhode", "bakhode", NA, NA))
set("tv2_fotal_fodselspresentasjon", c("sete", NA, NA, NA))
set("hovedarsak_operativ_forlosning", c(NA, "fotalt_distress", NA, NA))
set("tv2_hovedarsak_operativ_forlosning", c("langsom_fremgang", NA, NA, NA))
set("niva_ledende_del_akutt_sectio", c("over_spina", "under_spina", NA, NA))
set("cx_akutt_sectio", c(NA, "6cm", NA, NA))
set("fosterovervaking_kontinuerlig_ekstern_ctg", c(0, 0, 1, 0))
set("fosterovervaking_stan_kontinuerlig_intern_ctg", c(0, 0, 0, 0))
set("fosterovervaking_intermitterende", c(1, 1, 0, 1))
set("base_excess_arterie", c(-401, -3, NA, 12))
set("base_deficit_arterie", c(NA, NA, 26, NA))
set("ph_arterie", c(7.20, 7.56, 6.40, 7.55))
# amniotomy at 2 cm (woman 1) is counted (SAP v0.9: whatever the dilatation)
set("amniotomi", c(1, 0, 1, NA))
set("cervix_apning_amniotomi", c("2cm", NA, "6cm", NA))
# tears: 3 grade 2 only -> no OASIS; 4 grade 3b -> OASIS; CS women no status
set("perinealrift", c(NA, NA, 1, 1))
set("perinealrift_grad_grad_2", c(NA, NA, 1, 1))
set("perinealrift_grad_grad_3b", c(NA, NA, 0, 1))
set("samvalg_operativ_forlosning_tiltaket_utfort", c("1", NA, "0", NA))
set("samvalg_operativ_forlosning_informert", c("1", NA, NA, NA))
set("samvalg_ekstern_ctg_tiltaket_utfort", c("1", NA, "0", NA))
set("stotteperson_partner", c(1, NA, 0, NA))

adsl <- tibble::tibble(
  STUDYID = "T", USUBJID = sprintf("T-%d", 1:n), SITEID = "A", CLUSTER = 1,
  STEPN = 3L, STEP = factor(3, levels = 1:12), PERIODC = "control", EXPOSN = 0L,
  FORMPER = c("intervention", "control", "intervention", "control"),
  TRT01P = factor(arms[c(2, 1, 2, 1)], levels = arms), TRT01PN = c(1, 0, 1, 0),
  TRT01A = factor(arms[c(2, 1, 2, 1)], levels = arms),
  FASFL = "Y", PASFL = "Y", VDSFL = c("N", "N", "Y", "Y"), TRNSFL = "N",
  MODE = c("CS", "CS", "SVD", "SVD"), MODE1N = c(1L, 3L, 1L, 1L),
  MODEDTL = NA_character_, ICSFL = c("Y", "Y", "N", "N"), CXCSN = c(10, 6, NA, NA),
  ROBSON = "1", AGE = 30, BMIPREG = 24, HEIGHT = 167, BWT = 3500, GA = 40
)

test_that("make_adeff derives the descriptive endpoints in their own denominators", {
  tmp <- withr::local_tempdir()
  env <- environment(make_adeff)
  orig <- get("path_adam", envir = env)
  withr::defer(assign("path_adam", orig, envir = env))
  assign("path_adam", function(...) fs::path(tmp, "ad", ...), envir = env)

  e <- suppressWarnings(make_adeff(raw, adsl, codelists, list(), list(sdm = sdm)))
  g <- function(code) e[e$PARAMCD == code, ]

  # base excess / deficit outside -25..25 -> missing (-401, deficit 26); +12 kept
  expect_equal(as.vector(g("BEA")$AVAL), c(NA, -3, NA, 12))
  # arterial pH outside 6.5-7.55 -> missing
  expect_equal(as.vector(g("PHA")$AVAL), c(7.20, NA, NA, 7.55))

  # amniotomy counted whatever the dilatation; no exclusion flag
  expect_equal(as.vector(g("AMNIO")$AVAL), c(1, 0, 1, 0))
  expect_true(all(g("AMNIO")$ANL01FL == "Y"))

  # OASIS (grade 3-4) in the vaginal delivery set; composite: CS = no
  expect_equal(as.vector(g("OASIS")$AVAL), c(NA, NA, 0, 1))
  expect_equal(unique(g("OASIS")$APOP), "VDS")
  expect_equal(as.vector(g("OASISC")$AVAL), c(0, 0, 0, 1))
  expect_false(any(c("TEAR", "PERSUP", "PERSUPC", "MEDPR", "AMNIOANY", "CXAMNIO",
                     "PERSUPTY") %in% e$PARAMCD))

  # CS of the second twin only: dilatation 10 cm, the second twin's
  # presentation and reason, no level; CS characteristics only for the CS
  expect_equal(as.vector(g("CXCS")$AVALC)[1:2], c("10 cm", "6 cm"))
  expect_equal(as.vector(g("CXCS")$ANL01FL), c("Y", "Y", "N", "N"))
  expect_equal(as.vector(g("CSPRES")$AVALC)[1], decode_cat("sete", "fotal_fodselspresentasjon", codelists))
  expect_equal(as.vector(g("CSREAS")$AVALC)[1], "Prolonged labour")
  expect_true(is.na(g("CSLEVEL")$AVALC[1]))
  expect_false(is.na(g("CSLEVEL")$AVALC[2]))

  # type of continuous monitoring: among the women with it
  expect_equal(as.vector(g("CFMTYPE")$ANL01FL), c("N", "N", "Y", "N"))

  # SDM: operative delivery only, LCG period only; gated item where the gate is
  # yes; no companionship and no other SDM items (SAP v0.9)
  lab <- function(v) sdm$item_en[sdm$variable == v]
  sd <- e[e$PARCAT2 %in% "SHARED DECISION MAKING", ]
  perf <- sd[sd$PARAM == lab("samvalg_operativ_forlosning_tiltaket_utfort"), ]
  inf <- sd[sd$PARAM == lab("samvalg_operativ_forlosning_informert"), ]
  expect_equal(as.vector(perf$ANL01FL), c("Y", "N", "Y", "N"))     # LCG women
  expect_equal(as.vector(inf$ANL01FL), c("Y", "N", "N", "N"))      # performed = yes
  expect_equal(length(unique(sd$PARAMCD)), 2)
  expect_false(lab("samvalg_ekstern_ctg_tiltaket_utfort") %in% sd$PARAM)
  expect_false(any(e$PARCAT2 %in% "COMPANIONSHIP"))
})
