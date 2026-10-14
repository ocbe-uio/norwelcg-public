# blinded_checks.R — BLINDED aggregate tables for the blinded data review
# (docs/sap/sap_data_review.md item 53; from items 22, 31, 41(1), 41(6), 41(11),
# 41(15)). SAFE environment.
#
#   From the project root (SAFE environment, on the real export):
#     Rscript R/blinded_review/blinded_checks.R
#   In dev, to exercise the code on the anonymised copy (associations are null
#   there by construction):
#     Rscript R/blinded_review/blinded_checks.R --anon
#
#   writes outputs/blinded_checks/<table>.csv (outputs/blinded_checks_anon/
#   with --anon) and prints every table.
#
# Blinding: all tables are pooled over the study periods, except
# `period_schedule` and `period_dates`, which cross the documentation-form
# period with hospital and calendar time and contain no outcome. No table
# combines an outcome with period, step or treatment. Output is aggregate
# counts only (no record keys, no individual values).

# a coded value, with blanks shown as "(missing)"
bc_code <- function(x) {
  x <- as.character(x)
  dplyr::if_else(is.na(x) | x == "", "(missing)", x)
}

# a checkbox child under its gate question: children are NA when the gate is
# "No", so NA counts as "no" when the gate is answered
bc_tick <- function(x, gate) {
  dplyr::case_when(
    suppressWarnings(as.numeric(x)) %in% 1 ~ "yes",
    suppressWarnings(as.numeric(gate)) %in% c(0, 1) ~ "no",
    .default = "(missing)"
  )
}

# two-way count with row percentages, long format
bc_xtab <- function(row, col, row_name, col_name) {
  tibble::tibble(r = row, c = col) |>
    dplyr::count(r, c, name = "n") |>
    dplyr::group_by(r) |>
    dplyr::mutate(pct_row = round(100 * n / sum(n), 1)) |>
    dplyr::ungroup() |>
    dplyr::rename(!!row_name := r, !!col_name := c)
}

# raw: the export with canonical column names (make_raw_norwel());
# adsl: make_adsl() on the same raw; hospitals: metadata/hospitals.csv
blinded_checks <- function(raw, adsl, hospitals, cfg, ph_limits = c(6.5, 7.8)) {
  num <- function(x) suppressWarnings(as.numeric(x))
  has <- function(x) !is.na(x) & as.character(x) != ""
  mode1 <- bc_code(raw$forlosningsmetode)
  vag <- raw$forlosningsmetode %in% c("spontan_vaginal_fodsel", "tang", "vakuum")
  twin <- has(raw$tv2_fodselstidspunkt) | has(raw$tv2_forlosningsmetode)
  out <- list()

  # ---- spinal and pudendal x mode of delivery / perineal tear (41(6), DM 13) --
  # row % of "yes" = how much of the use sits in CS / instrumental deliveries
  gate <- raw$medikamentell_smertelindring
  for (m in c("spinal", "pudendal")) {
    x <- bc_tick(raw[[paste0("type_medikamentell_smertelindring_", m)]], gate)
    out[[paste0(m, "_by_mode")]] <- bc_xtab(x, mode1, m, "mode_twin1")
    out[[paste0(m, "_by_tear")]] <- bc_xtab(x[vag], bc_code(raw$perinealrift[vag]),
                                            m, "perineal_tear_vaginal")
  }

  # ---- episiotomy x mode of delivery (41(11)) --------------------------------
  # row % = episiotomy rate per mode, including episiotomies recorded for CS
  out$episiotomy_by_mode <- bc_xtab(mode1, bc_code(raw$episiotomi),
                                    "mode_twin1", "episiotomy")

  # ---- cord blood gas measured, by hospital and by mode (41(15), PI 12) -------
  pa <- num(raw$ph_arterie)
  pv <- num(raw$ph_vene)
  gas <- dplyr::case_when(
    !is.na(pa) & pa >= ph_limits[1] & pa <= ph_limits[2] ~ "arterial (plausible)",
    !is.na(pa)                                           ~ "arterial (out of range)",
    !is.na(pv)                                           ~ "venous only",
    .default                                             = "no cord gas"
  )
  out$cordgas_by_hospital <- bc_xtab(bc_code(raw$fodested), gas, "hospital", "cord_gas_twin1")
  out$cordgas_by_mode <- bc_xtab(mode1, gas, "mode_twin1", "cord_gas_twin1")

  # ---- twin 1 x twin 2 mode of delivery (41(1), DM 15) -----------------------
  out$twin_modes <- bc_xtab(mode1[twin], bc_code(raw$tv2_forlosningsmetode[twin]),
                            "mode_twin1", "mode_twin2")

  # ---- documentation form vs scheduled period (22, PI 1) ----------------------
  # scheduled = metadata/hospitals.csv (planned until PI 1 is answered);
  # form = the source file. Births inside the inclusion window only.
  inwin <- dplyr::filter(adsl, INWINFL %in% "Y")
  out$period_schedule <- inwin |>
    dplyr::group_by(SITEID, STEPN, scheduled = PERIODC) |>
    dplyr::summarise(
      n                 = dplyr::n(),
      form_control      = sum(FORMPER %in% "control"),
      form_transition   = sum(FORMPER %in% "transition"),
      form_intervention = sum(FORMPER %in% "intervention"),
      n_discordant      = sum(FORMPER != PERIODC, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(SITEID, STEPN)

  # first and last birth per hospital and form period against the scheduled
  # dates: the observed crossover dates PI 1 asks for, and how many births of
  # each form fall outside its scheduled period
  sw_start <- as.Date(cfg$sw$start)
  sw_end <- as.Date(cfg$sw$end)
  step_start <- function(k) sw_start + 7 * (cfg$sw$step_weeks %||% 5) * (k - 1)
  sched <- hospitals |>
    dplyr::transmute(
      SITEID,
      trans_start = step_start(TRANS_STEP),
      lcg_start   = step_start(LCG_STEP)
    )
  out$period_dates <- inwin |>
    dplyr::left_join(sched, by = "SITEID") |>
    dplyr::mutate(
      sched_from = dplyr::case_when(
        FORMPER == "control"      ~ sw_start,
        FORMPER == "transition"   ~ trans_start,
        FORMPER == "intervention" ~ lcg_start
      ),
      sched_to = dplyr::case_when(
        FORMPER == "control"      ~ trans_start - 1,
        FORMPER == "transition"   ~ lcg_start - 1,
        FORMPER == "intervention" ~ sw_end
      )
    ) |>
    dplyr::group_by(SITEID, form = FORMPER) |>
    dplyr::summarise(
      n                  = dplyr::n(),
      first_birth        = min(BIRTHDT),
      last_birth         = max(BIRTHDT),
      scheduled_from     = dplyr::first(sched_from),
      scheduled_to       = dplyr::first(sched_to),
      n_outside_schedule = sum(BIRTHDT < sched_from | BIRTHDT > sched_to, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(SITEID, first_birth)

  # ---- primary endpoint: missing data (31; repeat on the locked database) ----
  out$primary_missing <- tibble::tribble(
    ~check,                                                  ~n,
    "women",                                                 nrow(adsl),
    "mode of delivery (twin 1) not recorded",                sum(mode1 == "(missing)"),
    "twin pregnancies",                                      sum(twin),
    "twin 2 mode of delivery not recorded",                  sum(twin & !has(raw$tv2_forlosningsmetode)),
    "woman-level mode of delivery missing",                  sum(is.na(adsl$MODEN)),
    "intrapartum caesarean sections (woman level)",          sum(adsl$ICSFL %in% "Y"),
    "caesarean section without cervical dilatation",         sum(adsl$ICSFL %in% "Y" & is.na(adsl$CXCSN)),
    "caesarean section at <= 4 cm (counted in the primary)", sum(adsl$ICSFL %in% "Y" & adsl$CXCSN %in% 0:4),
    "hospital not in metadata/hospitals.csv",                sum(is.na(adsl$CLUSTER)),
    "time of birth missing or outside the inclusion window", sum(!adsl$INWINFL %in% "Y"),
    "scheduled study period missing",                       sum(is.na(adsl$PERIODC))
  )

  out
}

if (sys.nframe() == 0L) {
  stopifnot("run from the project root" = file.exists("config/cfg.yml"))
  suppressMessages(library(dplyr))
  for (f in c("R/external/functions.R", "R/make_raw/make_raw_norwel.R",
              "R/make_raw/read_norwel_raw.R", "R/helpers/codelists.R",
              "R/make_ad/make_adsl.R")) {
    source(f)
  }
  anon <- "--anon" %in% commandArgs(trailingOnly = TRUE)
  cfg <- yaml::read_yaml("config/cfg.yml")
  # the real export whatever cfg$mode says (sham mode would read the anon copy)
  raw <- make_raw_norwel(utils::modifyList(cfg, list(mode = if (anon) "sham" else "true")))
  hospitals <- readr::read_csv(cfg$hospitals_file, comment = "#", show_col_types = FALSE)
  codelists <- readr::read_csv(cfg$codelists_file, comment = "#", show_col_types = FALSE)
  adsl <- suppressWarnings(make_adsl(raw, hospitals, codelists, cfg))
  res <- blinded_checks(raw, adsl, hospitals, cfg)

  dir <- file.path("outputs", if (anon) "blinded_checks_anon" else "blinded_checks")
  fs::dir_create(dir)
  for (nm in names(res)) {
    readr::write_csv(res[[nm]], file.path(dir, paste0(nm, ".csv")))
    cat("\n==", nm, "==\n")
    print(as.data.frame(res[[nm]]), row.names = FALSE)
  }
  cat("\nwritten to", dir, if (anon) "(ANONYMISED COPY — code check only)" else "", "\n")
}
