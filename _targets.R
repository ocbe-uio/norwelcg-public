# =========================================================
# _targets.R — NORWELCG analysis pipeline
#
#   data/raw (anonymised rds | per-period .dta)  -> R/make_raw
#             -> ADaM (R/make_ad: adsl, adeff, adlp)
#             -> RD   (R/make_rd: reporting datasets and models)
#             -> report (reports/statistical_analysis.qmd)
#
# No SDTM stage: the export is one row per woman. cfg$mode = "sham" in
# development; "true" only after database lock (CLAUDE.md).
# =========================================================

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c(
    # core / tidyverse
    "tibble", "dplyr", "tidyr", "purrr", "stringr", "readr", "readxl",
    "labelled", "glue", "fs", "here", "rlang", "yaml", "lubridate", "withr",
    # de-identification: "sdcMicro" is optional (risk readout only)
    # pharmaverse: raw -> SDTM -> ADaM
    "sdtm.oak", "admiral",
    # (optional, metadata-driven) "metacore", "metatools", "xportr",
    # analysis / reporting
    "lme4", "emmeans", "marginaleffects", "broom", "survival", "survminer",
    # "DoseFinding",  # only for dose-finding / MCP-Mod trials
    "rtables", "rtables.officer", "ggplot2", "ggformula", "patchwork",
    "haven", "quarto"
  )
)

# ---- source custom functions --------------------------------------------
# Source whole folders so new domain files are picked up automatically.
purrr::walk(
  fs::dir_ls("R", recurse = TRUE, glob = "*.R"),
  tar_source
)

# ---- pipeline ------------------------------------------------------------
list(

  # --- config -------------------------------------------------------------
  # file-tracked so edits to the yaml invalidate downstream targets
  tar_target(cfg_file, "config/cfg.yml", format = "file"),
  tar_target(cfg,      yaml::read_yaml(cfg_file)),

  # --- Stage 1: raw import --------------------------------------------------
  # cfg$mode switches: sham -> anonymised rds; true -> the per-period .dta files.
  # raw_file tracks the input on disk so a new export invalidates downstream.
  # It depends on the cfg target, so a change of cfg$mode / cfg$export /
  # cfg$raw_files re-points it (before 2026-10-14 it read cfg.yml inside the
  # command and kept tracking the 20260911 copy after the switch to 20261001;
  # make_raw_norwel() itself always read cfg$export).
  tar_target(raw_file,
             if (identical(cfg$mode, "true")) {
               unlist(cfg$raw_files)
             } else {
               file.path("data/raw", paste0(cfg$export, "_anon"),
                         paste0(cfg$export, "_anon.rds"))
             },
             format = "file"),
  tar_target(raw, make_raw_norwel(cfg, raw_file)),

  # hospitals: randomised cluster, strata, annual births and the crossover
  # schedule (followed as planned, PI 1)
  tar_target(hosp_file, cfg$hospitals_file,
             format = "file"),
  tar_target(hospitals, readr::read_csv(hosp_file, comment = "#",
                                        show_col_types = FALSE)),

  # codelists: English labels for the coded category values (PI 13)
  tar_target(codelist_file, cfg$codelists_file,
             format = "file"),
  tar_target(codelists, readr::read_csv(codelist_file, comment = "#",
                                        show_col_types = FALSE)),

  # lookups: continent (item 58), birthweight standard (64), SDM items (65(d))
  tar_target(continent_file, cfg$continent_file,
             format = "file"),
  tar_target(bwref_file, cfg$bwref_file, format = "file"),
  tar_target(sdm_file, cfg$sdm_items_file, format = "file"),
  tar_target(lookups, list(
    continent = readr::read_csv(continent_file, comment = "#", show_col_types = FALSE),
    bwref     = readr::read_csv(bwref_file, comment = "#", show_col_types = FALSE),
    sdm       = readr::read_csv(sdm_file, comment = "#", show_col_types = FALSE,
                                col_types = readr::cols(.default = "c"))
  )),

  # --- Stage 0 (SAFE env only): anonymise for development -----------------
  # The database ships one raw .dta file per study period (intervention,
  # transition, control) — cfg$raw_files, keyed by the period label.
  # read_norwel_raw() aligns them by label, adds the TRUE `treatment`, and
  # combines; make_anon() then writes the anonymised copy to data/raw/<stem>_anon/
  # (treatment permuted, dates shifted within the trial window). The per-row
  # offsets go to data/raw/anon_keys/ and must NOT be exported to development.
  # tar_target(raw_dta,    unlist(cfg$raw_files), format = "file"),
  # tar_target(raw,        read_norwel_raw(raw_dta, cfg = cfg)),   # TRUE period
  # tar_target(anonymised, make_anon(raw_dta, cfg)),               # random period

  # --- ADaM (no SDTM stage: raw is one row per participant) ---------------
  tar_target(adsl, make_adsl(raw, hospitals, codelists, cfg, lookups)),
  tar_target(adeff, make_adeff(raw, adsl, codelists, cfg, lookups)),
  tar_target(adlp, make_adlp(raw, adsl, cfg)),

  # --- reporting datasets -------------------------------------------------
  tar_target(rdeff, make_rdeff(adeff, cfg)),
  tar_target(rdmi,  make_rdmi(adeff, cfg)),
  tar_target(rdsub, make_rdsub(adeff, cfg)),     # Robson subgroup (SAP 8.2)
  # labour-curve model: imputation of the time of reaching 4 cm (SAP 5.1.1.5)
  # (make_rdtear.R, the ordinal tear analysis, is not used from SAP v0.9)
  tar_target(lcfit, fit_lc(adlp, adsl, cfg)),
  tar_target(imp0,  impute_t0(lcfit, adlp, cfg)),
  tar_target(rdtte, make_rdtte(imp0, adeff, cfg)),
  tar_target(rddsc, make_rddsc(adsl, adeff, adlp, cfg)),

  # --- report -------------------------------------------------------------
  # manual wiring instead of tar_quarto: the installed quarto CLI (1.3) gives
  # tarchetypes' `quarto inspect` dependency detection nothing, so the report
  # target names its upstream targets explicitly.
  tar_target(report_src, "reports/statistical_analysis.qmd", format = "file"),
  tar_target(report, {
    list(cfg, adsl, rdeff, rdmi, rdsub, rdtte, rddsc)  # explicit dependencies
    quarto::quarto_render(report_src)
    sub("[.]qmd$", ".html", report_src)
  }, format = "file"),

  NULL
)
