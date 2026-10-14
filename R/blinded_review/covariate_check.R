# covariate_check.R — BLINDED check of the prognostic strength of the candidate
# covariates for intrapartum caesarean section (SAP §4.1.3). SAFE environment.
#
#   From the project root:   Rscript R/blinded_review/covariate_check.R
#
# Blinding: pooled over all study periods. The period label is dropped on
# reading, and no treatment, time interval or hospital term enters any model,
# so nothing about the treatment effect is revealed. Output is aggregate only
# (likelihood-ratio tests, c-statistics); no individual-level data.
#
# In the anonymised development copy every covariate is permuted independently
# of the outcome, so running covariate_check() there only tests the code — all
# associations are null by construction.

# restricted cubic spline, 3 knots at the 10th/50th/90th percentiles (a natural
# cubic spline with those knots; linear beyond the outer knots)
rcs3 <- function(x) {
  splines::ns(
    x,
    knots = stats::quantile(x, 0.5),
    Boundary.knots = stats::quantile(x, c(0.1, 0.9))
  )
}

# c-statistic (area under the ROC curve) via the Mann-Whitney statistic
cstat <- function(p, y) {
  r <- rank(p)
  n1 <- sum(y == 1)
  n0 <- sum(y == 0)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

covariate_check <- function(raw) {
  lab <- vapply(
    raw,
    function(x) {
      l <- attr(x, "label", exact = TRUE)
      if (is.null(l)) NA_character_ else as.character(l)
    },
    character(1)
  )
  # Stata truncates long names; the label carries the full (dotted) name
  col <- function(l) {
    j <- which(names(raw) == l | lab == l)
    if (length(j) != 1) stop("column not found by name/label: ", l)
    raw[[j]]
  }
  num <- function(x) suppressWarnings(as.numeric(x))
  chr <- function(x) {
    x <- as.character(x)
    x[x %in% ""] <- NA
    x
  }
  yes <- function(x) num(x) %in% 1
  cat_or_na <- function(x, fn) ifelse(is.na(x), NA, fn(x))

  ics <- raw$forlosningsmetode %in% "akutt_sectio"
  cx <- readr::parse_number(chr(raw$cx_akutt_sectio))
  keep <- !(ics & !is.na(cx) & cx <= 4) # principal stratum: reached 5 cm

  gate_pre <- num(col("kjente_pregravide_sykdommer"))
  gate_preg <- num(col("svangerskapsrelaterte_sykdommer"))
  no_gate <- is.na(gate_pre) & is.na(gate_preg)
  diab <- yes(col("hvilke_kjente_pregravide_sykdommer.dia_type1")) |
    yes(col("hvilke_kjente_pregravide_sykdommer.dia_type2")) |
    yes(col("hvilke_svangerskapsrelaterte_sykdommer.svangerskapsdia_metforminbehandlet")) |
    yes(col("hvilke_svangerskapsrelaterte_sykdommer.svangerskapsdia_insulinbehandlet"))
  htn <- yes(col("hvilke_kjente_pregravide_sykdommer.kronisk_hypertensjon")) |
    yes(col("hvilke_svangerskapsrelaterte_sykdommer.svangerskapshypertensjon")) |
    yes(col("hvilke_svangerskapsrelaterte_sykdommer.preeklampsi"))

  d <- data.frame(
    ICS = as.integer(ics),
    ROBSON = chr(raw$robson_gruppe),
    AGE = num(raw$alder),
    HEIGHT = num(raw$hoyde),
    BMI = num(raw$pregravid_vekt) / (num(raw$hoyde) / 100)^2,
    BWT = num(raw$fodselsvekt_gram),
    GA = num(col("gestasjonsalder_ved_fodsel_hele_uker")),
    NORWAY = cat_or_na(chr(raw$landbakgrunn), function(x) ifelse(x == "Norge", "Norway", "other")),
    EDU = chr(raw$utdanning),
    MARITAL = cat_or_na(chr(raw$sivilstatus),
                        function(x) ifelse(x %in% c("gift", "samboer"), "married_cohab", "other")),
    SMOKE = chr(raw$royk_for_eller_i_sv_s),
    SNUS = chr(raw$snus_for_eller_i_sv_s),
    DIAB = ifelse(no_gate, NA, ifelse(diab, "yes", "no")),
    HTN = ifelse(no_gate, NA, ifelse(htn, "yes", "no")),
    stringsAsFactors = FALSE
  )[keep, ]

  # missing-indicator method (SAP §4.1.3): "missing" level for categorical
  # covariates; median + indicator for continuous covariates
  miss_n <- colSums(is.na(d))
  for (v in c("ROBSON", "NORWAY", "EDU", "MARITAL", "SMOKE", "SNUS", "DIAB", "HTN")) {
    d[[v]] <- factor(ifelse(is.na(d[[v]]), "missing", d[[v]]))
  }
  for (v in c("AGE", "HEIGHT", "BMI", "BWT", "GA")) {
    m <- is.na(d[[v]])
    d[[paste0(v, "_MISS")]] <- as.integer(m)
    d[[v]][m] <- stats::median(d[[v]], na.rm = TRUE)
  }
  mi <- function(v) if (any(d[[paste0(v, "_MISS")]] == 1)) paste0(" + ", v, "_MISS") else ""

  base_terms <- paste0(
    "ROBSON + rcs3(AGE)", mi("AGE"), " + rcs3(BMI)", mi("BMI"),
    " + rcs3(HEIGHT)", mi("HEIGHT"), " + rcs3(BWT)", mi("BWT"), " + NORWAY"
  )
  fit <- function(rhs) stats::glm(stats::as.formula(paste("ICS ~", rhs)), binomial, data = d)
  base <- fit(base_terms)

  # 1. each proposed covariate's contribution (drop-one likelihood-ratio test)
  dr <- stats::drop1(base, test = "LRT")
  proposed <- data.frame(
    term = rownames(dr)[-1],
    df = dr$Df[-1],
    LR_chisq = round(dr$LRT[-1], 1),
    p = signif(dr$`Pr(>Chi)`[-1], 2),
    row.names = NULL
  )

  # 2. each candidate added one at a time to the proposed set
  cands <- c(EDU = "EDU", MARITAL = "MARITAL", SMOKE = "SMOKE", SNUS = "SNUS",
             DIAB = "DIAB", HTN = "HTN", GA = paste0("rcs3(GA)", mi("GA")))
  c_base <- cstat(stats::fitted(base), d$ICS)
  added <- do.call(rbind, lapply(names(cands), function(nm) {
    m <- fit(paste(base_terms, "+", cands[[nm]]))
    a <- stats::anova(base, m, test = "LRT")
    data.frame(
      candidate = nm,
      n_missing = unname(miss_n[nm]),
      df = a$Df[2],
      LR_chisq = round(a$Deviance[2], 1),
      p = signif(a$`Pr(>Chi)`[2], 2),
      delta_c = round(cstat(stats::fitted(m), d$ICS) - c_base, 4)
    )
  }))

  # 3. discrimination
  all_m <- fit(paste(base_terms, "+", paste(cands, collapse = " + ")))
  c_stats <- data.frame(
    model = c("Robson only", "proposed set", "proposed set + all candidates"),
    c_statistic = round(c(cstat(stats::fitted(fit("ROBSON")), d$ICS), c_base,
                          cstat(stats::fitted(all_m), d$ICS)), 4)
  )

  list(
    n = c(women = nrow(d), events = sum(d$ICS)),
    proposed_terms = proposed,
    candidates_added = added,
    discrimination = c_stats
  )
}

if (sys.nframe() == 0L) {
  stopifnot("run from the project root" = file.exists("config/cfg.yml"))
  source("R/make_raw/read_norwel_raw.R")
  cfg <- yaml::read_yaml("config/cfg.yml")
  acfg <- yaml::read_yaml("config/anon.yml")$anon
  raw <- read_norwel_raw(unlist(cfg$raw_files), cfg = cfg, acfg = acfg)
  raw$treatment <- NULL # blinded: the study period is not used
  print(covariate_check(raw))
}
