# anon_checks.R — optional verification + re-identification risk readout for the
# flat-file anonymiser (see make_anon.R).
#
# Pragmatic (per agreed plan): reported, not gated on a formal threshold.
#   - k-anonymity readout: worst-case equivalence-class size over a set of
#     quasi-identifier columns (via sdcMicro if installed, else base R).
#   - marginal check: a permuted column reuses exactly the same values, so its
#     marginal (including missingness) is preserved by construction; anon_verify
#     confirms columns, row count and per-column value multisets are unchanged.

# `%||%` guard (base R >= 4.4 provides it; rlang otherwise)
if (!exists("%||%")) `%||%` <- function(x, y) if (is.null(x)) y else x

# default quasi-identifiers for the NorWel table: the demographic / birth
# attributes most likely to co-identify. Override via acfg$qi_vars.
.default_qi <- c(
  "fodested", "alder", "landbakgrunn", "sivilstatus", "utdanning", "paritet",
  "robson_gruppe", "gestasjonsalder_ved_fodsel_hele_uker", "barnets_kjonn",
  "fodselsvekt_gram"
)

# worst-case k for a set of quasi-identifier columns
worst_case_k <- function(df, qi_cols) {
  qi_cols <- intersect(qi_cols, names(df))
  if (length(qi_cols) == 0 || nrow(df) == 0) return(NA_integer_)
  counts <- df |>
    dplyr::count(dplyr::across(dplyr::all_of(qi_cols)), name = ".k")
  min(counts$.k, na.rm = TRUE)
}

anon_risk_readout <- function(df, acfg, out_dir) {
  qi <- intersect(acfg$qi_vars %||% .default_qi, names(df))

  k_base <- worst_case_k(df, qi)

  k_sdc <- NA_real_
  if (requireNamespace("sdcMicro", quietly = TRUE) && length(qi) > 0) {
    k_sdc <- tryCatch({
      sdc <- sdcMicro::createSdcObj(dat = as.data.frame(df), keyVars = qi)
      sum(sdc@risk$individual[, "fk"] == 1, na.rm = TRUE)  # records unique on key
    }, error = function(e) NA_real_)
  } else {
    message("anon_risk_readout: sdcMicro not installed; base-R k only.")
  }

  readout <- tibble::tibble(
    n_rows          = nrow(df),
    n_quasi         = length(qi),
    quasi_ids       = paste(qi, collapse = ", "),
    worst_case_k    = k_base,
    n_unique_on_key = k_sdc
  )
  readr::write_csv(readout, fs::path(out_dir, "risk_readout.csv"))
  readout
}

# schema + marginal sanity check vs the source table: same columns, same row
# count, and — for every non-timing, non-synthetic column — the same multiset
# of values (a permutation reuses exactly the same values, so sorted values must
# match). Synthetic IDs (e.g. `nokkel`) differ from the source by design.
anon_verify <- function(raw, anon, timing_cols = character(),
                        synthetic_cols = character()) {
  if (!is.data.frame(raw)) raw <- haven::read_dta(raw)
  # config tokens -> actual columns, as make_anon resolves them (labels carry
  # the full names Stata truncated; needs make_anon.R's token helpers)
  skip <- .resolve_tokens(c(timing_cols, synthetic_cols), .build_dict(anon))
  common <- intersect(names(raw), names(anon))
  same_multiset <- vapply(common, function(col) {
    if (col %in% skip) return(NA)
    identical(sort(as.character(raw[[col]])), sort(as.character(anon[[col]])))
  }, logical(1))
  tibble::tibble(
    same_nrow      = nrow(raw) == nrow(anon),
    n_common_cols  = length(common),
    n_dropped      = length(setdiff(names(raw), names(anon))),
    marginals_ok   = all(same_multiset[!is.na(same_multiset)]),
    n_marg_checked = sum(!is.na(same_multiset))
  )
}
