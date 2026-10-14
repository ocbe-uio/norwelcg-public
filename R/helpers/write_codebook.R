# write_codebook.R — a codebook of the export, generated in development from the
# anonymised copy (review item 51). The anonymiser preserves every variable's
# marginal distribution, so the counts equal those of the real export; only
# the timestamps (shifted), the record key (synthetic) and dropped columns
# differ. Free-text fields are summarised by counts only, never by value.
#
#   Rscript R/helpers/write_codebook.R      -> metadata/codebook_<export>.txt

codebook_entry <- function(x, name, label, max_levels = 200) {
  nm <- sum(is.na(x) | (is.character(x) & x %in% ""))
  head <- c(strrep("-", 79), name, if (!is.null(label) && label != name) paste0("  label: ", label),
            sprintf("  missing: %d of %d", nm, length(x)))
  v <- x[!(is.na(x) | (is.character(x) & x %in% ""))]
  if (inherits(x, c("POSIXt", "Date")) ||
      (is.character(x) && mean(grepl("^\\d{4}-\\d{2}-\\d{2}", v)) > 0.9 && length(v))) {
    return(c(head, "  type: date-time (shifted by a random whole-day offset in the anonymised copy)"))
  }
  if (name == "nokkel") return(c(head, "  type: record key (synthetic in the anonymised copy)"))
  if (is.numeric(x) && length(unique(v)) > 15) {
    q <- stats::quantile(v, c(0, 0.5, 1), names = FALSE)
    return(c(head, sprintf("  type: numeric; min %s, median %s, max %s",
                           format(q[1]), format(q[2]), format(q[3]))))
  }
  tab <- sort(table(v), decreasing = TRUE)
  if (is.character(x) && length(tab) > max_levels) {
    return(c(head, sprintf("  type: free text (%d distinct values; not listed)", length(tab))))
  }
  tab <- table(v)
  c(head, sprintf("  type: %s; values:", if (is.numeric(x)) "numeric (coded)" else "text (coded)"),
    sprintf("    %8d  %s", as.integer(tab), names(tab)))
}

write_codebook <- function(raw, path) {
  out <- unlist(lapply(names(raw), function(v) {
    codebook_entry(raw[[v]], v, attr(raw[[v]], "label", exact = TRUE))
  }))
  writeLines(c(sprintf("Codebook generated %s from the anonymised export (%d rows, %d variables).",
                       format(Sys.Date()), nrow(raw), ncol(raw)),
               "Counts equal the real export (marginals preserved); timestamps shifted, key synthetic.",
               out), path)
  invisible(path)
}

if (sys.nframe() == 0L) {
  stopifnot("run from the project root" = file.exists("config/cfg.yml"))
  source("R/external/functions.R"); source("R/make_raw/make_raw_norwel.R")
  cfg <- yaml::read_yaml("config/cfg.yml")
  raw <- make_raw_norwel(utils::modifyList(cfg, list(mode = "sham")))
  p <- write_codebook(raw, file.path("metadata", paste0("codebook_", cfg$export, ".txt")))
  cat("written to", p, "\n")
}
