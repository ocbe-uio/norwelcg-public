# run_anon.R — run the anonymiser in a FRESH R process (SAFE environment only).
#
#   From the project root:   Rscript R/make_anon/run_anon.R
#
# A fresh process guarantees the current code is used. Re-running make_anon()
# in an existing session keeps the function definitions sourced earlier while
# anon.yml is re-read at call time — the cause of deviation D-2 (real record
# keys permuted into the copy because the old code ignored `synthetic_ids`).
#
# Writes data/raw/<export>_anon/ (movable, incl. anon_manifest.csv) and
# data/raw/anon_keys/offset_map.csv (NEVER export), then verifies the copy.
#
# The body runs only when executed as a script: targets' tar_source() sources
# every file under R/, and without this guard each tar_make() would re-run the
# anonymiser (and rewrite the key file) as a side effect.

if (sys.nframe() == 0L) {
  stopifnot(
    "run from the project root" = file.exists("config/anon.yml")
  )

  source("R/external/functions.R") # path_raw()
  source("R/make_raw/read_norwel_raw.R")
  source("R/make_anon/anon_checks.R")
  source("R/make_anon/make_anon.R")

  cfg <- yaml::read_yaml("config/cfg.yml")
  acfg <- yaml::read_yaml("config/anon.yml")$anon

  raw <- read_norwel_raw(unlist(cfg$raw_files), cfg = cfg, acfg = acfg)
  anon <- make_anon(raw, cfg = cfg, acfg = acfg)

  # 1. schema + marginals (expect same_nrow = TRUE, marginals_ok = TRUE)
  print(anon_verify(
    raw,
    anon,
    timing_cols = acfg$timing,
    synthetic_cols = names(acfg$synthetic_ids)
  ))

  # 2. synthetic keys: prefix must equal the (permuted) period on every row and
  #    no row may keep its real key. Stop — do NOT move the copy — otherwise.
  for (id in names(acfg$synthetic_ids)) {
    s <- acfg$synthetic_ids[[id]]
    pre <- unlist(s$prefix)[as.character(anon[[s$from %||% "treatment"]])]
    ok_prefix <- all(startsWith(anon[[id]], paste0(pre, s$sep %||% "-")))
    ok_new <- !(id %in% names(raw)) || mean(anon[[id]] == raw[[id]]) < 0.01
    if (!ok_prefix || !ok_new) {
      stop(
        "synthetic id '", id, "' failed its check — do NOT transfer this copy.",
        call. = FALSE
      )
    }
  }

  message(
    "run_anon: code ", ANON_CODE_VERSION,
    " — checks passed. Transfer ONLY data/raw/", cfg$export, "_anon/."
  )
}
