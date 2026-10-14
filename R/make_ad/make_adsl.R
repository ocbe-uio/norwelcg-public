# make_adsl.R — raw (flat, one row per woman) -> ADaM ADSL (subject-level).
# NorWel has no SDTM stage: the raw table is already one row per participant,
# so ADSL derives directly from it. All BDS/endpoint datasets merge the
# subject-level variables from here.
#
# Contents (SAP v0.83; decisions in docs/sap/sap_data_review.md):
#   * identifiers: SUBJID = the record key `nokkel` of the export (synthetic in
#     the anonymised copy), USUBJID = STUDYID-SUBJID; cluster (SITEID =
#     delivery unit) with the randomised cluster number, strata and annual
#     births from metadata/hospitals.csv
#   * time of birth BIRTHDTM — defines inclusion and the time interval (item
#     38); STEPN/STEP from the cfg$sw calendar, steps starting at
#     cfg$sw$step_start_time (08:00), births on the last inclusion day in step
#     12 (item 11)
#   * study period from the documentation form: FORMPER = the prefix of the
#     record key (CTR / TRAN / INT = control / transition / intervention;
#     item 62). TRT01P follows FORMPER and is NA in transition periods.
#     PERIODC = the period by the randomised schedule (hospital x step), kept
#     for the blinded form-vs-schedule check (item 53).
#   * mode of delivery per woman: the most operative across babies (CS >
#     instrumental > spontaneous); twin 2 missing -> twin 1 (SAP 4.1.1). A CS
#     of twin 2 only (twin 1 vaginal) is at full dilation (CXCSN = 10).
#   * analysis sets FASFL, PASFL (FAS minus transition periods), VDSFL (PAS and
#     vaginal delivery); TRNSFL; EXPOSN = LCG exposure step (supplementary
#     analysis 2). No principal stratum from SAP v0.9: the primary endpoint
#     counts all CS from 4 cm (item 69)
#   * covariates (SAP 4.1.3): Robson, age, pre-pregnancy BMI, height, birth
#     weight (first twin), gestational age; baseline-table characteristics.
#     CONTRADM and BWPCT/BWPCTC are derived but not in the SAP v0.9 baseline
#     table
#   * `lookups` (optional; NULL -> the derived columns are NA): `continent`
#     (metadata/country_continent.csv: country of origin -> continent, UN M49;
#     item 58) and `bwref` (metadata/bw_reference_skjaerven2000.csv: smoothed
#     mean and SD of birth weight by sex and completed week; item 64). The
#     birthweight percentile is Phi((BW - mean) / SD) for the first baby
#     (first twin included), weeks 20-44, known sex.

make_adsl <- function(raw, hospitals, codelists, cfg, lookups = NULL) {
  arms <- dplyr::bind_rows(lapply(cfg$arms, tibble::as_tibble))
  ref <- match(cfg$ref_arm, arms$armcd)
  arm_levels <- arms$arm[c(ref, setdiff(seq_len(nrow(arms)), ref))]
  sw_start <- as.Date(cfg$sw$start)
  sw_end   <- as.Date(cfg$sw$end)
  step_len <- 7 * (cfg$sw$step_weeks %||% 5)
  n_steps  <- cfg$sw$n_steps %||% 12
  # steps start at 08:00 local time; times are local clock times stored as UTC
  step0 <- as.POSIXct(paste(cfg$sw$start, cfg$sw$step_start_time %||% "00:00"),
                      format = "%Y-%m-%d %H:%M", tz = "UTC")
  # study period from the prefix of the record key (item 62)
  key_period <- c(CTR = "control", TRAN = "transition", INT = "intervention")

  yn  <- function(x) dplyr::if_else(x == 1, "Y", "N", missing = NA_character_)
  # English labels for the coded values (metadata/codelists.csv); the derived
  # flags below read the raw codes, not the labels
  dec <- function(x, variable) decode_cat(x, variable, codelists)
  has <- function(x) !is.na(x) & as.character(x) != ""
  cmv <- function(x) readr::parse_number(dplyr::na_if(as.character(x), ""))
  mode_rank <- function(x) dplyr::case_when(
    x == "akutt_sectio"           ~ 3L,
    x %in% c("tang", "vakuum")    ~ 2L,
    x == "spontan_vaginal_fodsel" ~ 1L,
    .default = NA_integer_
  )
  # checkbox children are NA when their gate question is "No": Y if any child
  # ticked, N if every gate is answered (children NA = gate No), NA otherwise
  any1 <- function(gates, ...) {
    m <- cbind(...)
    g <- cbind(gates)
    dplyr::case_when(
      rowSums(m == 1, na.rm = TRUE) > 0 ~ "Y",
      rowSums(is.na(g)) == 0            ~ "N",
      .default = NA_character_
    )
  }

  # time of birth: the typed copy where present (item 38), else the string
  birth_ny <- if ("nyfodselstidspunkt" %in% names(raw)) raw$nyfodselstidspunkt else NA
  birth <- dplyr::coalesce(
    lubridate::force_tz(as.POSIXct(birth_ny, tz = "UTC"), "UTC"),
    lubridate::ymd_hm(raw$fodselstidspunkt, quiet = TRUE)
  )

  hosp <- hospitals |>
    dplyr::select(SITEID, CLUSTER, STRATUM, BIRTHS, TRANS_STEP, LCG_STEP)
  unmapped <- setdiff(unique(stats::na.omit(raw$fodested)), hosp$SITEID)
  if (length(unmapped)) {
    stop("fodested not in metadata/hospitals.csv: ", paste(unmapped, collapse = ", "))
  }

  # optional lookups (baseline table): continent, birthweight reference
  cont <- lookups$continent
  cont_of <- function(x) {
    x <- dplyr::na_if(as.character(x), "")
    if (is.null(cont)) return(rep(NA_character_, length(x)))
    un <- setdiff(unique(stats::na.omit(x)), cont$code)
    if (length(un)) warning("country of origin not in the continent lookup: ",
                            paste(un, collapse = ", "))
    cont$continent[match(x, cont$code)]
  }
  bw_pct <- function(bw, sex, wk) {
    ref <- lookups$bwref
    if (is.null(ref)) return(rep(NA_real_, length(bw)))
    s <- dplyr::case_when(sex == "gutt" ~ "male", sex == "jente" ~ "female")
    i <- match(paste(s, wk), paste(ref$sex, ref$ga_weeks))
    100 * stats::pnorm((bw - ref$mean[i]) / ref$sd[i])
  }

  # record key: unique and non-missing, prefix CTR / TRAN / INT
  key <- as.character(raw$nokkel)
  if (any(is.na(key) | key == "")) stop("nokkel missing for ", sum(is.na(key) | key == ""), " rows")
  if (anyDuplicated(key)) stop("nokkel not unique: ", paste(head(key[duplicated(key)]), collapse = ", "))
  prefix <- sub("-.*$", "", key)
  if (!all(prefix %in% names(key_period))) {
    stop("nokkel prefix not CTR / TRAN / INT: ",
         paste(head(unique(setdiff(prefix, names(key_period)))), collapse = ", "))
  }
  if ("treatment" %in% names(raw)) {
    mism <- sum(key_period[prefix] != raw$treatment, na.rm = TRUE)
    if (mism) warning(mism, " records whose nokkel prefix differs from the source file; ",
                      "the prefix is used (SAP 3)")
  }

  adsl <- raw |>
    dplyr::mutate(SITEID = fodested, BIRTHDTM = birth) |>
    dplyr::left_join(hosp, by = "SITEID", relationship = "many-to-one") |>
    dplyr::mutate(
      STUDYID = cfg$studyid,
      SUBJID  = key,
      USUBJID = paste0(STUDYID, "-", SUBJID),

      # --- time of birth, calendar, study period ----------------------------
      ADMDTM  = lubridate::ymd_hm(tidspunkt_innleggelse, quiet = TRUE),
      BIRTHDT = lubridate::as_date(BIRTHDTM),
      INWINFL = dplyr::if_else(BIRTHDT >= sw_start & BIRTHDT <= sw_end,
                               "Y", "N", missing = "N"),
      # births before 08:00 on the first day belong to step 1, births on the
      # last inclusion day to step 12
      STEPN   = dplyr::if_else(
        INWINFL == "Y",
        pmin(pmax(as.integer(floor(as.numeric(difftime(BIRTHDTM, step0, units = "days")) /
                                     step_len)) + 1L, 1L),
             as.integer(n_steps)),
        NA_integer_
      ),
      STEP    = factor(STEPN, levels = seq_len(n_steps)),
      PERIODC = dplyr::case_when(
        is.na(STEPN) | is.na(CLUSTER) ~ NA_character_,
        STEPN >= LCG_STEP             ~ "intervention",
        STEPN >= TRANS_STEP           ~ "transition",
        .default                      = "control"
      ),
      FORMPER  = unname(key_period[prefix]),
      PERDISFL = dplyr::if_else(FORMPER != PERIODC, "Y", "N"),
      # LCG exposure step from the scheduled LCG step; at least 1 for a woman
      # documented on the LCG form (item 62)
      EXPOSN   = dplyr::case_when(
        FORMPER == "intervention" ~ pmax(STEPN - LCG_STEP + 1L, 1L),
        FORMPER == "control"      ~ 0L,
        .default = NA_integer_
      ),

      # --- treatment (documentation form; policy strategy) -------------------
      TRT01P  = factor(arms$arm[match(FORMPER, arms$raw)], levels = arm_levels),
      TRT01PN = match(TRT01P, levels(TRT01P)) - 1L,   # 0 = reference arm
      TRT01A  = TRT01P,

      # --- mode of delivery per woman ----------------------------------------
      TWINFL  = dplyr::if_else(has(tv2_fodselstidspunkt) | has(tv2_forlosningsmetode),
                               "Y", "N"),
      MODE1N  = mode_rank(forlosningsmetode),
      MODE2N  = dplyr::if_else(TWINFL == "Y", mode_rank(tv2_forlosningsmetode),
                               NA_integer_),
      MODEN   = pmax(MODE1N, MODE2N, na.rm = TRUE),
      MODE    = c("SVD", "IVD", "CS")[MODEN],
      MODEDTL = dec(forlosningsmetode, "forlosningsmetode"),
      ICSFL   = dplyr::if_else(MODEN == 3L, "Y", "N"),
      CXCSN   = dplyr::case_when(
        MODE1N == 3L ~ cmv(cx_akutt_sectio),
        MODEN == 3L  ~ 10          # CS of twin 2 after a vaginal twin 1
      ),

      # --- analysis sets -------------------------------------------------------
      FASFL   = "Y",   # export = eligible women (>= 18, planned vaginal, not opted out)
      TRNSFL  = dplyr::if_else(FORMPER == "transition", "Y", "N", missing = "N"),
      # births outside the inclusion window have no time interval: not in the PAS
      PASFL   = dplyr::if_else(FASFL == "Y" & !is.na(TRT01P) & INWINFL == "Y", "Y", "N"),
      VDSFL   = dplyr::if_else(PASFL == "Y" & MODEN %in% 1:2, "Y", "N"),

      # --- covariates and baseline characteristics ---------------------------
      AGE      = alder,
      COUNTRYO = dplyr::na_if(landbakgrunn, ""),
      NORWAYFL = dplyr::if_else(COUNTRYO == "Norge", "Y", "N", missing = NA_character_),
      MARSTAT  = dec(sivilstatus, "sivilstatus"),
      COHABFL  = dplyr::if_else(sivilstatus %in% c("gift", "samboer"), "Y", "N",
                                missing = NA_character_),
      EDULVL   = dec(utdanning, "utdanning"),
      HIEDUFL  = dplyr::if_else(utdanning == "hoyere_utdanning", "Y", "N",
                                missing = NA_character_),
      HEIGHT   = hoyde,
      WGTPREG  = pregravid_vekt,
      BMIPREG  = WGTPREG / (HEIGHT / 100)^2,
      SMOKEFL  = yn(royk_for_eller_i_sv_s),
      SNUSFL   = yn(snus_for_eller_i_sv_s),
      DIABFL = any1(cbind(kjente_pregravide_sykdommer,
                          svangerskapsrelaterte_sykdommer),
                    hvilke_kjente_pregravide_sykdommer_dia_type1,
                    hvilke_kjente_pregravide_sykdommer_dia_type2,
                    hvilke_svangerskapsrelaterte_sykdommer_svangerskapsdia_metforminbehandlet,
                    hvilke_svangerskapsrelaterte_sykdommer_svangerskapsdia_insulinbehandlet),
      HTNFL  = any1(cbind(kjente_pregravide_sykdommer,
                          svangerskapsrelaterte_sykdommer),
                    hvilke_kjente_pregravide_sykdommer_kronisk_hypertensjon,
                    hvilke_svangerskapsrelaterte_sykdommer_svangerskapshypertensjon,
                    hvilke_svangerskapsrelaterte_sykdommer_preeklampsi),
      ROBSON   = dec(robson_gruppe, "robson_gruppe"),
      PARITY   = dec(paritet, "paritet"),
      NULLIPFL = dplyr::if_else(paritet == "p0", "Y", "N", missing = NA_character_),
      PREVCSFL = yn(tidligere_sectio),
      # first vaginal delivery: nullipara, or para-1 whose only previous birth
      # was a CS (not fully derivable for p2+ with previous CS -> "N")
      FVDFL    = dplyr::case_when(
        NULLIPFL == "Y"                        ~ "Y",
        paritet == "p1" & tidligere_sectio == 1 ~ "Y",
        is.na(dplyr::na_if(paritet, ""))        ~ NA_character_,
        .default = "N"
      ),
      SPONTFL  = dplyr::if_else(induksjon == 0, "Y", "N", missing = NA_character_),
      INDUCFL  = dplyr::if_else(induksjon == 1, "Y", "N", missing = NA_character_),
      ADMREAS  = dec(innleggelsesarsak, "innleggelsesarsak"),
      CONTRADM = as.numeric(antall_rier_10min_innkomst),
      HOSPBIRC = cut(BIRTHS, c(1000, 2000, 4000, Inf), right = FALSE,
                     labels = c("1000-1999", "2000-3999", ">= 4000")),
      GAWKS    = gestasjonsalder_ved_fodsel_hele_uker,
      GADAYS   = GAWKS * 7L + gestasjonsalder_ved_fodsel_pluss_dager,
      GA       = GADAYS / 7,
      SEX      = dec(barnets_kjonn, "barnets_kjonn"),
      BWT      = fodselsvekt_gram,
      CONTINENT = cont_of(landbakgrunn),
      BWPCT    = bw_pct(BWT, barnets_kjonn, GAWKS),
      BWPCTC   = dplyr::case_when(BWPCT < 10 ~ "Small (< 10th percentile)",
                                  BWPCT > 90 ~ "Large (> 90th percentile)",
                                  !is.na(BWPCT) ~ "Appropriate (10th-90th percentile)"),
      BWCAT    = cut(BWT, c(-Inf, 3000, 3500, 4000, 4500, Inf), right = FALSE,
                     labels = c("< 3000 g", "3000-3499 g", "3500-3999 g",
                                "4000-4499 g", ">= 4500 g")),
      HDCIRC   = neonatal_hodeomkrets
    ) |>
    dplyr::select(
      STUDYID, USUBJID, SUBJID, SITEID, CLUSTER, STRATUM,
      ADMDTM, BIRTHDTM, BIRTHDT, INWINFL, STEPN, STEP,
      PERIODC, FORMPER, PERDISFL, EXPOSN, TRT01P, TRT01PN, TRT01A,
      FASFL, PASFL, VDSFL, TRNSFL,
      TWINFL, MODE1N, MODE2N, MODEN, MODE, MODEDTL, ICSFL, CXCSN,
      AGE, COUNTRYO, NORWAYFL, MARSTAT, COHABFL, EDULVL, HIEDUFL,
      HEIGHT, WGTPREG, BMIPREG, SMOKEFL, SNUSFL, DIABFL, HTNFL,
      ROBSON, PARITY, NULLIPFL, PREVCSFL, FVDFL, SPONTFL, INDUCFL, ADMREAS,
      CONTRADM, HOSPBIRC, CONTINENT, GAWKS, GADAYS, GA, SEX, BWT, BWPCT, BWPCTC,
      BWCAT, HDCIRC
    ) |>
    labelled::set_variable_labels(
      STUDYID  = "Study identifier",
      USUBJID  = "Unique subject identifier",
      SUBJID   = "Subject identifier (record key nokkel)",
      SITEID   = "Cluster / delivery unit",
      CLUSTER  = "Randomised cluster number (sequence)",
      STRATUM  = "Randomisation stratum (births x CS rate)",
      ADMDTM   = "Admission datetime",
      BIRTHDTM = "Datetime of birth (first baby)",
      BIRTHDT  = "Date of birth (first baby)",
      INWINFL  = "Birth within the inclusion window",
      STEPN    = "Stepped-wedge time interval (numeric, from time of birth; steps start 08:00)",
      STEP     = "Stepped-wedge time interval",
      PERIODC  = "Study period by randomised crossover schedule",
      FORMPER  = "Study period of the documentation form (nokkel prefix)",
      PERDISFL = "Form period differs from scheduled period",
      EXPOSN   = "LCG exposure step (1 = first step after transition; 0 = control)",
      TRT01P   = "Planned treatment (documentation form period)",
      TRT01PN  = "Planned treatment (0 = reference)",
      TRT01A   = "Actual treatment (= planned; treatment policy)",
      FASFL    = "Full analysis set flag",
      PASFL    = "Primary analysis set flag (FAS minus transition periods)",
      VDSFL    = "Vaginal delivery set flag",
      TRNSFL   = "Birth during the hospital's transition period",
      TWINFL   = "Twin delivery",
      MODE1N   = "Mode of delivery, first baby (1 SVD, 2 IVD, 3 CS)",
      MODE2N   = "Mode of delivery, second baby (1 SVD, 2 IVD, 3 CS)",
      MODEN    = "Mode of delivery, woman (most operative; 1 SVD, 2 IVD, 3 CS)",
      MODE     = "Mode of delivery, woman (SVD / IVD / CS)",
      MODEDTL  = "Mode of delivery, first baby (as recorded)",
      ICSFL    = "Intrapartum caesarean section (any baby)",
      CXCSN    = "Cervical dilatation at CS (cm)",
      AGE      = "Maternal age (years)",
      COUNTRYO = "Country of origin",
      NORWAYFL = "Country of origin: Norway",
      MARSTAT  = "Marital status",
      COHABFL  = "Cohabitant or married",
      EDULVL   = "Education level",
      HIEDUFL  = "Higher education",
      HEIGHT   = "Height (cm)",
      WGTPREG  = "Pre-pregnancy weight (kg)",
      BMIPREG  = "Pre-pregnancy BMI (kg/m2)",
      SMOKEFL  = "Smoking before/during pregnancy",
      SNUSFL   = "Snuff before/during pregnancy",
      DIABFL   = "Diabetes (pregestational or medically treated GDM)",
      HTNFL    = "Hypertensive disease (chronic, gestational or preeclampsia)",
      ROBSON   = "Robson ten-group classification",
      PARITY   = "Parity",
      NULLIPFL = "Nulliparous",
      PREVCSFL = "Previous caesarean section",
      FVDFL    = "First vaginal delivery",
      SPONTFL  = "Spontaneous onset of labour",
      INDUCFL  = "Induction of labour",
      ADMREAS  = "Reason for admission",
      CONTRADM = "Contractions per 10 minutes at admission",
      HOSPBIRC = "Annual number of deliveries at the hospital",
      GAWKS    = "Gestational age at birth (completed weeks)",
      GADAYS   = "Gestational age at birth (days)",
      GA       = "Gestational age at birth (weeks, decimal)",
      SEX      = "Neonate sex (first baby)",
      BWT      = "Birth weight (g, first baby)",
      CONTINENT = "Country of origin: continent",
      BWPCT    = "Birthweight percentile for gestational age and sex (Skjaerven 2000)",
      BWPCTC   = "Birthweight for gestational age (Skjaerven 2000)",
      BWCAT    = "Birth weight category (first baby)",
      HDCIRC   = "Neonatal head circumference (cm, first baby)"
    )

  fs::dir_create(path_adam())
  readr::write_rds(adsl, path_adam("adsl.rds"))
  adsl
}
