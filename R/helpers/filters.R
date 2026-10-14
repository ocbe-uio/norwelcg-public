# filters.R — shared filtering helpers.

# Restrict a dataset to the analysis population using a CDISC ADaM population
# flag (default from config/cfg.yml: analysis$popfl, e.g. FASFL = Full Analysis
# Set). The flag column must be present (merged from ADSL). Keeps rows == "Y".
filter_pop <- function(data, cfg, flag = NULL) {
  flag <- flag %||% cfg$analysis$popfl %||% "FASFL"
  if (!flag %in% names(data)) {
    stop("Population flag '", flag, "' not found in data; merge it from ADSL.")
  }
  dplyr::filter(data, .data[[flag]] == "Y")
}
