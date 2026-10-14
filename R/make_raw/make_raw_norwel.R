# make_raw_norwel.R — single entry point for the NorWel raw data, switching on
# cfg$mode:
#
#   sham : read the anonymised copy data/raw/<export>_anon/<export>_anon.rds
#          (produced by make_anon in the safe environment; its `treatment`
#          column is already randomised — no separate sham-randomisation step).
#   true : read the per-period true .dta files listed in cfg$raw_files via
#          read_norwel_raw() (SAFE env only; `treatment` carries the true study
#          period: intervention / transition / control).
#
# Either way the columns are renamed to their full canonical names: the Stata
# files truncate names to 32 (28 + uniqueness suffix) chars, but every column's
# `label` attribute carries the full dotted name (e.g.
# "hvilke_kjente_pregravide_sykdommer.dia_type2"). We rename each column to the
# sanitised label (lower-snake, no length cap) so downstream ADaM code can use
# readable, stable names, and keep the original label as the label attribute.

# `files` is passed by the raw_file target purely so targets tracks the input
# on disk; the paths themselves are resolved from cfg either way.
make_raw_norwel <- function(cfg, files = NULL) {
  raw <- if (identical(cfg$mode, "true")) {
    read_norwel_raw(unlist(cfg$raw_files), cfg = cfg)
  } else {
    readr::read_rds(path_raw(paste0(cfg$export, "_anon"),
                             paste0(cfg$export, "_anon.rds")))
  }

  canon <- vapply(seq_along(raw), function(j) {
    l <- attr(raw[[j]], "label", exact = TRUE)
    ok <- !is.null(l) && length(l) == 1 && !is.na(l) && l != "" &&
      !grepl("[^A-Za-z0-9._]", l)   # variable-like token, not descriptive text
    if (ok) as.character(l) else names(raw)[j]
  }, character(1))

  nm <- gsub("[^A-Za-z0-9]+", "_", canon)
  nm <- tolower(gsub("^_|_$", "", gsub("_+", "_", nm)))
  nm <- make.unique(nm, sep = "_")
  names(raw) <- nm
  for (j in seq_along(raw)) attr(raw[[j]], "label") <- canon[j]

  raw
}
