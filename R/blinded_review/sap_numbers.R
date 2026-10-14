# sap_numbers.R — the pooled, blinded numbers quoted in the SAP, recomputed from
# an export, so the signed SAP can be checked against the final data (review
# item 52). Aggregate counts only, pooled over the study periods except the
# period sizes; no treatment comparison, no record keys.
#
#   Safe environment (final export):   Rscript R/blinded_review/sap_numbers.R
#   Development (anonymised copy):     Rscript R/blinded_review/sap_numbers.R --anon
#
# Writes outputs/sap_numbers.csv (outputs/sap_numbers_anon.csv with --anon). On
# the anonymised copy single-variable counts are exact (marginals preserved);
# counts combining variables from different permutation blocks are approximate.

sapnum_compute <- function(adsl, adeff, adlp) {
  pct <- function(x, n) sprintf("%s (%.1f%%)", format(x, big.mark = ","), 100 * x / n)
  row <- function(section, quantity, value) {
    tibble::tibble(sap_section = section, quantity = quantity, value = as.character(value))
  }
  p <- function(code) adeff[adeff$PARAMCD == code, ]
  n <- nrow(adsl)
  cs <- adsl$ICSFL == "Y"
  vd <- adsl$MODE %in% c("SVD", "IVD")
  vds <- adsl$VDSFL %in% "Y"
  tw <- adsl$TWINFL == "Y"

  imputed_no <- function(code) sum(p(code)$DTYPE == "IMPUTED")

  # time zero: examinations at 4 cm among vaginal deliveries
  ex <- adlp[adlp$ANL01FL == "Y" & adlp$USUBJID %in% adsl$USUBJID[vd & adsl$PASFL == "Y"], ]
  w4 <- unique(ex$USUBJID[ex$CMN == 4])
  wlo <- unique(ex$USUBJID[ex$CMN < 4])
  nvd <- sum(vd & adsl$PASFL == "Y")
  t4 <- tapply(ex$AVAL[ex$CMN == 4], ex$USUBJID[ex$CMN == 4], min)

  pha <- p("PHA")$AVAL
  phv <- p("PHV")$AVAL
  ga <- adsl$GADAYS

  dplyr::bind_rows(
    row("1.2, 3, 4.1.2", "women (FAS)", format(n, big.mark = ",")),
    row("3", "control / transition / LCG period (form)",
        paste(table(factor(adsl$FORMPER, c("control", "transition", "intervention"))),
              collapse = " / ")),
    row("4.1.2", "mode of delivery missing", sum(is.na(adsl$MODEN))),
    row("PI 10", "intrapartum CS, pooled", pct(sum(cs), n)),
    row("1.2", "CS at 3 cm (retracted cervix)", sum(cs & adsl$CXCSN %in% 3)),
    row("4.1.2", "CS at 4 cm", sum(cs & adsl$CXCSN %in% 4)),
    row("4.1.2", "CS without cervical dilatation", sum(cs & is.na(adsl$CXCSN))),
    row("4.1.1", "twin deliveries", sum(tw)),
    row("4.1.1", "twin 2 mode of delivery missing", sum(tw & is.na(adsl$MODE2N))),
    row("5.1.1.1", "amniotomy / oxytocin / epidural: status imputed no",
        paste(imputed_no("AMNIO"), imputed_no("OXY"), imputed_no("EDA"), sep = " / ")),
    row("5.1.1.1", "episiotomy: status imputed no", imputed_no("EPIS")),
    row("5.1.1.1", "OASIS missing (vaginal delivery set; no tear status or no grade)",
        pct(sum(is.na(p("OASIS")$AVAL[p("OASIS")$USUBJID %in% adsl$USUBJID[vds]])), sum(vds))),
    row("5.1.1.1", "estimated blood loss missing", pct(sum(is.na(p("PPHCAT")$AVAL)), n)),
    row("5.1.1.2", "Apgar at 5 min missing (first baby)", sum(is.na(p("APGAR5")$AVAL))),
    row("5.1.1.4", "arterial cord pH missing (first baby)", pct(sum(is.na(pha)), n)),
    row("5.1.1.4", "venous pH only / no cord gas (first baby)",
        paste(sum(is.na(pha) & !is.na(phv)), sum(is.na(pha) & is.na(phv)), sep = " / ")),
    row("5.1.1.5", "vaginal deliveries (PAS) without an examination at 4 cm",
        pct(nvd - length(w4), nvd)),
    row("5.1.1.5", "vaginal deliveries (PAS) without an examination below 4 cm",
        pct(nvd - length(wlo), nvd)),
    row("5.1.1.5", "4 cm examination -> delivery > 24 h / > 36 h",
        sprintf("%.1f%% / %.1f%%", 100 * mean(t4 > 24), 100 * mean(t4 > 36))),
    row("5.1.1.5", "4 cm examination -> delivery: mean of min(T, 36 h)",
        sprintf("%.1f h", mean(pmin(t4, 36)))),
    row("12.2", "births before 37+0 weeks", pct(sum(ga < 259, na.rm = TRUE), n))
  )
}

if (sys.nframe() == 0L) {
  stopifnot("run from the project root" = file.exists("config/cfg.yml"))
  suppressMessages(library(dplyr))
  for (f in c("R/external/functions.R", "R/make_raw/make_raw_norwel.R",
              "R/make_raw/read_norwel_raw.R", "R/helpers/codelists.R",
              "R/make_ad/make_adsl.R", "R/make_ad/make_adeff.R", "R/make_ad/make_adlp.R")) {
    source(f)
  }
  anon <- "--anon" %in% commandArgs(trailingOnly = TRUE)
  cfg <- yaml::read_yaml("config/cfg.yml")
  # ADaM written to a temporary folder, never over data/ad
  tmp <- tempfile("sapnum")
  path_adam <- function(...) fs::path(tmp, ...)
  raw <- make_raw_norwel(utils::modifyList(cfg, list(mode = if (anon) "sham" else "true")))
  hospitals <- readr::read_csv(cfg$hospitals_file, comment = "#", show_col_types = FALSE)
  codelists <- readr::read_csv(cfg$codelists_file, comment = "#", show_col_types = FALSE)
  adsl  <- suppressWarnings(make_adsl(raw, hospitals, codelists, cfg))
  adeff <- suppressWarnings(make_adeff(raw, adsl, codelists, cfg))
  adlp  <- make_adlp(raw, adsl, cfg)
  res <- sapnum_compute(adsl, adeff, adlp)
  fs::dir_create("outputs")
  out <- file.path("outputs", if (anon) "sap_numbers_anon.csv" else "sap_numbers.csv")
  readr::write_csv(res, out)
  print(as.data.frame(res), right = FALSE, row.names = FALSE)
  cat("\nwritten to", out, if (anon) "(ANONYMISED COPY)" else "", "\n")
}
