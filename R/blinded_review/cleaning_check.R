# cleaning_check.R — BLINDED data-cleaning check: flags implausible and
# internally inconsistent values for review against the source records.
# Rules and thresholds: docs/sap/data_cleaning_rules.md.
#
#   From the project root (SAFE environment, on the real export):
#     Rscript R/blinded_review/cleaning_check.R
#   In dev, to exercise the code on the anonymised copy (synthetic keys):
#     Rscript R/blinded_review/cleaning_check.R --anon
#
#   writes outputs/cleaning_flags.csv  one row per flagged value
#                                      (record key, rule, variable, value)
#         outputs/cleaning_summary.csv counts per rule
#   (outputs/cleaning_*_anon.csv with --anon)
#
# Blinded: no treatment, period or hospital variable is used or reported; the
# record key (`nokkel`) is included so the data managers can retrieve the
# record. Runs on the raw export (make_raw_norwel() output or the .dta files
# read by read_norwel_raw()).

CLEANING_LIMITS <- list(
  year      = c(2024, 2027),   # plausible calendar years for all timestamps
  exam_h    = c(0, 72),        # hours to delivery, every examination: outside the
                               # open interval (0, 72) the examination is not used
                               # (ADLP ANL01FL; final rule 3, item 52)
  cm_step_h = c(0, 24),        # hours from one centimetre to the next, from 4 cm
  cm_step_h_lo = c(0, 72),     # ... below 4 cm (flag only; intervals are not used)
  height    = c(130, 220),     # cm
  weight    = c(35, 250),      # kg, pre-pregnancy
  bmi       = c(13, 70),       # kg/m2
  age       = c(18, 55),       # years
  ga_weeks  = c(22, 45),       # completed weeks
  ga_days   = c(0, 6),         # plus days
  bwt       = c(300, 6500),    # g
  hdcirc    = c(20, 45),       # cm
  apgar     = c(0, 10),
  ph        = c(6.5, 7.55),    # arterial and venous (SAP v0.9)
  be        = c(-25, 25),      # base excess (SAP v0.9)
  bd        = c(-25, 25),      # base deficit (SAP v0.9)
  blood_ml  = c(0, 5000)       # estimated blood loss, ml
)

cleaning_check <- function(raw, limits = CLEANING_LIMITS) {
  key <- if ("nokkel" %in% names(raw)) as.character(raw$nokkel) else sprintf("row_%05d", seq_len(nrow(raw)))
  flags <- list()
  add <- function(rule, variable, keep, value) {
    keep <- keep & !is.na(keep)
    if (!any(keep)) return(invisible(NULL))
    flags[[length(flags) + 1L]] <<- tibble::tibble(
      nokkel = key[keep], rule = rule, variable = variable,
      value = as.character(value[keep])
    )
  }
  num <- function(x) suppressWarnings(as.numeric(x))
  pt <- function(x) {
    if (inherits(x, "POSIXt")) return(as.POSIXct(x))
    lubridate::ymd_hm(as.character(x), quiet = TRUE)
  }
  outside <- function(x, lim) !is.na(x) & (x < lim[1] | x > lim[2])

  # ---- timestamps: sentinel / impossible years ------------------------------
  tcols <- c(grep("^cx_[0-9]+cm$", names(raw), value = TRUE),
             grep("^(tidspunkt_|ny|tv2_tidspunkt_|tv2_fodselstidspunkt|start_trykketid|fodselstidspunkt|kvinnens_opplevelse_latensfasens_start)",
                  names(raw), value = TRUE))
  tcols <- intersect(unique(tcols), names(raw))
  for (v in tcols) {
    x <- pt(raw[[v]])
    yr <- as.integer(format(x, "%Y"))
    add("timestamp year outside the trial period", v, outside(yr, limits$year), raw[[v]])
  }

  birth <- dplyr::coalesce(pt(raw[["nyfodselstidspunkt"]] %||% NA),
                           pt(raw[["fodselstidspunkt"]]))
  adm <- dplyr::coalesce(pt(raw[["nytidinnleggelse"]] %||% NA),
                         pt(raw[["tidspunkt_innleggelse"]]))
  add("admission after delivery", "tidspunkt_innleggelse",
      !is.na(adm) & !is.na(birth) & adm > birth, format(adm))

  # ---- cervical examinations -------------------------------------------------
  cx <- lapply(1:10, function(k) pt(raw[[paste0("cx_", k, "cm")]]))
  # one window for every dilatation, as in the analysis (ADLP: 0 < h < 72)
  for (k in 1:10) {
    lim <- limits$exam_h
    h <- as.numeric(difftime(birth, cx[[k]], units = "hours"))
    add(sprintf("time from the %d cm examination to delivery not in (%g, %g) h", k,
                lim[1], lim[2]),
        paste0("cx_", k, "cm"), !is.na(h) & (h <= lim[1] | h >= lim[2]), round(h, 2))
  }
  for (k in 1:9) {
    lim <- if (k >= 4) limits$cm_step_h else limits$cm_step_h_lo
    h <- as.numeric(difftime(cx[[k + 1]], cx[[k]], units = "hours"))
    add(sprintf("time from %d to %d cm outside %g-%g h", k, k + 1, lim[1], lim[2]),
        sprintf("cx_%dcm -> cx_%dcm", k, k + 1), outside(h, lim), round(h, 2))
  }

  # ---- maternal characteristics ---------------------------------------------
  h <- num(raw$hoyde); w <- num(raw$pregravid_vekt)
  add("height outside plausible range", "hoyde", outside(h, limits$height), h)
  add("pre-pregnancy weight outside plausible range", "pregravid_vekt", outside(w, limits$weight), w)
  add("pre-pregnancy BMI outside plausible range", "hoyde / pregravid_vekt",
      outside(w / (h / 100)^2, limits$bmi), round(w / (h / 100)^2, 1))
  if ("alder" %in% names(raw)) {
    add("maternal age outside the eligible range", "alder",
        outside(num(raw$alder), limits$age), num(raw$alder))
  }

  # ---- neonatal characteristics ----------------------------------------------
  for (pre in c("", "tv2_")) {
    gw <- num(raw[[paste0(pre, "gestasjonsalder_ved_fodsel_hele_uker")]])
    gd <- num(raw[[paste0(pre, "gestasjonsalder_ved_fodsel_pluss_dager")]])
    add("gestational age (weeks) outside plausible range",
        paste0(pre, "gestasjonsalder_ved_fodsel_hele_uker"), outside(gw, limits$ga_weeks), gw)
    add("gestational age (plus days) outside 0-6",
        paste0(pre, "gestasjonsalder_ved_fodsel_pluss_dager"), outside(gd, limits$ga_days), gd)
    bw <- num(raw[[paste0(pre, "fodselsvekt_gram")]])
    add("birth weight outside plausible range", paste0(pre, "fodselsvekt_gram"),
        outside(bw, limits$bwt), bw)
    hc <- num(raw[[paste0(pre, "neonatal_hodeomkrets")]])
    add("head circumference outside plausible range", paste0(pre, "neonatal_hodeomkrets"),
        outside(hc, limits$hdcirc), hc)
    for (m in c("1min", "5min", "10min")) {
      ap <- num(raw[[paste0(pre, "apgar_skar_", m)]])
      add("Apgar score outside 0-10", paste0(pre, "apgar_skar_", m), outside(ap, limits$apgar), ap)
    }
    pa <- num(raw[[paste0(pre, "ph_arterie")]]); pv <- num(raw[[paste0(pre, "ph_vene")]])
    add("arterial cord pH outside plausible range", paste0(pre, "ph_arterie"),
        outside(pa, limits$ph), pa)
    add("venous cord pH outside plausible range", paste0(pre, "ph_vene"),
        outside(pv, limits$ph), pv)
    ok <- !outside(pa, limits$ph) & !outside(pv, limits$ph) & !is.na(pa) & !is.na(pv)
    add("arterial cord pH higher than venous (samples swapped?)",
        paste0(pre, "ph_arterie / ", pre, "ph_vene"), ok & pa > pv,
        paste0(pa, " / ", pv))
    for (b in c("base_excess_arterie", "base_excess_vene", "base_deficit_arterie",
                "base_deficit_vene")) {
      x <- num(raw[[paste0(pre, b)]])
      lim <- if (grepl("deficit", b)) limits$bd else limits$be
      add("base excess/deficit outside plausible range", paste0(pre, b), outside(x, lim), x)
    }
  }

  # ---- delivery, blood loss, perineum ----------------------------------------
  bl <- num(raw$blodtap_ml_inntil_2timer_pp)
  add("estimated blood loss outside plausible range", "blodtap_ml_inntil_2timer_pp",
      outside(bl, limits$blood_ml), bl)
  cs <- raw$forlosningsmetode %in% "akutt_sectio"
  vag <- !is.na(raw$forlosningsmetode) & !cs
  add("caesarean section without cervical dilatation", "cx_akutt_sectio",
      cs & (is.na(raw$cx_akutt_sectio) | raw$cx_akutt_sectio == ""), raw$cx_akutt_sectio)
  add("cervical dilatation recorded without a caesarean section", "cx_akutt_sectio",
      !cs & !is.na(raw$cx_akutt_sectio) & raw$cx_akutt_sectio != "", raw$cx_akutt_sectio)
  add("perineal tear recorded after a caesarean section", "perinealrift",
      cs & num(raw$perinealrift) == 1, raw$perinealrift)
  add("perineal support recorded after a caesarean section", "perineal_stotteteknikk",
      cs & num(raw$perineal_stotteteknikk) == 1, raw$perineal_stotteteknikk)
  add("perineal support not recorded after a vaginal delivery", "perineal_stotteteknikk",
      vag & is.na(num(raw$perineal_stotteteknikk)), NA_character_)
  add("perineal tear status not recorded after a vaginal delivery", "perinealrift",
      vag & is.na(num(raw$perinealrift)), NA_character_)
  grades <- grep("^perinealrift_grad", names(raw), value = TRUE)
  if (length(grades)) {
    ticked <- rowSums(sapply(raw[grades], function(x) num(x) %in% 1)) > 0
    add("tear grade ticked without a recorded tear", "perinealrift_grad.*",
        ticked & !(num(raw$perinealrift) %in% 1), NA_character_)
    add("tear recorded without a grade", "perinealrift_grad.*",
        num(raw$perinealrift) %in% 1 & !ticked, NA_character_)
  }

  # ---- twins -------------------------------------------------------------------
  twin <- !is.na(raw$tv2_fodselstidspunkt) & as.character(raw$tv2_fodselstidspunkt) != ""
  add("second twin without a mode of delivery", "tv2_forlosningsmetode",
      twin & (is.na(raw$tv2_forlosningsmetode) | raw$tv2_forlosningsmetode == ""), NA_character_)

  # ---- intervention gates vs their details ------------------------------------
  pairs <- list(c("amniotomi", "cervix_apning_amniotomi"),
                c("oxytocin_infusjon", "cx_oppstart_oxytocin_infusjon"),
                c("medikamentell_smertelindring", "cx_start_eda"))
  for (p in pairs) {
    if (!all(p %in% names(raw))) next
    g <- num(raw[[p[1]]]); x <- raw[[p[2]]]
    add("detail recorded while the intervention is marked as not done", p[2],
        g %in% 0 & !is.na(x) & as.character(x) != "", x)
  }

  # ---- fetal monitoring --------------------------------------------------------
  mon <- grep("^fosterovervaking", names(raw), value = TRUE)
  if (length(mon) > 1) {
    none <- num(raw[["fosterovervaking_ingen"]]) %in% 1
    other <- rowSums(sapply(raw[setdiff(mon, "fosterovervaking_ingen")],
                            function(x) num(x) %in% 1)) > 0
    add("'no fetal monitoring' ticked together with a monitoring method",
        "fosterovervaking.*", none & other, NA_character_)
    add("no fetal monitoring item ticked at all", "fosterovervaking.*",
        !none & !other, NA_character_)
  }

  out <- dplyr::bind_rows(flags)
  if (nrow(out) == 0) return(out)
  dplyr::arrange(out, rule, nokkel)
}

if (sys.nframe() == 0L) {
  suppressMessages({library(dplyr); library(here)})
  source(here::here("R", "external", "functions.R"))
  source(here::here("R", "make_raw", "make_raw_norwel.R"))
  source(here::here("R", "make_raw", "read_norwel_raw.R"))
  cfg <- yaml::read_yaml(here::here("config", "cfg.yml"))
  anon <- "--anon" %in% commandArgs(trailingOnly = TRUE)
  # the real export whatever cfg$mode says: in sham mode make_raw_norwel()
  # reads the anonymised copy, whose synthetic keys the DMs cannot look up
  raw <- make_raw_norwel(utils::modifyList(cfg, list(mode = if (anon) "sham" else "true")))
  fl <- cleaning_check(raw)
  sfx <- if (anon) "_anon" else ""
  fs::dir_create(here::here("outputs"))
  readr::write_csv(fl, here::here("outputs", paste0("cleaning_flags", sfx, ".csv")))
  summ <- fl |> count(rule, variable, name = "n") |> arrange(desc(n))
  readr::write_csv(summ, here::here("outputs", paste0("cleaning_summary", sfx, ".csv")))
  cat("flagged values:", nrow(fl), "in", dplyr::n_distinct(fl$nokkel), "records\n")
  print(as.data.frame(summ), row.names = FALSE)
}
