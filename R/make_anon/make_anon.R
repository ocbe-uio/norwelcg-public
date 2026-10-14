# make_anon.R — produce an anonymised copy of the NorWel raw data for code
# development in an LLM-accessible environment.
#
# The NorWel raw data arrives as one flat Stata (.dta) table per study period
# (intervention / transition / control), one row per participant; they are
# label-aligned and combined by read_norwel_raw() before anonymisation.
# "Anonymised" here means anonymised relative to the development environment
# (the recipient), per the contextual approach in CJEU C-413/23 P (EDPS v SRB,
# 4 Sep 2025): the recipient holds no re-identification keys and cannot
# reasonably re-identify. The data remain personal/pseudonymised for the
# controller, who retains the keys. See docs/data_anonymisation_specification.md.
#
# Method (config/anon.yml):
#   * drop    - record-metadata columns removed outright (`created`, paradata).
#   * synthetic ids - record keys (`synthetic_ids`, e.g. `nokkel`) removed
#               before permutation and rebuilt afterwards in the same format,
#               prefix from the permuted period label; no real key survives
#               and no map is kept.
#   * timing  - true timestamps kept as datetimes; every timestamp of a row is
#               shifted by ONE random whole-day offset drawn for that row, so
#               intervals / time-of-day / weekday are preserved and the true
#               calendar date is hidden. The offset is bounded so the shifted
#               anchor date (delivery; see anon.yml) stays within the trial
#               window (pooled over all study periods), which also hides which
#               period/arm a row is from. Every date-time column must be listed
#               in `timing` or `drop` — make_anon stops otherwise, so a new
#               timestamp in an export can never be permuted with its TRUE date.
#   * blocks  - every other column is permuted across rows (marginals kept,
#               individual linkage broken). Permutation is block-consistent:
#               the columns of a `group` move together (a gate travels with its
#               conditional children); `joint` groups share one order (e.g.
#               amniotomi + oxytocin, to keep their correlation). `treatment`
#               (the TRUE study period from read_norwel_raw: intervention /
#               transition / control) is a permuted singleton, so the anonymised
#               copy carries a RANDOM period label (period sizes preserved).
#
# CARDINAL RULES
#   * the per-row date offsets are the re-identification key: written ONLY to a
#     safe-only path (data/raw/anon_keys/) and NEVER exported to development.
#   * the anonymised copy carries a RANDOM period label (permuted `treatment`),
#     so no separate sham-randomisation step is needed or run.
#   * only code travels dev -> safe; only anonymised data travels safe -> dev.
#
# USAGE (SAFE environment only), from the project root in a FRESH process:
#     Rscript R/make_anon/run_anon.R
#   (make_anon() + anon_verify + synthetic-key check). Interactively, re-source
#   this file first — an old session keeps old definitions while anon.yml is
#   re-read (deviation D-2) — then:
#     cfg  <- yaml::read_yaml("config/cfg.yml")
#     anon <- make_anon(unlist(cfg$raw_files), cfg)   # named paths, or a df

# ---- small utilities -----------------------------------------------------

# `%||%` guard (base R >= 4.4 provides it; rlang otherwise)
if (!exists("%||%")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}

# anonymisation code version: bump whenever the method changes. Written to
# <export>_anon/anon_manifest.csv by the code that actually ran, so the
# development side can confirm which version produced a copy (a stale R session
# keeps old function definitions while re-reading anon.yml — deviation D-2).
ANON_CODE_VERSION <- "2026-09-11.3"

# non-missing test that treats "" (Stata empty string) as missing
.is_present <- function(x) {
  x <- as.character(x)
  !(is.na(x) | x == "")
}

# name + variable-label dictionary for a data frame
.build_dict <- function(df) {
  tibble::tibble(
    name = names(df),
    label = vapply(
      df,
      function(x) {
        l <- attr(x, "label", exact = TRUE)
        if (is.null(l) || length(l) != 1 || is.na(l)) {
          NA_character_
        } else {
          as.character(l)
        }
      },
      character(1)
    )
  )
}

# resolve one config token to the actual column name(s) it matches.
#   "prefix.*"  -> label starts with prefix + "."   (checkbox multi-selects)
#   "prefix*"   -> name  starts with prefix         (e.g. "tv2_*")
#   "name"      -> exact match on name, label, or 32-char truncated name
.resolve_token <- function(token, dict) {
  if (grepl("\\.\\*$", token)) {
    pre <- sub("\\.\\*$", "", token)
    dict$name[!is.na(dict$label) & startsWith(dict$label, paste0(pre, "."))]
  } else if (grepl("\\*$", token)) {
    pre <- sub("\\*$", "", token)
    dict$name[startsWith(dict$name, pre)]
  } else {
    hit <- dict$name == token |
      (!is.na(dict$label) & dict$label == token) |
      dict$name == substr(token, 1, 32)
    dict$name[hit]
  }
}

.resolve_tokens <- function(tokens, dict) {
  unique(unlist(lapply(tokens, .resolve_token, dict = dict), use.names = FALSE))
}

# ---- timing: per-row whole-day shift -------------------------------------

# a timing column as POSIXct (UTC). Two source forms: ISO-local
# "YYYY-MM-DDTHH:MM" strings (the original str16 timestamps) and datetimes
# already typed by haven (Stata %tc/%td, e.g. the cleaned ny* columns).
.as_utc_time <- function(x) {
  if (inherits(x, c("POSIXt", "Date"))) {
    t <- as.POSIXct(x)
    attr(t, "tzone") <- "UTC"
    return(t)
  }
  as.POSIXct(as.character(x), format = "%Y-%m-%dT%H:%M", tz = "UTC")
}

# columns holding date-times: typed POSIXct/Date, or character columns with any
# ISO-like "YYYY-MM-DD[ HH:MM]" value (sentinel years such as 999 included).
.datetime_cols <- function(df) {
  iso <- "^[0-9]{1,4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}:[0-9]{2})?"
  hit <- vapply(
    df,
    function(x) {
      if (inherits(x, c("POSIXt", "Date"))) {
        return(TRUE)
      }
      is.character(x) && any(grepl(iso, x[.is_present(x)]))
    },
    logical(1)
  )
  names(df)[hit]
}

# one integer day offset per row, drawn so the shifted anchor stays within the
# trial window. The window comes from acfg$window (explicit [start, end] dates —
# recommended: the raw data contains sentinel/erroneous timestamps, e.g. year
# 999, which would wreck an observed min/max window); without it, the observed
# anchor range is used. Rows whose anchor is outside the window get a random
# target date drawn uniformly inside the window instead (their true date is
# garbage; parking them inside the window leaks nothing). Rows with no usable
# anchor get a random offset of up to one window length either way, so their
# other timestamps are still hidden (never left unshifted). cap
# (max_shift_days) optionally bounds the magnitude for in-window rows.
window_offsets <- function(anchor, window = NULL, cap = NULL) {
  t <- .as_utc_time(anchor)
  days <- floor(as.numeric(t) / 86400) # whole days since epoch
  if (!is.null(window)) {
    lo <- as.numeric(as.Date(window[[1]]))
    hi <- as.numeric(as.Date(window[[2]]))
  } else {
    inr <- days # no explicit window: use the observed range
    lo <- suppressWarnings(min(inr, na.rm = TRUE))
    hi <- suppressWarnings(max(inr, na.rm = TRUE))
  }
  if (!is.finite(lo) || !is.finite(hi)) {
    stop("window_offsets: no usable anchor date and no explicit window.")
  }
  in_win <- !is.na(days) & days >= lo & days <= hi

  off <- integer(length(days))

  # in-window rows: uniform whole-day offset keeping the anchor inside [lo, hi]
  lower <- ceiling(lo - days[in_win])
  upper <- floor(hi - days[in_win])
  if (!is.null(cap)) {
    lower <- pmax(lower, -abs(cap))
    upper <- pmin(upper, abs(cap))
  }
  span <- upper - lower
  off[in_win] <- lower + floor(stats::runif(sum(in_win)) * (span + 1))

  # out-of-window / unparseable-but-numeric rows: send to a random in-window day
  fix <- !in_win & !is.na(days)
  if (any(fix)) {
    target <- lo + floor(stats::runif(sum(fix)) * (hi - lo + 1))
    off[fix] <- target - days[fix]
  }

  # no usable anchor: random offset in [-(hi - lo), hi - lo]
  none <- is.na(days)
  if (any(none)) {
    w <- hi - lo
    off[none] <- -w + floor(stats::runif(sum(none)) * (2 * w + 1))
  }
  off
}

# shift a timing column by an integer number of days per row. Typed
# datetimes/dates are shifted directly (NA stays NA); ISO-local
# "YYYY-MM-DDTHH:MM" strings keep their HH:MM and empty/missing pattern.
# Whole-day shift => no DST issues, so parse/format in UTC.
shift_datetime <- function(x, offset_days) {
  if (inherits(x, c("POSIXt", "Date"))) {
    return(x + as.difftime(offset_days, units = "days"))
  }
  xc <- as.character(x)
  out <- xc
  ok <- .is_present(xc)
  if (any(ok)) {
    t <- as.POSIXct(xc[ok], format = "%Y-%m-%dT%H:%M", tz = "UTC")
    t2 <- t + as.difftime(offset_days[ok], units = "days")
    parsed <- format(t2, "%Y-%m-%dT%H:%M", tz = "UTC")
    # leave unparseable values (unexpected format) untouched
    bad <- is.na(t)
    parsed[bad] <- xc[ok][bad]
    out[ok] <- parsed
  }
  out
}

# ---- block partition -----------------------------------------------------

# turn the `groups` config into a list of blocks: each block is
# list(cols = <chr>, restrict = <col name or NA>). Applies `joint` (member
# groups merged into one shared-order block). Columns not claimed by any group
# and not timing become singleton blocks.
build_blocks <- function(df, acfg, timing_cols) {
  dict <- .build_dict(df)
  groups <- acfg$groups %||% list()

  # resolve each named group to columns (+ optional restrict_to)
  gcols <- list()
  grestrict <- list()
  for (nm in names(groups)) {
    g <- groups[[nm]]
    if (is.list(g) && !is.null(g$members)) {
      cols <- .resolve_tokens(g$members, dict)
      restrict <- g$restrict_to %||% NA_character_
    } else {
      cols <- .resolve_tokens(as.character(unlist(g)), dict)
      restrict <- NA_character_
    }
    cols <- setdiff(cols, timing_cols) # timing is shifted, never permuted
    if (length(cols)) {
      gcols[[nm]] <- cols
      grestrict[[nm]] <- restrict
    }
  }

  # merge joint sets into single shared-order blocks
  joint <- acfg$joint %||% list()
  merged <- character()
  blocks <- list()
  for (set in joint) {
    set <- intersect(as.character(set), names(gcols))
    if (length(set) < 2) {
      next
    }
    cols <- unique(unlist(gcols[set], use.names = FALSE))
    blocks[[length(blocks) + 1]] <- list(cols = cols, restrict = NA_character_)
    merged <- c(merged, set)
  }
  for (nm in setdiff(names(gcols), merged)) {
    blocks[[length(blocks) + 1]] <- list(
      cols = gcols[[nm]],
      restrict = grestrict[[nm]]
    )
  }

  # singletons: anything left that is neither timing nor already grouped
  claimed <- unique(unlist(lapply(blocks, `[[`, "cols"), use.names = FALSE))
  singletons <- setdiff(names(df), c(timing_cols, claimed))
  for (col in singletons) {
    blocks[[length(blocks) + 1]] <- list(cols = col, restrict = NA_character_)
  }

  blocks
}

# permute one block's columns with a single shared order. When `restrict` names
# a column, permute only among rows where that column is present (others keep
# their value — used to keep the twin-2 record among twin rows only).
permute_block <- function(df, block, n) {
  rows <- seq_len(n)
  if (!is.na(block$restrict) && block$restrict %in% names(df)) {
    rows <- which(.is_present(df[[block$restrict]]))
  }
  if (length(rows) < 2) {
    return(df)
  }
  ord <- rows[sample.int(length(rows))]
  for (col in block$cols) {
    v <- df[[col]]
    v[rows] <- v[ord]
    df[[col]] <- v
  }
  df
}

# ---- synthetic IDs -------------------------------------------------------

# a synthetic key in the real key's format, e.g. "CTR-00042": prefix from the
# already-permuted `from` column (so it agrees with the random period label),
# number = a random permutation of 1..n within each prefix, zero-padded to
# `width`. Nothing is derived from the real key and no map is kept.
synthetic_id <- function(df, id, spec) {
  from <- spec$from %||% "treatment"
  if (!from %in% names(df)) {
    stop(
      "make_anon: synthetic id '",
      id,
      "' needs column '",
      from,
      "'.",
      call. = FALSE
    )
  }
  map <- unlist(spec$prefix)
  grp <- as.character(df[[from]])
  miss <- setdiff(unique(grp), names(map))
  if (length(miss)) {
    stop(
      "make_anon: no `prefix` for ",
      from,
      " value(s): ",
      paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  num <- integer(length(grp))
  for (g in unique(grp)) {
    i <- which(grp == g)
    num[i] <- sample.int(length(i))
  }
  width <- spec$width %||% nchar(length(grp))
  paste0(map[grp], spec$sep %||% "-", formatC(num, width = width, flag = "0"))
}

# ---- driver --------------------------------------------------------------
# raw : one of
#   * a combined data.frame (e.g. from read_norwel_raw), with a `treatment`
#     column holding the TRUE study period — permuted here to a RANDOM period;
#   * a NAMED character vector of the per-period .dta paths, e.g.
#     c(intervention = ..., transition = ..., control = ...) or simply
#     unlist(cfg$raw_files) — read + harmonised + tagged via read_norwel_raw()
#     (an unnamed length-2 vector keeps the legacy intervention/control order);
#   * a single .dta path or data.frame (single-table case).
# cfg : cfg.yml list (used for the output stem / export name).
make_anon <- function(raw, cfg = NULL, acfg = NULL, out_stem = NULL) {
  if (is.null(acfg)) {
    acfg <- yaml::read_yaml(here::here("config", "anon.yml"))$anon
  }
  if (is.null(cfg)) {
    cfg <- yaml::read_yaml(here::here("config", "cfg.yml"))
  }

  df <-
    if (is.character(raw) && length(raw) >= 2) {
      read_norwel_raw(raw, cfg = cfg, acfg = acfg)
    } else if (is.data.frame(raw)) {
      raw
    } else {
      haven::read_dta(raw)
    }
  df <- tibble::as_tibble(df)
  n <- nrow(df)
  withr::local_seed(acfg$seed %||% 1L)

  # 0. remember variable labels to re-apply at the end (subsetting drops them)
  labels0 <- setNames(
    lapply(df, function(x) attr(x, "label", exact = TRUE)),
    names(df)
  )

  # 1. drop record-metadata columns. Synthetic-ID columns (e.g. `nokkel`) are
  #    removed too and rebuilt after the permutation (step 5b), so no real key
  #    value survives in the copy.
  sids <- acfg$synthetic_ids %||% list()
  df <- df[,
    setdiff(names(df), c(acfg$drop %||% character(), names(sids))),
    drop = FALSE
  ]

  dict <- .build_dict(df)
  timing_cols <- intersect(
    .resolve_tokens(acfg$timing %||% character(), dict),
    names(df)
  )

  # 1b. every date-time column must be shifted or dropped: one left out of
  #     `timing` would be permuted with its TRUE calendar value (the ny* columns
  #     of the 20260909 export). Stop before anything is written.
  unshifted <- setdiff(.datetime_cols(df), timing_cols)
  if (length(unshifted)) {
    stop(
      "make_anon: date-time column(s) not listed in anon.yml `timing` or ",
      "`drop`: ",
      paste(unshifted, collapse = ", "),
      call. = FALSE
    )
  }

  # 2. per-row whole-day offset (the re-identification key), bounded so every
  #    shifted anchor date stays within the trial window. `anchor` may list
  #    several columns in priority order; the first present value is used.
  anchors <- as.character(unlist(acfg$anchor))
  if (!length(anchors) || !all(anchors %in% names(df))) {
    stop(
      "make_anon: anchor column(s) '",
      paste(setdiff(anchors, names(df)), collapse = "', '"),
      "' not found for the date shift."
    )
  }
  anchor_t <- Reduce(
    function(a, b) {
      a[is.na(a)] <- b[is.na(a)]
      a
    },
    lapply(anchors, function(col) .as_utc_time(df[[col]]))
  )
  offset <- window_offsets(
    anchor_t,
    window = acfg$window,
    cap = acfg$max_shift_days
  )

  # 3. shift all timing columns by the row offset (row-fixed; intervals kept)
  for (col in timing_cols) {
    df[[col]] <- shift_datetime(df[[col]], offset)
  }

  # 4. block-consistent permutation of everything else
  blocks <- build_blocks(df, acfg, timing_cols)
  for (b in blocks) {
    df <- permute_block(df, b, n)
  }

  # 5. reconcile gated timing columns with their (now permuted) gate: blank the
  #    timestamp where the gate is 0/missing so the two never contradict.
  for (tv in names(acfg$timing_gates %||% list())) {
    gate <- acfg$timing_gates[[tv]]
    if (tv %in% names(df) && gate %in% names(df)) {
      g <- df[[gate]]
      bad <- is.na(g) | g %in% c(0, "0") | (is.character(g) & g == "")
      df[[tv]][bad] <- if (is.character(df[[tv]])) "" else NA
    }
  }

  # 5b. rebuild synthetic IDs from the permuted period label (front of table)
  for (id in names(sids)) {
    df[[id]] <- synthetic_id(df, id, sids[[id]])
    df <- df[, c(id, setdiff(names(df), id)), drop = FALSE]
  }

  # 6. re-apply variable labels for surviving columns
  for (col in names(df)) {
    if (!is.null(labels0[[col]])) attr(df[[col]], "label") <- labels0[[col]]
  }

  # ---- write outputs -----------------------------------------------------
  stem <- out_stem %||%
    (if (
      !is.null(cfg$export) &&
        nzchar(cfg$export) &&
        cfg$export != "_YYYYMMDD_HHMMSS"
    ) {
      cfg$export
    } else {
      "norwel"
    })

  # re-identification key -> SAFE-ONLY path (data/raw/ is git-ignored; NEVER export)
  safe_dir <- path_raw("anon_keys")
  fs::dir_create(safe_dir)
  readr::write_csv(
    tibble::tibble(row = seq_len(n), offset_days = offset),
    fs::path(safe_dir, "offset_map.csv")
  )

  # anonymised copy -> movable directory
  out_dir <- path_raw(paste0(stem, "_anon"))
  fs::dir_create(out_dir)
  haven::write_dta(df, fs::path(out_dir, paste0(stem, "_anon.dta")))
  readr::write_rds(df, fs::path(out_dir, paste0(stem, "_anon.rds")))
  readr::write_csv(
    tibble::tibble(
      anon_code_version = ANON_CODE_VERSION,
      config_hash = rlang::hash(acfg),
      created = format(Sys.time(), "%Y-%m-%d %H:%M"),
      n_rows = n,
      synthetic_ids = paste(names(sids), collapse = ";")
    ),
    fs::path(out_dir, "anon_manifest.csv")
  )

  if (isTRUE(acfg$risk_readout)) {
    try(anon_risk_readout(df, acfg, out_dir), silent = TRUE)
  }

  # Say where the files went. path_raw() resolves against here::here(), which in
  # the safe environment may not be the directory you think it is (no .git /
  # .Rproj marker, or a marker in a parent), so report ABSOLUTE paths.
  periods <- if ("treatment" %in% names(df)) {
    tb <- table(as.character(df$treatment), useNA = "ifany")
    paste(sprintf("%s=%d", names(tb), as.integer(tb)), collapse = ", ")
  } else {
    "no `treatment` column"
  }
  message(sprintf(
    paste0(
      "make_anon (code %s): %d rows written (%s).\n",
      "  anonymised copy  -> %s\n",
      "  re-id key (SAFE) -> %s   [NEVER export this]"
    ),
    ANON_CODE_VERSION,
    n,
    periods,
    fs::path_abs(out_dir),
    fs::path_abs(fs::path(safe_dir, "offset_map.csv"))
  ))

  df
}

############################
# To run the test files on safe environment:
# library(haven); library(dplyr); library(tibble)
# library(readr); library(fs); library(withr); library(here)
# source("R/make_raw/read_norwel_raw.R")
# source("R/external/functions.R")
# source("R/make_anon/anon_checks.R")
# cfg  <- yaml::read_yaml("config/cfg.yml")

# anon <- make_anon(
#  c(intervention = "data/raw/test_intervention.dta",
#    transition   = "data/raw/test_transition.dta",
#    control      = "data/raw/test_control.dta"),  # names -> `treatment` values
#  cfg
# )   # or simply: make_anon(unlist(cfg$raw_files), cfg)

# # 6. Optional verification before moving it:

# raw <- read_norwel_raw(unlist(cfg$raw_files), cfg = cfg)
# acfg <- yaml::read_yaml("config/anon.yml")$anon
# anon_verify(raw, anon, timing_cols = acfg$timing,
#             synthetic_cols = names(acfg$synthetic_ids))
# expect: same_nrow = TRUE, marginals_ok = TRUE
