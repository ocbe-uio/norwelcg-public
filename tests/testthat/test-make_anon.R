# Logic tests for the flat-file anonymiser (R/make_anon/). Runs against a small
# synthetic fixture that mirrors the real NorWel structure (labelled columns,
# dotted checkbox labels, timing strings, a gate, the amniotomi/oxytocin joint,
# a twin-2 block, a gated timing var). Marginals/consistency are checked, not
# real data (permutation breaks cross-variable relationships by design).

source(here::here("R/make_anon/anon_checks.R"))
source(here::here("R/make_anon/make_anon.R"))
source(here::here("R/make_raw/read_norwel_raw.R"))

# point path_raw() at a temp dir so make_anon can write its outputs
local_anon <- function(env = parent.frame()) {
  tmp <- withr::local_tempdir(.local_envir = env)
  dir.create(file.path(tmp, "raw"))
  assign("path_raw", function(...) file.path(tmp, "raw", ...), envir = globalenv())
  withr::defer(rm("path_raw", envir = globalenv()), envir = env)
  tmp
}

make_fixture <- function(n = 400) {
  set.seed(1)
  lbl <- function(x, label) { attr(x, "label") <- label; x }
  adm <- as.POSIXct("2025-06-01 08:00", tz = "UTC") + runif(n, 0, 60 * 86400)
  iso <- function(t) format(t, "%Y-%m-%dT%H:%M", tz = "UTC")
  amn <- rbinom(n, 1, 0.34)
  oxy <- ifelse(amn == 1, rbinom(n, 1, 0.6), rbinom(n, 1, 0.2))
  ind <- rbinom(n, 1, 0.34)
  twin <- rep(0, n); twin[sample(n, 20)] <- 1
  tibble::tibble(
    created = iso(adm - 3600),
    answer_time_ms = sample(1e5:9e6, n),
    tidspunkt_innleggelse = iso(adm),
    fodselstidspunkt = iso(adm + runif(n, 5, 20) * 3600),
    tidspunkt_oppstart_induksjon = ifelse(ind == 1, iso(adm - runif(n, 1, 10) * 3600), ""),
    fodested = sample(c("Ahus", "Haukeland", "St_Olav"), n, replace = TRUE),
    induksjon = ind,
    amniotomi = amn,
    cervix_apning_amniotomi = ifelse(amn == 1, paste0(sample(2:6, n, TRUE), "cm"), ""),
    hovedarsak_amniotomi = ifelse(amn == 1, sample(c("skalp", "annet"), n, TRUE), ""),
    oxytocin_infusjon = oxy,
    max_dose_oxytocin_infusjon = ifelse(oxy == 1, sample(30:150, n, TRUE), NA_integer_),
    stotteperson_partner = lbl(rbinom(n, 1, .8), "stotteperson.partner"),
    v_a = lbl(rbinom(n, 1, .1), "stotteperson.doula"),
    tv2_fodselstidspunkt = ifelse(twin == 1, iso(adm + runif(n, 6, 22) * 3600), ""),
    tv2_fodselsvekt_gram = ifelse(twin == 1, sample(1500:3500, n, TRUE), NA_integer_),
    tv2_barnets_kjonn = ifelse(twin == 1, sample(c("gutt", "jente"), n, TRUE), ""),
    # typed (haven POSIXct) cleaned timestamps, as the ny* columns arrive
    nyfodselstidspunkt = adm + runif(n, 5, 20) * 3600,
    nytidinduksjon = replace(adm - runif(n, 1, 10) * 3600, ind == 0, NA)
  )
}

fixture_acfg <- function() list(
  seed = 42,
  drop = c("created", "answer_time_ms"),
  anchor = "tidspunkt_innleggelse",
  shift_within_window = TRUE,
  timing = c("tidspunkt_innleggelse", "fodselstidspunkt",
             "tidspunkt_oppstart_induksjon", "tv2_fodselstidspunkt",
             "nyfodselstidspunkt", "nytidinduksjon"),
  timing_gates = list(tidspunkt_oppstart_induksjon = "induksjon",
                      nytidinduksjon = "induksjon"),
  groups = list(
    induksjon = list("induksjon"),
    amniotomi = list("amniotomi", "cervix_apning_amniotomi", "hovedarsak_amniotomi"),
    oxytocin = list("oxytocin_infusjon", "max_dose_oxytocin_infusjon"),
    stotteperson = list("stotteperson.*"),
    tv2 = list(restrict_to = "tv2_fodselstidspunkt", members = list("tv2_*"))
  ),
  joint = list(list("amniotomi", "oxytocin")),
  risk_readout = FALSE
)

test_that("dropped columns are removed and outputs written to the safe path", {
  tmp <- local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = "_YYYYMMDD_HHMMSS"),
                 acfg = fixture_acfg(), out_stem = "syn")
  expect_false(any(c("created", "answer_time_ms") %in% names(a)))
  expect_true(file.exists(file.path(tmp, "raw", "anon_keys", "offset_map.csv")))
  expect_true(file.exists(file.path(tmp, "raw", "syn_anon", "syn_anon.dta")))
  # manifest records the code version that actually ran
  man <- readr::read_csv(file.path(tmp, "raw", "syn_anon", "anon_manifest.csv"),
                         show_col_types = FALSE)
  expect_identical(man$anon_code_version, ANON_CODE_VERSION)
  expect_identical(man$config_hash, rlang::hash(fixture_acfg()))
})

test_that("timing shift preserves within-row intervals and time-of-day", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  pt <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M", tz = "UTC")
  expect_equal(as.numeric(pt(a$fodselstidspunkt) - pt(a$tidspunkt_innleggelse)),
               as.numeric(pt(df$fodselstidspunkt) - pt(df$tidspunkt_innleggelse)))
  expect_true(mean(substr(df$tidspunkt_innleggelse, 1, 10) !=
                     substr(a$tidspunkt_innleggelse, 1, 10)) > 0.9)
  expect_identical(substr(df$tidspunkt_innleggelse, 12, 16),
                   substr(a$tidspunkt_innleggelse, 12, 16))
})

test_that("permutation preserves marginals for permuted columns", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  mm <- function(x) sort(as.character(x))
  expect_identical(mm(df$fodested), mm(a$fodested))
  expect_identical(mm(df$amniotomi), mm(a$amniotomi))
  expect_identical(mm(df$max_dose_oxytocin_infusjon), mm(a$max_dose_oxytocin_infusjon))
})

test_that("blocks stay internally consistent (gate travels with its children)", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  g0 <- a$amniotomi == 0
  expect_true(all(a$cervix_apning_amniotomi[g0] == ""))
  expect_true(all(a$hovedarsak_amniotomi[g0] == ""))
  expect_true(all(a$cervix_apning_amniotomi[a$amniotomi == 1] != ""))
})

test_that("joint groups keep their cross-group correlation", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  expect_identical(sort(paste(df$amniotomi, df$oxytocin_infusjon)),
                   sort(paste(a$amniotomi, a$oxytocin_infusjon)))
})

test_that("twin-2 block is permuted only among twin rows", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  expect_equal(sum(.is_present(a$tv2_fodselsvekt_gram)), sum(.is_present(df$tv2_fodselstidspunkt)))
  expect_true(all(.is_present(a$tv2_fodselsvekt_gram) == .is_present(a$tv2_fodselstidspunkt)))
})

test_that("gated timing is blanked where its gate is off; labels are kept", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  expect_true(all(a$tidspunkt_oppstart_induksjon[a$induksjon == 0] == ""))
  expect_identical(attr(a$v_a, "label"), "stotteperson.doula")
})

test_that("shifted admission dates stay within the observed trial window", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  dt <- function(x) as.Date(substr(x, 1, 10))
  win <- range(dt(df$tidspunkt_innleggelse))
  expect_true(all(dt(a$tidspunkt_innleggelse) >= win[1] &
                    dt(a$tidspunkt_innleggelse) <= win[2]))
  # and intervals are still preserved under the bounded offset
  pt <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M", tz = "UTC")
  expect_equal(as.numeric(pt(a$fodselstidspunkt) - pt(a$tidspunkt_innleggelse)),
               as.numeric(pt(df$fodselstidspunkt) - pt(df$tidspunkt_innleggelse)))
})

test_that("explicit window survives sentinel dates; out-of-window rows parked inside", {
  local_anon()
  df <- make_fixture()
  # inject sentinel/garbage admissions as seen in the real raw (e.g. year 999)
  df$tidspunkt_innleggelse[1:3] <- c("999-12-25T18:35", "1000-01-14T23:32",
                                     "0150-06-01T08:00")
  acfg <- fixture_acfg()
  acfg$window <- c("2025-06-01", "2025-08-01")
  a <- make_anon(df, cfg = list(export = ""), acfg = acfg, out_stem = "syn")
  d <- as.Date(substr(a$tidspunkt_innleggelse, 1, 10), format = "%Y-%m-%d")
  # every shifted admission — including the sentinel rows — is inside the window
  expect_true(all(d >= as.Date("2025-06-01") & d <= as.Date("2025-08-01"),
                  na.rm = TRUE))
  expect_false(anyNA(d))
})

# --- typed timing, anchor fallback, unlisted-timestamp guard -------------

test_that("typed POSIXct timing columns are shifted with the row offset", {
  local_anon()
  df <- make_fixture()
  a <- make_anon(df, cfg = list(export = ""), acfg = fixture_acfg(), out_stem = "syn")
  pt <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M", tz = "UTC")
  gap <- function(x) as.numeric(difftime(x$nyfodselstidspunkt,
                                         pt(x$tidspunkt_innleggelse),
                                         units = "secs"))
  expect_s3_class(a$nyfodselstidspunkt, "POSIXct")
  # same offset as the string timing columns on every row
  expect_equal(gap(a), gap(df))
  # true calendar date hidden
  expect_true(mean(as.Date(a$nyfodselstidspunkt) !=
                     as.Date(df$nyfodselstidspunkt)) > 0.9)
  # gated typed timing is blanked (NA) where its gate is off
  expect_true(all(is.na(a$nytidinduksjon[a$induksjon == 0])))
})

test_that("an unlisted timestamp column stops make_anon before writing", {
  tmp <- local_anon()
  run <- function(df, acfg = fixture_acfg()) {
    make_anon(df, cfg = list(export = ""), acfg = acfg, out_stem = "syn")
  }
  df <- make_fixture()
  df$nytidinnleggelse <- as.POSIXct(df$tidspunkt_innleggelse,
                                    format = "%Y-%m-%dT%H:%M", tz = "UTC")
  expect_error(run(df), "nytidinnleggelse")
  df <- make_fixture()
  df$ny_streng <- df$fodselstidspunkt           # ISO string form
  expect_error(run(df), "ny_streng")
  expect_false(dir.exists(file.path(tmp, "raw", "syn_anon")))
  # dropping it is equally acceptable
  acfg <- fixture_acfg()
  acfg$drop <- c(acfg$drop, "ny_streng")
  expect_no_error(run(df, acfg))
})

test_that("anchor falls back through the listed columns; no row left unshifted", {
  tmp <- local_anon()
  df <- make_fixture()
  df$nyfodselstidspunkt[1:15] <- NA           # primary anchor missing
  df$tidspunkt_innleggelse[11:15] <- ""       # rows 11-15: no anchor at all
  acfg <- fixture_acfg()
  acfg$anchor <- list("nyfodselstidspunkt", "tidspunkt_innleggelse")
  acfg$window <- c("2025-06-01", "2025-09-01")
  a <- make_anon(df, cfg = list(export = ""), acfg = acfg, out_stem = "syn")
  off <- readr::read_csv(file.path(tmp, "raw", "anon_keys", "offset_map.csv"),
                         show_col_types = FALSE)$offset_days
  inwin <- function(d) all(d >= as.Date("2025-06-01") & d <= as.Date("2025-09-01"))
  # primary anchor bounds the ordinary rows; the fallback bounds rows 1-10
  expect_true(inwin(as.Date(a$nyfodselstidspunkt[-(1:15)])))
  expect_true(inwin(as.Date(substr(a$tidspunkt_innleggelse[1:10], 1, 10))))
  # anchor-less rows still receive a random offset
  expect_false(all(off[11:15] == 0))
})

# --- two raw files: harmonise + treatment --------------------------------

lbl <- function(x, label) { attr(x, "label") <- label; x }

write_two_arm_dtas <- function(dir, n = 120) {
  iso <- function(t) format(t, "%Y-%m-%dT%H:%M", tz = "UTC")
  admI <- as.POSIXct("2025-01-10 08:00", tz = "UTC") + runif(n, 0, 40 * 86400)
  admC <- as.POSIXct("2024-09-01 08:00", tz = "UTC") + runif(n, 0, 40 * 86400) # earlier period
  intv <- tibble::tibble(
    tidspunkt_innleggelse = iso(admI),
    nokkel = sprintf("INT-%05d", seq_len(n)),               # real-style key
    amniotomi = rbinom(n, 1, .4),
    v8  = lbl(rbinom(n, 1, .8), "stotteperson.partner"),   # positional Stata name
    imA = lbl(rbinom(n, 1, .5), "Induksjonsmetoder.Amniotomi"),
    samvalg_x = lbl(rbinom(n, 1, .6), "samvalg_x")          # intervention-only
  )
  ctrl <- tibble::tibble(
    tidspunkt_innleggelse = iso(admC),
    nokkel = sprintf("CTR-%05d", seq_len(n)),
    amniotomi = rbinom(n, 1, .4),
    v9  = lbl(rbinom(n, 1, .8), "stotteperson.partner"),   # different name, same label
    imA = lbl(rbinom(n, 1, .5), "Induksjonsmetode.Amniotomi"), # variant label
    tiltak = lbl(rbinom(n, 1, .3), "tiltakslinjen_krysset_forste_sta") # control-only
  )
  # transition period: SAME structure as control (statistician, 2026-09-09),
  # different admission window and its own positional Stata name for the shared
  # label, so label alignment is exercised across all three files.
  admT <- as.POSIXct("2024-11-15 08:00", tz = "UTC") + runif(n, 0, 40 * 86400)
  trns <- tibble::tibble(
    tidspunkt_innleggelse = iso(admT),
    nokkel = sprintf("TRAN-%05d", seq_len(n)),
    amniotomi = rbinom(n, 1, .4),
    v11 = lbl(rbinom(n, 1, .8), "stotteperson.partner"),
    imA = lbl(rbinom(n, 1, .5), "Induksjonsmetode.Amniotomi"),
    tiltak = lbl(rbinom(n, 1, .3), "tiltakslinjen_krysset_forste_sta")
  )
  fi <- file.path(dir, "int.dta"); fc <- file.path(dir, "ctr.dta")
  ft <- file.path(dir, "trn.dta")
  haven::write_dta(intv, fi); haven::write_dta(ctrl, fc)
  haven::write_dta(trns, ft)
  list(fi = fi, fc = fc, ft = ft, n = n)
}

test_that("read_norwel_raw aligns by label, harmonises, and tags true treatment", {
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  acfg <- list(harmonize = list(Induksjonsmetoder = list("Induksjonsmetode")))
  r <- read_norwel_raw(ff$fi, ff$fc, acfg = acfg)

  # positional v8/v9 aligned via the shared label -> one column, no misalignment
  expect_true("stotteperson_partner" %in% names(r))
  expect_equal(sum(is.na(r$stotteperson_partner)), 0)
  # cosmetic label variant harmonised to one induction-method column
  expect_true("induksjonsmetoder_amniotomi" %in% names(r))
  expect_equal(sum(is.na(r$induksjonsmetoder_amniotomi)), 0)
  # arm-specific columns are NA in the arm that lacks them
  expect_true(all(is.na(r$samvalg_x[r$treatment == "control"])))
  expect_true(all(is.na(r$tiltakslinjen_krysset_forste_sta[r$treatment == "intervention"])))
  # true allocation present with correct sizes
  expect_equal(as.integer(table(r$treatment)[c("control", "intervention")]),
               c(ff$n, ff$n))
})

test_that("make_anon on the combined table randomises treatment and pools arms", {
  tmp <- local_anon()
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  acfg <- list(
    seed = 7, drop = character(),
    anchor = "tidspunkt_innleggelse", shift_within_window = TRUE,
    timing = c("tidspunkt_innleggelse"),
    harmonize = list(Induksjonsmetoder = list("Induksjonsmetode")),
    groups = list(), joint = list(), risk_readout = FALSE
  )
  raw <- read_norwel_raw(ff$fi, ff$fc, acfg = acfg)
  a <- make_anon(raw, cfg = list(export = ""), acfg = acfg, out_stem = "two")

  # treatment marginal preserved but re-randomised (decoupled from arm-specific
  # data presence, so true arm is no longer reconstructable)
  expect_equal(sort(as.character(raw$treatment)), sort(as.character(a$treatment)))
  # samvalg presence no longer coincides with treatment == "intervention"
  present_by_int <- tapply(!is.na(a$samvalg_x), a$treatment == "intervention", mean)
  expect_gt(present_by_int["FALSE"], 0)   # some control-labelled rows carry samvalg
  # window bound holds on the pooled admission range
  dt <- function(x) as.Date(substr(x, 1, 10))
  win <- range(dt(raw$tidspunkt_innleggelse))
  expect_true(all(dt(a$tidspunkt_innleggelse) >= win[1] &
                    dt(a$tidspunkt_innleggelse) <= win[2]))
})

# --- three raw files: the transition period ------------------------------

test_that("read_norwel_raw reads the transition file as a third period", {
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  acfg <- list(harmonize = list(Induksjonsmetoder = list("Induksjonsmetode")))
  r <- read_norwel_raw(c(intervention = ff$fi, transition = ff$ft,
                         control = ff$fc), acfg = acfg)

  # three period levels, each with its true size
  expect_equal(as.integer(table(r$treatment)[c("control", "intervention",
                                               "transition")]),
               rep(ff$n, 3))
  # transition rows behave like control rows: control-only column present,
  # intervention-only column NA
  trn <- r$treatment == "transition"
  expect_equal(sum(is.na(r$tiltakslinjen_krysset_forste_sta[trn])), 0)
  expect_true(all(is.na(r$samvalg_x[trn])))
  # label alignment still collapses the positional names (v8/v9/v11) into one
  expect_true("stotteperson_partner" %in% names(r))
  expect_equal(sum(is.na(r$stotteperson_partner)), 0)
  expect_equal(sum(is.na(r$induksjonsmetoder_amniotomi)), 0)
})

test_that("read_norwel_raw requires names when more than two files are given", {
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  expect_error(
    read_norwel_raw(c(ff$fi, ff$ft, ff$fc), acfg = list()),
    "NAMED character vector"
  )
})

test_that("make_anon permutes the three-level period label", {
  tmp <- local_anon()
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  acfg <- list(
    seed = 7, drop = character(),
    anchor = "tidspunkt_innleggelse", shift_within_window = TRUE,
    timing = c("tidspunkt_innleggelse"),
    harmonize = list(Induksjonsmetoder = list("Induksjonsmetode")),
    groups = list(), joint = list(), risk_readout = FALSE
  )
  raw <- read_norwel_raw(c(intervention = ff$fi, transition = ff$ft,
                           control = ff$fc), acfg = acfg)
  a <- make_anon(raw, cfg = list(export = ""), acfg = acfg, out_stem = "three")

  # period marginal preserved (all three sizes) but re-randomised
  expect_equal(sort(as.character(raw$treatment)), sort(as.character(a$treatment)))
  expect_false(identical(as.character(raw$treatment), as.character(a$treatment)))
  # the control-only column no longer identifies control+transition rows
  expect_gt(mean(!is.na(a$tiltakslinjen_krysset_forste_sta[
    a$treatment == "intervention"])), 0)
})

# --- synthetic record key (nokkel) ---------------------------------------

sid_acfg <- function() list(
  seed = 7, drop = "nokkel",   # as in anon.yml: dropped AND rebuilt
  anchor = "tidspunkt_innleggelse", shift_within_window = TRUE,
  timing = c("tidspunkt_innleggelse"),
  harmonize = list(Induksjonsmetoder = list("Induksjonsmetode")),
  groups = list(), joint = list(), risk_readout = FALSE,
  synthetic_ids = list(nokkel = list(
    from = "treatment", width = 5,
    prefix = list(intervention = "INT", transition = "TRAN", control = "CTR")
  ))
)

test_that("synthetic nokkel follows the permuted period; no real key survives", {
  local_anon()
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  acfg <- sid_acfg()
  raw <- read_norwel_raw(c(intervention = ff$fi, transition = ff$ft,
                           control = ff$fc), acfg = acfg)
  a <- make_anon(raw, cfg = list(export = ""), acfg = acfg, out_stem = "sid")
  pre <- c(intervention = "INT", transition = "TRAN", control = "CTR")

  # real format, first column, prefix = the (random) period on every row
  expect_identical(names(a)[1], "nokkel")
  expect_true(all(grepl("^(INT|TRAN|CTR)-[0-9]{5}$", a$nokkel)))
  expect_identical(as.character(sub("-.*", "", a$nokkel)),
                   unname(pre[as.character(a$treatment)]))
  # unique, numbered 1..n within each prefix
  expect_equal(anyDuplicated(a$nokkel), 0)
  for (p in names(pre)) {
    k <- a$nokkel[a$treatment == p]
    expect_setequal(as.integer(sub(".*-", "", k)), seq_along(k))
  }
  # not the real key: a row keeps its real key only by chance
  expect_lt(mean(a$nokkel == raw$nokkel), 0.05)
  # all other columns come out exactly as without the synthetic id
  b <- make_anon(raw, cfg = list(export = ""),
                 acfg = modifyList(sid_acfg(), list(drop = "nokkel",
                                                    synthetic_ids = NULL)),
                 out_stem = "sid0")
  expect_identical(as.data.frame(a[setdiff(names(a), "nokkel")]),
                   as.data.frame(b[names(b)]))
})

test_that("synthetic nokkel needs a prefix for every period", {
  local_anon()
  dir <- withr::local_tempdir()
  ff  <- write_two_arm_dtas(dir)
  acfg <- sid_acfg()
  acfg$synthetic_ids$nokkel$prefix$transition <- NULL
  raw <- read_norwel_raw(c(intervention = ff$fi, transition = ff$ft,
                           control = ff$fc), acfg = acfg)
  expect_error(make_anon(raw, cfg = list(export = ""), acfg = acfg,
                         out_stem = "sid"),
               "no `prefix` for treatment value\\(s\\): transition")
})

test_that("anon_verify resolves timing tokens by label (truncated names)", {
  local_anon()
  df <- make_fixture()
  # a Stata-truncated timing column, matched by its full-name label
  df$tid_trunk <- df$fodselstidspunkt
  attr(df$tid_trunk, "label") <- "tidspunkt_med_et_langt_navn_over_32_tegn"
  acfg <- fixture_acfg()
  acfg$timing <- c(acfg$timing, "tidspunkt_med_et_langt_navn_over_32_tegn")
  a <- make_anon(df, cfg = list(export = ""), acfg = acfg, out_stem = "syn")
  expect_true(anon_verify(df, a, timing_cols = acfg$timing)$marginals_ok)
})
