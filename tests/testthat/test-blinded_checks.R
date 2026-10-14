# test-blinded_checks.R — blinded aggregate tables (blinded_checks.R) on a
# synthetic raw export and ADSL with known counts.

here::i_am("tests/testthat/test-blinded_checks.R")
source(here::here("R", "external", "functions.R"))
source(here::here("R", "blinded_review", "blinded_checks.R"))

cfg <- list(sw = list(start = "2025-04-01", end = "2026-05-26", step_weeks = 5, n_steps = 12))
hospitals <- tibble::tibble(SITEID = c("A", "B"), TRANS_STEP = c(2, 11), LCG_STEP = c(3, 12))

raw <- tibble::tibble(
  fodested = c("A", "A", "A", "B", "B", "B"),
  forlosningsmetode = c("spontan_vaginal_fodsel", "vakuum", "akutt_sectio",
                        "akutt_sectio", "spontan_vaginal_fodsel", NA),
  tv2_fodselstidspunkt = c(NA, NA, NA, NA, "2025-06-01T08:00", "2025-06-02T08:00"),
  tv2_forlosningsmetode = c(NA, NA, NA, NA, "akutt_sectio", ""),
  medikamentell_smertelindring = c(1, 1, 1, 0, NA, 1),
  type_medikamentell_smertelindring_spinal = c(0, 0, 1, NA, NA, 0),
  type_medikamentell_smertelindring_pudendal = c(1, 1, 0, NA, NA, 0),
  perinealrift = c(1, 0, NA, NA, NA, NA),
  episiotomi = c(0, 1, 1, 0, NA, 0),
  ph_arterie = c(7.25, 7179, NA, NA, 7.10, NA),
  ph_vene = c(7.30, 7.30, 7.35, NA, NA, NA)
)
adsl <- tibble::tibble(
  SITEID = raw$fodested, CLUSTER = c(1, 1, 1, 10, 10, NA),
  BIRTHDT = as.Date(c("2025-04-10", "2025-05-10", "2025-04-12",
                      "2025-06-01", "2026-05-20", "2027-01-01")),
  INWINFL = c("Y", "Y", "Y", "Y", "Y", "N"),
  STEPN = c(1L, 2L, 1L, 2L, 12L, NA),
  PERIODC = c("control", "transition", "control", "control", "intervention", NA),
  FORMPER = c("control", "transition", "intervention", "control", "intervention", "control"),
  MODEN = c(1L, 2L, 3L, 3L, 3L, NA),
  ICSFL = c("N", "N", "Y", "Y", "Y", NA),
  CXCSN = c(NA, NA, 4, NA, 10, NA)
)
res <- blinded_checks(raw, adsl, hospitals, cfg)

cell <- function(tab, ...) {
  f <- list(...)
  keep <- Reduce(`&`, Map(function(v, x) tab[[v]] == x, names(f), f))
  tab$n[keep]
}

test_that("checkbox children under a gate: NA with gate answered = no, gate NA = missing", {
  expect_identical(bc_tick(c(1, 0, NA, NA), c(1, 1, 0, NA)), c("yes", "no", "no", "(missing)"))
})

test_that("spinal / pudendal tables cross use with mode and, in vaginal deliveries, tear", {
  expect_equal(cell(res$spinal_by_mode, spinal = "yes", mode_twin1 = "akutt_sectio"), 1)
  expect_equal(cell(res$spinal_by_mode, spinal = "(missing)", mode_twin1 = "spontan_vaginal_fodsel"), 1)
  expect_equal(sum(res$pudendal_by_tear$n), 3)   # vaginal deliveries only
  expect_equal(cell(res$pudendal_by_tear, pudendal = "yes", perineal_tear_vaginal = "1"), 1)
})

test_that("episiotomy recorded for CS is visible", {
  expect_equal(cell(res$episiotomy_by_mode, mode_twin1 = "akutt_sectio", episiotomy = "1"), 1)
  expect_equal(res$episiotomy_by_mode$pct_row[res$episiotomy_by_mode$mode_twin1 == "akutt_sectio"],
               c(50, 50))
})

test_that("cord gas status: plausible / out of range / venous only / none, by hospital", {
  g <- res$cordgas_by_hospital
  expect_equal(cell(g, hospital = "A", cord_gas_twin1 = "arterial (plausible)"), 1)
  expect_equal(cell(g, hospital = "A", cord_gas_twin1 = "arterial (out of range)"), 1)
  expect_equal(cell(g, hospital = "A", cord_gas_twin1 = "venous only"), 1)
  expect_equal(cell(g, hospital = "B", cord_gas_twin1 = "no cord gas"), 2)
})

test_that("twin table covers twin pregnancies only, blank twin-2 mode as missing", {
  expect_equal(sum(res$twin_modes$n), 2)
  expect_equal(cell(res$twin_modes, mode_twin1 = "(missing)", mode_twin2 = "(missing)"), 1)
})

test_that("form vs schedule: discordance per hospital x step, window births only", {
  ps <- res$period_schedule
  expect_equal(sum(ps$n), 5)
  expect_equal(ps$n_discordant[ps$SITEID == "A" & ps$STEPN == 1], 1)
  expect_equal(ps$form_intervention[ps$SITEID == "A" & ps$STEPN == 1], 1)
  expect_equal(sum(ps$n_discordant), 1)
})

test_that("period dates: first/last birth per form against the scheduled dates", {
  pd <- res$period_dates
  a_int <- pd[pd$SITEID == "A" & pd$form == "intervention", ]
  expect_equal(a_int$scheduled_from, as.Date("2025-04-01") + 70)   # step 3
  expect_equal(a_int$n_outside_schedule, 1)                          # born in step 1
  a_tr <- pd[pd$SITEID == "A" & pd$form == "transition", ]
  expect_equal(c(a_tr$scheduled_from, a_tr$scheduled_to),
               as.Date("2025-04-01") + c(35, 69))
  expect_equal(a_tr$n_outside_schedule, 0)
})

test_that("primary missing-data summary", {
  pm <- stats::setNames(res$primary_missing$n, res$primary_missing$check)
  expect_equal(pm[["women"]], 6)
  expect_equal(pm[["mode of delivery (twin 1) not recorded"]], 1)
  expect_equal(pm[["twin pregnancies"]], 2)
  expect_equal(pm[["twin 2 mode of delivery not recorded"]], 1)
  expect_equal(pm[["caesarean section without cervical dilatation"]], 1)
  expect_equal(pm[["caesarean section at <= 4 cm (counted in the primary)"]], 1)
  expect_equal(pm[["time of birth missing or outside the inclusion window"]], 1)
})
