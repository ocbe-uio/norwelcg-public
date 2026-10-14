# test-make_adsl.R — subject-level derivations (make_adsl.R) on a synthetic
# raw fixture: identifiers from the record key, step calendar from time of
# birth (steps from 08:00), treatment from the key prefix vs the scheduled
# period, woman-level mode of delivery (twin rules), principal stratum,
# analysis sets, interventions before 4 cm.

here::i_am("tests/testthat/test-make_adsl.R")
source(here::here("R", "make_ad", "make_adsl.R"))
source(here::here("R", "helpers", "codelists.R"))
source(here::here("R", "external", "functions.R"))

# derived columns carry variable labels: compare values only
expect_eq <- function(object, expected) {
  testthat::expect_equal(as.vector(object), expected)
}

cfg <- list(
  studyid = "TEST", ref_arm = "CTR",
  arms = list(list(armcd = "CTR", arm = "WHO", raw = "control"),
              list(armcd = "INT", arm = "LCG", raw = "intervention")),
  sw = list(start = "2025-04-01", end = "2026-05-26", step_weeks = 5, n_steps = 12,
            step_start_time = "08:00")
)
hospitals <- tibble::tibble(SITEID = c("A", "B"), CLUSTER = c(1, 10), STRATUM = 1,
                            BIRTHS = c(1500, 4500), TRANS_STEP = c(2, 11), LCG_STEP = c(3, 12))
codelists <- tibble::tribble(
  ~variable,            ~code,                     ~label_en,
  "forlosningsmetode",  "spontan_vaginal_fodsel",  "Spontaneous vaginal delivery",
  "forlosningsmetode",  "vakuum",                  "Vacuum delivery",
  "forlosningsmetode",  "tang",                    "Forceps delivery",
  "forlosningsmetode",  "akutt_sectio",            "Intrapartum caesarean section",
  "sivilstatus",        "gift",                    "Married",
  "utdanning",          "hoyere_utdanning",        "University or college",
  "robson_gruppe",      "robsongruppe_1",          "Robson group 1",
  "paritet",            "p0",                      "Nulliparous",
  "innleggelsesarsak",  "rier",                    "Contractions",
  "barnets_kjonn",      "jente",                   "Girl",
  "barnets_kjonn",      "gutt",                    "Boy",
  "barnets_kjonn",      "vet_ikke",                "Unknown"
)

# one row per case; every other column the derivation reads is NA
case <- function(key, site, birth, mode1, cx_cs = NA, mode2 = NA, twin = FALSE,
                 amn = 0, cx_amn = NA, eda = 0, cx_eda = NA) {
  tibble::tibble(nokkel = key, fodested = site,
                 nyfodselstidspunkt = as.POSIXct(birth, tz = "UTC"),
                 fodselstidspunkt = NA_character_, tidspunkt_innleggelse = NA_character_,
                 treatment = c(CTR = "control", TRAN = "transition",
                               INT = "intervention")[[sub("-.*", "", key)]],
                 forlosningsmetode = mode1, cx_akutt_sectio = cx_cs,
                 tv2_forlosningsmetode = mode2,
                 tv2_fodselstidspunkt = if (twin) "2025-01-01T00:00" else NA_character_,
                 amniotomi = amn, cervix_apning_amniotomi = cx_amn,
                 oxytocin_infusjon = 0, cx_oppstart_oxytocin_infusjon = NA_character_,
                 medikamentell_smertelindring = eda,
                 type_medikamentell_smertelindring_epidural = eda, cx_start_eda = cx_eda)
}
raw <- dplyr::bind_rows(
  case("CTR-001", "A", "2025-04-10 10:00", "spontan_vaginal_fodsel"),     # 1 step 1, control
  case("TRAN-001", "A", "2025-05-10 10:00", "spontan_vaginal_fodsel"),    # 2 step 2, transition
  case("INT-001", "A", "2026-05-26 23:00", "spontan_vaginal_fodsel"),     # 3 last day -> step 12, LCG
  case("CTR-002", "B", "2025-06-01 08:00", "spontan_vaginal_fodsel", mode2 = "akutt_sectio",
       twin = TRUE),                                                       # 4 twin 2 CS only
  case("CTR-003", "B", "2025-06-02 08:00", "vakuum", mode2 = NA, twin = TRUE), # 5 twin 2 mode missing
  case("CTR-004", "B", "2025-06-03 08:00", "akutt_sectio", cx_cs = "4cm", amn = 1,
       cx_amn = "3cm", eda = 1, cx_eda = "4cm"),                           # 6 CS at 4 cm
  case("CTR-005", "B", "2026-05-27 08:00", "spontan_vaginal_fodsel"),     # 7 outside window
  case("CTR-006", "A", "2025-05-06 07:30", "spontan_vaginal_fodsel"),     # 8 before 08:00 -> step 1
  case("TRAN-002", "A", "2025-05-06 08:30", "spontan_vaginal_fodsel"),    # 9 after 08:00 -> step 2
  case("TRAN-003", "A", "2025-06-10 09:00", "spontan_vaginal_fodsel")     # 10 in labour at the LCG start:
                                                                           #    transition form, LCG step
)
other <- c("alder", "landbakgrunn", "sivilstatus", "utdanning", "hoyde", "pregravid_vekt",
           "royk_for_eller_i_sv_s", "snus_for_eller_i_sv_s", "kjente_pregravide_sykdommer",
           "svangerskapsrelaterte_sykdommer",
           "hvilke_kjente_pregravide_sykdommer_dia_type1",
           "hvilke_kjente_pregravide_sykdommer_dia_type2",
           "hvilke_svangerskapsrelaterte_sykdommer_svangerskapsdia_metforminbehandlet",
           "hvilke_svangerskapsrelaterte_sykdommer_svangerskapsdia_insulinbehandlet",
           "hvilke_kjente_pregravide_sykdommer_kronisk_hypertensjon",
           "hvilke_svangerskapsrelaterte_sykdommer_svangerskapshypertensjon",
           "hvilke_svangerskapsrelaterte_sykdommer_preeklampsi", "robson_gruppe", "paritet",
           "tidligere_sectio", "induksjon", "innleggelsesarsak", "antall_rier_10min_innkomst",
           "gestasjonsalder_ved_fodsel_hele_uker", "gestasjonsalder_ved_fodsel_pluss_dager",
           "barnets_kjonn", "fodselsvekt_gram", "neonatal_hodeomkrets")
chr <- c("landbakgrunn", "sivilstatus", "utdanning", "robson_gruppe", "paritet",
         "innleggelsesarsak", "barnets_kjonn")
for (v in other) raw[[v]] <- if (v %in% chr) NA_character_ else NA_real_

test_that("make_adsl derives identifiers, calendar, period, mode, strata and flags", {
  tmp <- withr::local_tempdir()
  env <- environment(make_adsl)
  path_adam_orig <- get("path_adam", envir = env)
  withr::defer(assign("path_adam", path_adam_orig, envir = env))
  assign("path_adam", function(...) fs::path(tmp, "ad", ...), envir = env)

  a <- make_adsl(raw, hospitals, codelists, cfg)
  # identifiers from the record key
  expect_eq(a$SUBJID, raw$nokkel)
  expect_eq(a$USUBJID[1], "TEST-CTR-001")
  # steps start at 08:00: 1-3 June 2025 = day 61-63 -> step 2; 6 May 2025
  # (day 35) 07:30 -> step 1, 08:30 -> step 2
  expect_eq(a$STEPN, c(1L, 2L, 12L, 2L, 2L, 2L, NA, 1L, 2L, 3L))
  # treatment from the key prefix; the schedule-derived period kept for checks
  expect_eq(a$FORMPER, c("control", "transition", "intervention", rep("control", 5),
                         "transition", "transition"))
  expect_eq(a$PERIODC, c("control", "transition", "intervention",
                         "control", "control", "control", NA, "control", "transition",
                         "intervention"))
  expect_equal(as.character(a$TRT01P),
               c("WHO", NA, "LCG", "WHO", "WHO", "WHO", "WHO", "WHO", NA, NA))
  expect_eq(a$PERDISFL[10], "Y")          # form (transition) differs from schedule
  expect_eq(a$PASFL, c("Y", "N", "Y", "Y", "Y", "Y", "N", "Y", "N", "N"))
  expect_eq(a$TRNSFL[c(2, 9, 10)], c("Y", "Y", "Y"))
  expect_eq(a$EXPOSN[3], 10L)             # LCG from step 3, birth in step 12
  # twin rules: CS of twin 2 only -> woman CS at full dilation;
  # twin 2 mode missing -> twin 1's mode
  expect_eq(a$MODE[1:7], c("SVD", "SVD", "SVD", "CS", "IVD", "CS", "SVD"))
  expect_eq(a$CXCSN[4], 10)
  # no principal stratum and no pre-4 cm flags from SAP v0.9 (item 69)
  expect_false(any(c("PSTRFL", "PSTR4FL", "AMNIOB4FL", "OXYB4FL", "EDAB4FL") %in% names(a)))
  expect_eq(a$VDSFL, c("Y", "N", "Y", "N", "Y", "N", "N", "Y", "N", "N"))
  expect_equal(as.character(a$HOSPBIRC[c(1, 4)]), c("1000-1999", ">= 4000"))
  # coded values are translated to English (metadata/codelists.csv)
  expect_eq(a$MODEDTL[1:7], c(rep("Spontaneous vaginal delivery", 3),
                              "Spontaneous vaginal delivery", "Vacuum delivery",
                              "Intrapartum caesarean section",
                              "Spontaneous vaginal delivery"))
  expect_error(make_adsl(dplyr::mutate(raw, fodested = "Z"), hospitals, codelists, cfg),
               "not in metadata/hospitals.csv")
  expect_error(make_adsl(dplyr::mutate(raw, nokkel = "CTR-001"), hospitals, codelists, cfg),
               "not unique")
  expect_error(make_adsl(dplyr::mutate(raw, nokkel = sub("CTR", "XYZ", nokkel)),
                         hospitals, codelists, cfg), "prefix")
  expect_warning(make_adsl(dplyr::mutate(raw, treatment = "control"), hospitals, codelists, cfg),
                 "prefix differs")
  # without lookups the continent and percentile are NA
  expect_true(all(is.na(a$CONTINENT)) && all(is.na(a$BWPCT)))
})

test_that("make_adsl derives continent, birthweight percentile and category from the lookups", {
  tmp <- withr::local_tempdir()
  env <- environment(make_adsl)
  path_adam_orig <- get("path_adam", envir = env)
  withr::defer(assign("path_adam", path_adam_orig, envir = env))
  assign("path_adam", function(...) fs::path(tmp, "ad", ...), envir = env)

  r <- raw[1:4, ]
  r$landbakgrunn <- c("Norge", "Pakistan", "", "Atlantis")
  r$barnets_kjonn <- c("gutt", "jente", "gutt", "vet_ikke")
  r$gestasjonsalder_ved_fodsel_hele_uker <- c(40, 40, 30, 40)
  r$gestasjonsalder_ved_fodsel_pluss_dager <- 0
  r$fodselsvekt_gram <- c(3725, 2900, 1000, 3500)
  lookups <- list(
    continent = tibble::tibble(code = c("Norge", "Pakistan"), country_en = c("Norway", "Pakistan"),
                               continent = c("Europe", "Asia")),
    bwref = tibble::tibble(sex = c("male", "female", "male"), ga_weeks = c(40, 40, 30),
                           mean = c(3725, 3575, 1590), sd = c(460, 440, 270))
  )
  a <- expect_warning(make_adsl(r, hospitals, codelists, cfg, lookups), "Atlantis")
  expect_eq(a$CONTINENT, c("Europe", "Asia", NA, NA))
  # boy at the mean = 50th percentile; girl 2900 g at 40 w: z = -675/440
  expect_equal(a$BWPCT[1:3], 100 * stats::pnorm(c(0, (2900 - 3575) / 440, (1000 - 1590) / 270)))
  expect_true(is.na(a$BWPCT[4]))                     # unknown sex
  expect_eq(a$BWPCTC[1:3], c("Appropriate (10th-90th percentile)", "Small (< 10th percentile)",
                             "Small (< 10th percentile)"))
  expect_equal(as.character(a$BWCAT), c("3500-3999 g", "< 3000 g", "< 3000 g", "3500-3999 g"))
})
