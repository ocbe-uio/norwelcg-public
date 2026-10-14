# make_adlp.R — raw + ADSL -> ADaM ADLP (BDS, one row per cervical examination).
#
# The database records, for each centimetre k, the time of the vaginal
# examination at which k cm was found (cx_<k>cm). The imputation of the time of
# reaching 4 cm (time to vaginal delivery, SAP 5.1.1.5) uses a labour-curve
# model with time measured backwards from delivery, so each row carries the
# dilation found (CMN) and the time from the examination to the birth of the
# first baby (AVAL, hours).
#
#   PARAMCD  TTDLV   Time from cervical examination to delivery (hours)
#   ANL01FL  "Y" if 0 < AVAL < 72 h, every dilatation (final cleaning rule 3,
#            review item 52); sentinel-year timestamps (before 2024) are
#            dropped.

make_adlp <- function(raw, adsl, cfg) {
  stopifnot(nrow(raw) == nrow(adsl))
  lo <- as.POSIXct("2024-01-01", tz = "UTC")
  pt <- function(x) lubridate::ymd_hm(as.character(x), quiet = TRUE)

  adlp <- purrr::map(1:10, function(k) {
    tibble::tibble(USUBJID = adsl$USUBJID, CMN = k,
                   ADTM = pt(raw[[paste0("cx_", k, "cm")]]),
                   BIRTHDTM = adsl$BIRTHDTM)
  }) |>
    dplyr::bind_rows() |>
    dplyr::filter(!is.na(ADTM), ADTM >= lo) |>
    dplyr::mutate(
      PARAMCD = "TTDLV",
      PARAM   = "Time from cervical examination to delivery (hours)",
      PARCAT1 = "LABOUR PROGRESSION",
      AVAL    = as.numeric(difftime(BIRTHDTM, ADTM, units = "hours")),
      ANL01FL = dplyr::if_else(AVAL > 0 & AVAL < 72, "Y", "N", missing = "N")
    ) |>
    dplyr::select(-BIRTHDTM) |>
    dplyr::left_join(
      adsl |>
        dplyr::select(STUDYID, USUBJID, SITEID, CLUSTER, STEPN, STEP,
                      TRT01P, TRT01PN, TRT01A, FASFL, PASFL, VDSFL,
                      MODE, ROBSON, AGE, BMIPREG, HEIGHT, BWT, GA),
      by = "USUBJID"
    ) |>
    dplyr::arrange(USUBJID, CMN) |>
    dplyr::relocate(STUDYID) |>
    labelled::set_variable_labels(
      PARAMCD = "Parameter code",
      PARAM   = "Parameter",
      PARCAT1 = "Parameter category 1",
      CMN     = "Cervical dilatation found at the examination (cm)",
      ADTM    = "Datetime of the examination",
      AVAL    = "Time from the examination to delivery (hours)",
      ANL01FL = "Analysis flag (0 < AVAL < 72 h)"
    )

  fs::dir_create(path_adam())
  readr::write_rds(adlp, path_adam("adlp.rds"))
  adlp
}
