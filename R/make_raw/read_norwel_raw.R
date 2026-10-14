# read_norwel_raw.R — import the NorWel Stata (.dta) raw files (one per study
# period), harmonise their variables, and combine into a single labelled table
# with a `treatment` column carrying the TRUE period/allocation.
#
# The database stores each study period in a SEPARATE .dta file:
#   * intervention — LCG period,
#   * transition   — the 5-week teaching/roll-in step before each cluster's LCG
#                    period (protocol §4); received 2026-09-09. Its structure is
#                    IDENTICAL to the control file (statistician): it carries the
#                    control-only variables and lacks the intervention-only ones.
#   * control      — WHO partograph period.
# The files are largely identical, but:
#   * Stata truncates names to 32 chars and renames dotted/duplicate items to
#     v8, v9, v64, ... positionally, so the files must be aligned by variable
#     LABEL, not by column name — a naive row-bind would misalign the checkbox
#     groups. Alignment key per column = its label when meaningful, else name.
#   * a few variables are arm-specific: the intervention file carries the
#     shared-decision `samvalg_*` battery, the `stotteperson.*` support-person
#     group and the LCG alert-line timings `tidsintervall_LCG_*`; the control
#     (and hence transition) files carry the standard-care timings
#     `tiltakslinjen_krysset_forste_stadium` /
#     `avdelingens_tidsgrenser_overskredet_andre_stadium` and an extra
#     `jordmor_kontinuerlig_tilstede_cm.4_5cm` band. These become NA in the
#     period(s) that lack them.
#   * one cosmetic label difference (`Induksjonsmetode.` vs `Induksjonsmetoder.`)
#     is unified via `harmonize` in config/anon.yml.
#
# Each column is renamed to a sanitised (lower-snake) key; the canonical LABEL is
# kept as the `label` attribute so the anonymiser's label-based token matching in
# config/anon.yml keeps working. This is the TRUE-data path (safe environment);
# make_anon() then produces the anonymised copy (and permutes `treatment`).
#
# `treatment` takes the NAMES of `files` as its values, i.e. one level per study
# period — "intervention" / "transition" / "control". How the transition rows
# enter the analysis is an OPEN SAP item (docs/sap/sap_data_review.md items
# 21-22); the raw layer deliberately keeps the period as its own level rather
# than folding it into an arm, so any of the candidate handlings stays derivable.

# `%||%` guard (base R >= 4.4 provides it; rlang otherwise)
if (!exists("%||%")) `%||%` <- function(x, y) if (is.null(x)) y else x

# sanitise a label/name to a syntactically clean lower-snake column name
.sanitise_name <- function(x) {
  x <- gsub("[^A-Za-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  tolower(x)
}

# unique, valid Stata column names (<= 32 chars) from canonical keys
.stata_unique_names <- function(keys) {
  nm <- substr(.sanitise_name(keys), 1, 32)
  if (anyDuplicated(nm)) nm <- substr(make.unique(substr(nm, 1, 28), sep = "_"), 1, 32)
  nm
}

# per-column alignment key = label (if meaningful) else name; apply harmonise
.canon_keys <- function(df, harmonize = list()) {
  keys <- vapply(seq_along(df), function(j) {
    l <- attr(df[[j]], "label", exact = TRUE)
    if (is.null(l) || length(l) != 1 || is.na(l) || l == "" || l == "(unlabeled)")
      names(df)[j] else as.character(l)
  }, character(1))
  # harmonise on the part before the first "." (remaps a whole checkbox family)
  for (canon in names(harmonize)) {
    variants <- as.character(unlist(harmonize[[canon]]))
    before   <- sub("\\..*$", "", keys)
    hit      <- before %in% variants
    if (any(hit)) {
      keys[hit] <- vapply(keys[hit], function(k) {
        dp <- regexpr("\\.", k)
        if (dp > 0) paste0(canon, substring(k, dp)) else canon
      }, character(1))
    }
  }
  keys
}

# read one .dta, align/rename by canonical key, keep canonical label, tag period
.read_one_file <- function(path, period, treatment_var, harmonize) {
  d    <- tibble::as_tibble(haven::read_dta(path))
  keys <- .canon_keys(d, harmonize)
  nm   <- .stata_unique_names(keys)
  names(d) <- nm
  for (j in seq_along(d)) attr(d[[j]], "label") <- keys[j]
  d[[treatment_var]] <- period
  list(d = d, labs = stats::setNames(keys, nm))
}

# files : NAMED character vector of .dta paths; the names become the `treatment`
#         values, e.g. c(intervention = "...", transition = "...",
#         control = "..."). An unnamed length-2 vector is read as the legacy
#         (intervention, control) pair. The legacy two-positional-argument form
#         read_norwel_raw(file_int, file_ctr, cfg, acfg) is still accepted.
read_norwel_raw <- function(files, file_ctr = NULL, cfg = NULL, acfg = NULL,
                            treatment_var = "treatment") {
  # legacy form: read_norwel_raw(<intervention>, <control>, ...)
  if (!is.null(file_ctr)) {
    stopifnot(is.character(files), length(files) == 1L,
              is.character(file_ctr), length(file_ctr) == 1L)
    files <- c(intervention = files, control = file_ctr)
  }
  files <- unlist(files)
  stopifnot(is.character(files), length(files) >= 1L)
  if (is.null(names(files)) || !all(nzchar(names(files)))) {
    if (length(files) == 2L) {
      names(files) <- c("intervention", "control")   # documented legacy order
      message("read_norwel_raw: unnamed 2-file input read as ",
              "(intervention, control).")
    } else {
      stop("read_norwel_raw: `files` must be a NAMED character vector — the ",
           "names become the `treatment` values, e.g. c(intervention = ..., ",
           "transition = ..., control = ...).")
    }
  }

  if (is.null(acfg)) acfg <- yaml::read_yaml(here::here("config", "anon.yml"))$anon
  harmonize <- acfg$harmonize %||% list()

  parts <- lapply(seq_along(files), function(i)
    .read_one_file(files[[i]], names(files)[i], treatment_var, harmonize))
  names(parts) <- names(files)

  # Report rows and the label-level differences so misalignment is visible,
  # never silent. `absent` = variables in the union that this file lacks; check
  # it against the expected pattern at database lock (with transition ~ control:
  # 53 absent from transition and control, 3 absent from intervention).
  labs   <- lapply(parts, `[[`, "labs")
  shared <- Reduce(intersect, labs)
  allv   <- unique(unlist(labs, use.names = FALSE))
  message(paste0(
    sprintf("read_norwel_raw: %d files; %d distinct variables, %d shared by all.",
            length(files), length(allv), length(shared)),
    paste0("\n  ", sprintf("%-13s n=%6d, %4d vars, %3d absent",
                           names(parts),
                           vapply(parts, function(p) nrow(p$d), integer(1)),
                           lengths(labs),
                           length(allv) - lengths(labs)),
           collapse = "")
  ))

  # union of columns; period-specific columns fill with NA in the others
  combined <- dplyr::bind_rows(lapply(parts, `[[`, "d"))

  # re-apply canonical labels (bind_rows drops attributes)
  labmap <- do.call(c, unname(labs))
  labmap <- labmap[!duplicated(names(labmap))]
  for (col in names(combined))
    if (!is.na(labmap[col])) attr(combined[[col]], "label") <- unname(labmap[col])
  attr(combined[[treatment_var]], "label") <-
    "Study period / treatment arm (TRUE allocation)"

  combined
}
