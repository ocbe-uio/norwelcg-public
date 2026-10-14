# make_adeff.R — raw + ADSL -> ADaM ADEFF (BDS, one row per woman per PARAM).
# All per-woman endpoints of SAP v0.9 in one dataset (decisions per endpoint in
# docs/sap/sap_data_review.md items 41, 62 and 69).
#
#   PARCAT1 = "PRIMARY"              intrapartum caesarean section (all CS from
#                                    4 cm, both periods)
#             "SECONDARY WOMEN"      SAP 5.1.1.1 efficacy endpoints
#             "SECONDARY NEONATE"    SAP 5.1.1.2 (worst baby per woman)
#             "SUPPLEMENTARY"        composite versions (CS = no event) of the
#                                    vaginal-delivery-set endpoints (SAP 5.1.1.7)
#             "AUXILIARY"            numeric variables for multiple imputation
#             "DESCRIPTIVE"          SAP 5.1.1.3 descriptive endpoints
#   ATYPE   = analysis type: BIN (0/1), NUM, CAT
#   APOP    = analysis set of the endpoint: PAS, or VDS (vaginal delivery set:
#             episiotomy, OASIS)
#   ANL01FL = "N" for descriptive endpoints where the endpoint does not apply
#             (no CS for the CS characteristics; LCG-form items in the WHO
#             period; follow-up items whose gate question is not yes)
#   DTYPE   = "IMPUTED" where a missing status was set to "no" (SAP tables)
#
# Amniotomy, oxytocin and epidural are counted whatever the cervical dilatation
# (SAP v0.9). Missing data left as NA: complete case (PPH, Apgar, OASIS), or
# multiple imputation in the analysis layer (cord pH).

# `lookups$sdm` (optional): metadata/sdm_items.csv — English labels and gates of
# the shared decision-making items (LCG form only; item 65(d)); only the
# operative-delivery items are in SAP v0.9. Without it the raw variable names
# are used and no gate is applied.
make_adeff <- function(raw, adsl, codelists, cfg, lookups = NULL) {
  stopifnot(nrow(raw) == nrow(adsl))

  d <- dplyr::bind_cols(
    adsl |> dplyr::select(USUBJID, MODE, MODE1N, ICSFL, CXCSN, FORMPER),
    raw
  )
  n <- nrow(d)
  num <- function(x) suppressWarnings(as.numeric(x))

  # ---- param builders ------------------------------------------------------
  bin_param <- function(x, paramcd, param, parcat1, parcat2 = NA_character_,
                        impute_no = FALSE, apop = "PAS", anl = TRUE,
                        atype = "BIN") {
    out <- tibble::tibble(
      USUBJID = d$USUBJID,
      PARAMCD = paramcd, PARAM = param,
      PARCAT1 = parcat1, PARCAT2 = parcat2,
      ATYPE = atype, APOP = apop,
      AVAL = as.numeric(x), AVALC = NA_character_,
      DTYPE = "",
      ANL01FL = dplyr::if_else(rep_len(anl, n), "Y", "N", missing = "Y")
    )
    if (impute_no) {
      out$DTYPE[is.na(out$AVAL)] <- "IMPUTED"
      out$AVAL[is.na(out$AVAL)] <- 0
    }
    out
  }
  # `codelist` names the codelist used to translate the recorded values into
  # English (metadata/codelists.csv)
  # `anl` marks the women the endpoint applies to (e.g. CS only)
  cat_param <- function(x, paramcd, param, parcat2 = NA_character_,
                        aval = NULL, codelist = NULL, anl = TRUE) {
    tibble::tibble(
      USUBJID = d$USUBJID,
      PARAMCD = paramcd, PARAM = param,
      PARCAT1 = "DESCRIPTIVE", PARCAT2 = parcat2,
      ATYPE = "CAT", APOP = "PAS",
      AVAL = if (is.null(aval)) NA_real_ else as.numeric(aval),
      AVALC = if (is.null(codelist)) dplyr::na_if(as.character(x), "")
              else decode_cat(x, codelist, codelists),
      DTYPE = "",
      ANL01FL = dplyr::if_else(rep_len(anl, n), "Y", "N", missing = "N")
    )
  }
  # ---- endpoint sources ----------------------------------------------------
  cs  <- d$ICSFL == "Y"                       # woman level, any baby (ADSL)
  cs1 <- d$MODE1N %in% 3L                     # the CS was the first baby's
  # CS characteristic: the first baby's, or the second twin's for a CS of the
  # second twin only
  tw <- function(x1, x2) {
    x2 <- if (is.null(x2)) rep(NA_character_, n) else as.character(x2)
    dplyr::if_else(cs1, as.character(x1), x2)
  }
  lcg <- d$FORMPER %in% "intervention"        # LCG-form-only items
  pph <- num(d$blodtap_ml_inntil_2timer_pp)
  # worst baby per woman among the babies with a value: event if any baby has
  # it, no event if every observed baby is without it, NA if no baby observed
  worst <- function(b1, b2) {
    dplyr::case_when(
      b1 %in% TRUE | b2 %in% TRUE ~ 1,
      !is.na(b1) | !is.na(b2)     ~ 0,
      .default = NA_real_
    )
  }
  # arterial/venous pH outside 6.5-7.55 set to missing (SAP 5.1.1.4 v0.9;
  # cleaning rule 13)
  inr <- function(x, lo, hi) dplyr::if_else(x >= lo & x <= hi, x, NA_real_)
  ph <- function(x) inr(num(x), 6.5, 7.55)
  pha1 <- ph(d$ph_arterie)
  pha2 <- ph(d$tv2_ph_arterie)
  # base excess / deficit outside -25..25 set to missing (SAP 5.1.1.4 v0.9;
  # cleaning rule 15); deficit is positive by definition
  be <- function(excess, deficit) {
    dplyr::coalesce(inr(num(excess), -25, 25), -inr(num(deficit), -25, 25))
  }

  # OASIS: highest perineal tear grade ticked is 3 (3a-3c) or 4
  grades <- cbind(d$perinealrift_grad_grad_1, d$perinealrift_grad_grad_2,
                  d$perinealrift_grad_grad_3a, d$perinealrift_grad_grad_3b,
                  d$perinealrift_grad_grad_3c, d$perinealrift_grad_grad_4) == 1
  grades[is.na(grades)] <- FALSE
  top <- apply(grades * matrix(c(1, 2, 3, 3, 3, 4), n, 6, byrow = TRUE), 1, max)
  oasis <- dplyr::case_when(
    d$perinealrift == 0 ~ 0,
    d$perinealrift == 1 & top >= 3 ~ 1,
    d$perinealrift == 1 & top > 0 ~ 0,
    .default = NA_real_               # no status, or a tear without grade
  )

  amn <- num(d$amniotomi)
  oxy <- num(d$oxytocin_infusjon)
  eda <- dplyr::if_else(d$medikamentell_smertelindring == 0, 0,
                        num(d$type_medikamentell_smertelindring_epidural))
  epis <- num(d$episiotomi)

  params <- list(
    # --- primary ------------------------------------------------------------
    bin_param(cs, "ICS", "Intrapartum caesarean section", "PRIMARY"),

    # --- secondary, women ----------------------------------------------------
    bin_param(d$MODE == "SVD", "SVD", "Spontaneous vaginal delivery",
              "SECONDARY WOMEN"),
    bin_param(d$MODE == "IVD", "IVD", "Instrumental vaginal delivery",
              "SECONDARY WOMEN"),
    bin_param(amn, "AMNIO", "Occurrence of amniotomy during labour",
              "SECONDARY WOMEN", impute_no = TRUE),
    bin_param(oxy, "OXY", "Use of oxytocin during labour",
              "SECONDARY WOMEN", impute_no = TRUE),
    bin_param(eda, "EDA", "Use of epidural analgesia during labour",
              "SECONDARY WOMEN", impute_no = TRUE),
    bin_param(d$fosterovervaking_intermitterende == 1 &
                d$fosterovervaking_kontinuerlig_ekstern_ctg != 1 &
                d$fosterovervaking_stan_kontinuerlig_intern_ctg != 1,
              "IFM", "Intermittent fetal monitoring (exclusive)",
              "SECONDARY WOMEN", impute_no = TRUE),
    bin_param(d$fosterovervaking_kontinuerlig_ekstern_ctg == 1 |
                d$fosterovervaking_stan_kontinuerlig_intern_ctg == 1,
              "CFM", "Continuous fetal monitoring",
              "SECONDARY WOMEN", impute_no = TRUE),
    bin_param(oasis, "OASIS", "Occurrence of OASIS (perineal tear grade 3-4)",
              "SECONDARY WOMEN", apop = "VDS"),
    bin_param(epis, "EPIS", "Episiotomy",
              "SECONDARY WOMEN", impute_no = TRUE, apop = "VDS"),
    bin_param(pph > 1000, "PPH1000", "Postpartum haemorrhage > 1000 ml",
              "SECONDARY WOMEN"),

    # --- secondary, neonate (worst baby per woman) ----------------------------
    bin_param(worst(pha1 < 7, pha2 < 7), "CORDPH7",
              "Arterial umbilical cord pH < 7.00 (any baby)", "SECONDARY NEONATE"),
    bin_param(worst(num(d$apgar_skar_5min) < 7, num(d$tv2_apgar_skar_5min) < 7),
              "APGAR5L7", "Apgar score < 7 at 5 minutes (any baby)",
              "SECONDARY NEONATE"),
    bin_param(worst(d$overflyttet_nfi_innen_to_timer == 1,
                    d$tv2_overflyttet_nfi_innen_to_timer == 1),
              "NICU2H", "NICU admission within 2 hours (any baby)",
              "SECONDARY NEONATE"),

    # --- supplementary: composite, CS = no event (SAP 5.1.1.7) ----------------
    bin_param(dplyr::if_else(cs, 0, epis), "EPISC",
              "Episiotomy, CS counted as no (composite)", "SUPPLEMENTARY",
              impute_no = TRUE),
    bin_param(dplyr::if_else(cs, 0, oasis), "OASISC",
              "OASIS, CS counted as no (composite)", "SUPPLEMENTARY"),

    # --- auxiliary variables for multiple imputation ---------------------------
    bin_param(pha1, "PHA", "Arterial cord pH, first baby", "AUXILIARY", atype = "NUM"),
    bin_param(ph(d$ph_vene), "PHV", "Venous cord pH, first baby", "AUXILIARY",
              atype = "NUM"),
    bin_param(be(d$base_excess_arterie, d$base_deficit_arterie), "BEA",
              "Arterial base excess, first baby", "AUXILIARY", atype = "NUM"),
    bin_param(be(d$base_excess_vene, d$base_deficit_vene), "BEV",
              "Venous base excess, first baby", "AUXILIARY", atype = "NUM"),
    bin_param(d$apgar_skar_1min, "APGAR1", "Apgar score at 1 minute, first baby",
              "AUXILIARY", atype = "NUM"),
    bin_param(d$apgar_skar_5min, "APGAR5", "Apgar score at 5 minutes, first baby",
              "AUXILIARY", atype = "NUM"),

    # --- descriptive: caesarean-section characteristics -----------------------
    # a CS of the second twin only (first twin vaginal): the second twin's
    # characteristics, dilatation 10 cm as in ADSL (CXCSN); no twin-2 level
    cat_param(dplyr::if_else(cs & !is.na(d$CXCSN), sprintf("%d cm", as.integer(d$CXCSN)),
                             NA_character_),
              "CXCS", "Cervical dilation at caesarean section", "CS CHARACTERISTICS",
              aval = dplyr::if_else(cs, d$CXCSN, NA_real_), anl = cs),
    cat_param(dplyr::if_else(cs & cs1, d$niva_ledende_del_akutt_sectio, NA_character_),
              "CSLEVEL", "Level of presenting part at caesarean section",
              "CS CHARACTERISTICS", codelist = "niva_ledende_del_akutt_sectio", anl = cs),
    cat_param(dplyr::if_else(cs, tw(d$fotal_fodselspresentasjon,
                                    d$tv2_fotal_fodselspresentasjon), NA_character_),
              "CSPRES", "Fetal presentation at caesarean section", "CS CHARACTERISTICS",
              codelist = "fotal_fodselspresentasjon", anl = cs),
    cat_param(dplyr::if_else(cs, tw(d$fotal_fodselsposisjon, d$tv2_fotal_fodselsposisjon),
                             NA_character_),
              "CSPOS", "Fetal position at caesarean section", "CS CHARACTERISTICS",
              codelist = "fotal_fodselsposisjon", anl = cs),
    cat_param(dplyr::if_else(cs, tw(d$hovedarsak_operativ_forlosning,
                                    d$tv2_hovedarsak_operativ_forlosning), NA_character_),
              "CSREAS", "Main reason for caesarean section", "CS CHARACTERISTICS",
              codelist = "hovedarsak_operativ_forlosning", anl = cs),

    # --- descriptive: other ----------------------------------------------------
    cat_param(dplyr::case_when(
                d$fosterovervaking_stan_kontinuerlig_intern_ctg == 1 ~
                  "STAN or continuous internal CTG",
                d$fosterovervaking_kontinuerlig_ekstern_ctg == 1 ~
                  "Continuous external CTG",
                .default = NA_character_),
              "CFMTYPE", "Type of continuous fetal monitoring", "OTHER",
              anl = d$fosterovervaking_kontinuerlig_ekstern_ctg %in% 1 |
                d$fosterovervaking_stan_kontinuerlig_intern_ctg %in% 1),
    cat_param(dplyr::case_when(
                pph > 1500 ~ ">1500", pph > 1000 ~ ">1000-1500",
                pph > 500  ~ ">500-1000", !is.na(pph) ~ "<=500",
                .default = NA_character_),
              "PPHCAT", "Postpartum haemorrhage category (ml)", "OTHER",
              aval = pph),
    # prolonged labour per the arm's own guideline definition (coalesced across
    # the arm-specific source variables; each woman has only her form's set)
    bin_param(dplyr::coalesce(d$tidsintervall_lcg_overskredet_forste_stadium,
                              d$tiltakslinjen_krysset_forste_stadium),
              "DYST1", "Prolonged first stage of labour (guideline definition)",
              "DESCRIPTIVE", "OTHER"),
    bin_param(dplyr::coalesce(d$tidsintervall_lcg_overskredet_andre_stadium,
                              d$avdelingens_tidsgrenser_overskredet_andre_stadium),
              "DYST2", "Prolonged second stage of labour (guideline definition)",
              "DESCRIPTIVE", "OTHER")
  )

  # --- descriptive: shared decision making for operative delivery -----------
  # recorded on the LCG form only: presented for the LCG period (ANL01FL), the
  # conditional items among the women whose gate question is yes (item 65(d));
  # SAP v0.9 keeps only the operative-delivery items (labour companionship and
  # the other situations are in later SAPs)
  items <- lookups$sdm
  label_of <- function(v) {
    if (!is.null(items) && v %in% items$variable) items$item_en[match(v, items$variable)]
    else v
  }
  gate_ok <- function(v) {
    g <- if (is.null(items)) "" else items$gate[match(v, items$variable)]
    if (is.na(g) || g == "" || !g %in% names(d)) rep(TRUE, n) else num(d[[g]]) %in% 1
  }
  ord <- function(cols) {
    if (is.null(items)) cols else cols[order(match(cols, items$variable), na.last = TRUE)]
  }
  sdm_cols <- ord(grep("^samvalg_operativ_forlosning", names(d), value = TRUE))
  params <- c(params, lapply(seq_along(sdm_cols), function(i) {
    v <- sdm_cols[i]
    cat_param(d[[v]], sprintf("SDM%02d", i), label_of(v), "SHARED DECISION MAKING",
              codelist = "samvalg_agreement", anl = lcg & gate_ok(v))
  }))

  adeff <- dplyr::bind_rows(params) |>
    dplyr::left_join(
      adsl |>
        dplyr::select(STUDYID, USUBJID, SITEID, CLUSTER, STEPN, STEP,
                      PERIODC, EXPOSN, TRT01P, TRT01PN, TRT01A,
                      FASFL, PASFL, VDSFL, TRNSFL,
                      MODE, MODEDTL, ROBSON, AGE, BMIPREG, HEIGHT, BWT, GA),
      by = "USUBJID"
    ) |>
    dplyr::relocate(STUDYID) |>
    labelled::set_variable_labels(
      PARAMCD = "Parameter code",
      PARAM   = "Parameter",
      PARCAT1 = "Parameter category 1 (analysis role)",
      PARCAT2 = "Parameter category 2",
      ATYPE   = "Analysis type (BIN / NUM / CAT)",
      APOP    = "Analysis set of the endpoint (PAS / VDS)",
      AVAL    = "Analysis value (numeric; 1 = event)",
      AVALC   = "Analysis value (character)",
      DTYPE   = "Derivation type (IMPUTED = missing status set to no)",
      ANL01FL = "Analysis flag (N = endpoint not applicable)"
    )

  fs::dir_create(path_adam())
  readr::write_rds(adeff, path_adam("adeff.rds"))
  adeff
}
