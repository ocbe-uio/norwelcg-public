# make_rddsc.R — descriptive reporting summaries (no models).
#
# SAP 6: descriptive/exploratory endpoints are presented descriptively in the
# main report; the SAP 4.1.3 covariates and baseline characteristics are
# summarised by arm as the baseline table. Primary analysis set (cfg popfl),
# counts by TRT01P with the reference arm first.
#
# Returns (and writes to data/rd/rddsc.rds) a list of tidy tibbles:
#   $baseline_cat  ADSL categorical characteristics: variable, label, category,
#                  n/pct per arm (pct of non-missing), missing as "(missing)",
#                  Y/N flags shown as Yes/No; includes the hospital's annual
#                  number of deliveries (SAP 12.2 v0.9)
#   $baseline_cont ADSL continuous characteristics: mean/sd/median/q1/q3/n_miss per arm
#   $endpoints     ADEFF PARCAT1 == "DESCRIPTIVE": per PARAMCD x category
#                  counts/pct per arm (categories from AVALC, or 0/1 AVAL
#                  shown as No/Yes for the dichotomous descriptive params),
#                  among the women the
#                  endpoint applies to (ANL01FL: CS for the CS characteristics,
#                  the LCG period and the gate for shared decision making)
#   $numeric       ADEFF ATYPE == "NUM" (cord gases, Apgar scores) and
#                  estimated blood loss: n/mean/sd/median/q1/q3 per arm
#   $exams         ADLP: cervical examinations by dilatation found and arm —
#                  n, median [q1, q3] hours from the examination to delivery
#                  (analysis-flagged examinations)
#   $t0obs         ADLP: observed time from the examination at the time origin
#                  (4 cm) to delivery, vaginal deliveries, per arm (median,
#                  quartiles, 90th pct)

make_rddsc <- function(adsl, adeff, adlp, cfg) {
  sl <- filter_pop(adsl, cfg)

  cat_vars  <- c("HOSPBIRC", "CONTINENT", "NORWAYFL", "COHABFL", "HIEDUFL", "SMOKEFL", "SNUSFL",
                 "DIABFL", "HTNFL", "PARITY", "NULLIPFL", "PREVCSFL",
                 "FVDFL", "SPONTFL", "INDUCFL", "ROBSON", "SEX", "TWINFL", "BWCAT")
  # height is an adjustment covariate but not in the baseline table (SAP 12.2)
  cont_vars <- c("AGE", "WGTPREG", "BMIPREG", "GA", "BWT", "HDCIRC")
  k0 <- cfg$analysis$tte$origin_cm %||% 4
  var_label <- function(data, v) labelled::var_label(data[[v]]) %||% v

  # category order: numeric when every category carries a number ("3 cm",
  # "Robson group 10", "<= 500"), "Not recorded" and "(missing)" last;
  # otherwise alphabetical
  cat_order <- function(category) {
    k <- suppressWarnings(readr::parse_number(category))
    tail_cat <- category %in% c("(missing)", "Not recorded")
    num_ok <- all(!is.na(k[!tail_cat]))
    order(category == "(missing)", category == "Not recorded",
          if (num_ok) k else rep(0, length(k)), category)
  }

  # counts/pct per arm with stable columns n_ref/pct_ref/n_int/pct_int
  # (reference arm = first TRT01P level); pct of the arm's non-missing
  arm_counts <- function(data, value) {
    data |>
      dplyr::mutate(category = dplyr::coalesce(as.character({{ value }}),
                                               "(missing)"),
                    arm = c("ref", "int")[as.integer(TRT01P)]) |>
      dplyr::count(arm, category) |>
      dplyr::mutate(pct = 100 * n /
                      sum(n[category != "(missing)"]),
                    pct = dplyr::if_else(category == "(missing)", NA_real_, pct),
                    .by = arm) |>
      tidyr::pivot_wider(names_from = arm, values_from = c(n, pct),
                         values_fill = list(n = 0L),
                         names_vary = "slowest") |>
      (\(x) {
        # an arm with no rows (e.g. LCG-form-only items in the WHO arm)
        for (a in c("ref", "int")) {
          if (!paste0("n_", a) %in% names(x)) x[[paste0("n_", a)]] <- 0L
          if (!paste0("pct_", a) %in% names(x)) x[[paste0("pct_", a)]] <- NA_real_
        }
        x[cat_order(x$category), c("category", "n_ref", "pct_ref", "n_int", "pct_int")]
      })()
  }

  baseline_cat <- purrr::map(cat_vars, function(v) {
    x <- sl[[v]]
    if (grepl("FL$", v)) x <- dplyr::recode(x, Y = "Yes", N = "No")
    arm_counts(dplyr::mutate(sl, .x = x), .x) |>
      dplyr::mutate(variable = v, label = var_label(sl, v), .before = 1)
  }) |> dplyr::bind_rows()

  baseline_cont <- purrr::map(cont_vars, function(v) {
    sl |>
      dplyr::summarise(
        n = sum(!is.na(.data[[v]])), n_miss = sum(is.na(.data[[v]])),
        mean = mean(.data[[v]], na.rm = TRUE),
        sd = stats::sd(.data[[v]], na.rm = TRUE),
        median = stats::median(.data[[v]], na.rm = TRUE),
        q1 = stats::quantile(.data[[v]], 0.25, na.rm = TRUE),
        q3 = stats::quantile(.data[[v]], 0.75, na.rm = TRUE),
        .by = TRT01P
      ) |>
      dplyr::arrange(TRT01P) |>                       # reference arm first
      dplyr::mutate(variable = v, label = var_label(sl, v), .before = 1)
  }) |> dplyr::bind_rows()

  endpoints <- filter_pop(adeff, cfg) |>
    dplyr::filter(PARCAT1 == "DESCRIPTIVE", ANL01FL == "Y") |>
    dplyr::mutate(value = dplyr::coalesce(AVALC, as.character(AVAL))) |>
    (\(d) purrr::map(unique(d$PARAMCD), function(p) {
      dp <- d[d$PARAMCD == p, ]
      # dichotomous (0/1 AVAL, no AVALC): No/Yes
      if (all(is.na(dp$AVALC)) && all(dp$AVAL %in% c(0, 1, NA)))
        dp$value <- c("No", "Yes")[dp$AVAL + 1]
      arm_counts(dp, value) |>
        dplyr::mutate(PARAMCD = p, PARAM = dp$PARAM[1],
                      PARCAT2 = dp$PARCAT2[1], .before = 1)
    }))() |>
    dplyr::bind_rows()

  exams <- filter_pop(adlp, cfg) |>
    dplyr::filter(ANL01FL == "Y") |>
    dplyr::summarise(
      n = dplyr::n(), women = dplyr::n_distinct(USUBJID),
      median = stats::median(AVAL),
      q1 = stats::quantile(AVAL, 0.25),
      q3 = stats::quantile(AVAL, 0.75),
      .by = c(CMN, TRT01P)
    ) |>
    dplyr::arrange(CMN, TRT01P)

  # numeric endpoints and auxiliaries (cord gases, Apgar, blood loss)
  numeric <- filter_pop(adeff, cfg) |>
    dplyr::filter(ATYPE == "NUM" | PARAMCD == "PPHCAT") |>
    dplyr::summarise(
      n = sum(!is.na(AVAL)), n_miss = sum(is.na(AVAL)),
      mean = mean(AVAL, na.rm = TRUE), sd = stats::sd(AVAL, na.rm = TRUE),
      median = stats::median(AVAL, na.rm = TRUE),
      q1 = stats::quantile(AVAL, 0.25, na.rm = TRUE),
      q3 = stats::quantile(AVAL, 0.75, na.rm = TRUE),
      .by = c(PARAMCD, PARAM, TRT01P)
    ) |>
    dplyr::arrange(PARAMCD, TRT01P)

  # observed time from the examination at the time origin (4 cm) to delivery
  # (vaginal deliveries)
  t0obs <- filter_pop(adlp, cfg) |>
    dplyr::filter(ANL01FL == "Y", CMN == k0, MODE %in% c("SVD", "IVD")) |>
    dplyr::summarise(
      n = dplyr::n(), median = stats::median(AVAL),
      q1 = stats::quantile(AVAL, 0.25), q3 = stats::quantile(AVAL, 0.75),
      p90 = stats::quantile(AVAL, 0.90), .by = TRT01P
    )

  rddsc <- list(baseline_cat = baseline_cat, baseline_cont = baseline_cont,
                endpoints = endpoints, numeric = numeric,
                exams = exams, t0obs = t0obs)
  fs::dir_create(path_rd())
  readr::write_rds(rddsc, path_rd("rddsc.rds"))
  rddsc
}
