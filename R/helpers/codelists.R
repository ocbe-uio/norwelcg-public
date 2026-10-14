# codelists.R — English labels for the coded (Norwegian) category values of the
# export. The table is metadata/codelists.csv (one row per variable x code),
# read as a tracked pipeline input and applied when the ADaM datasets are built,
# so every downstream table and figure is in English. The translations are to be
# validated by the investigators (questions_PI_DM.md, PI 13).

# Translate a coded vector. `variable` names the codelist: the base variable
# name (a tv2_ prefix is stripped, twin 2 shares the first baby's codelist) or
# one of the shared lists (samvalg_agreement, stotteperson_column,
# fosterovervaking_column, royk_snus). Empty strings become NA; codes that are
# not in the list are kept as they are and warned about once, so a new category
# in a later export is visible instead of silently dropped.
decode_cat <- function(x, variable, codelists, warn = TRUE) {
  x <- as.character(x)
  x[x == ""] <- NA_character_
  cl <- codelists[codelists$variable == sub("^tv2_", "", variable), ]
  if (nrow(cl) == 0) {
    if (warn) warning("no codelist for '", variable, "'", call. = FALSE)
    return(x)
  }
  out <- cl$label_en[match(x, cl$code)]
  unknown <- !is.na(x) & is.na(out)
  if (any(unknown)) {
    if (warn) {
      warning("codelist '", sub("^tv2_", "", variable), "': no label for ",
              paste(sort(unique(x[unknown])), collapse = ", "), call. = FALSE)
    }
    out[unknown] <- x[unknown]
  }
  out
}
