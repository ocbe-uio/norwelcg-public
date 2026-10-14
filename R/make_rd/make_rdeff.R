# make_rdeff.R — ADEFF -> reporting dataset for the dichotomous endpoints
# (complete case; the multiple-imputation endpoints are in make_rdmi.R).
#
# Model (SAP 4.1.2): binomial GLMM, logit link, random intercept for cluster,
# fixed effects for treatment, time interval (STEP) and the SAP 4.1.3
# covariates; absolute risk difference (primary summary measure) and relative
# difference by G-computation integrating over the random cluster effect,
# delta-method standard errors, 95% CIs (helpers in rd_helpers.R).
#
# Analyses (SAP v0.9; item 69):
#   PRIMARY   ICS, PAS (all CS from 4 cm, both periods); NI (+1.5 pp) and
#             superiority p-values and conclusions (SAP 2.1)
#   SENS1     unadjusted model                       (SAP 4.1.4, same estimand)
#   SENS2     hospital as a fixed effect             (SAP 4.1.4)
#   SUPP1     transition periods included as WHO partograph (FAS; SAP 4.1.5)
#   SUPP2     exposure time: LCG first step / later steps vs WHO partograph
#   SECONDARY dichotomous secondary endpoints in their analysis set (APOP: PAS,
#             or VDS for episiotomy and OASIS)
#   SUPPLEMENTARY composite endpoints, CS = no event (PAS; SAP 5.1.1.7)

make_rdeff <- function(adeff, cfg) {
  mi_params <- "CORDPH7"                             # analysed in make_rdmi()
  fas <- adeff[adeff$FASFL == "Y", ]
  ics <- fas[fas$PARAMCD == "ICS", ]
  prim <- ics[ics$PASFL == "Y", ]
  ref <- levels(adeff$TRT01P)[1]
  int <- levels(adeff$TRT01P)[2]

  # transition women as WHO partograph (SUPP1)
  trans <- ics
  trans$TRT01P[trans$TRNSFL == "Y"] <- ref
  # exposure time (SUPP2): WHO partograph / LCG first step after transition /
  # later steps, labelled from the arm levels
  expo <- prim
  expo_lv <- c(ref, paste(int, "step 1"), paste(int, "step 2+"))
  expo$EXPCAT <- factor(
    dplyr::case_when(expo$EXPOSN == 0 ~ expo_lv[1], expo$EXPOSN == 1 ~ expo_lv[2],
                     expo$EXPOSN >= 2 ~ expo_lv[3]),
    levels = expo_lv)

  lab <- function(res, paramcd, param, parcat1, analysis, population) {
    dplyr::mutate(res, PARAMCD = paramcd, PARAM = param, PARCAT1 = parcat1,
                  analysis = analysis, population = population, .before = 1)
  }
  ics_lab <- function(res, analysis, population) {
    lab(res, "ICS", "Intrapartum caesarean section", "PRIMARY", analysis, population)
  }

  primary <- list(
    ics_lab(analyse_bin(prim, cfg, ni = TRUE), "PRIMARY", "PAS"),
    ics_lab(analyse_bin(prim, cfg, adjust = FALSE, ni = TRUE),
            "SENS1 UNADJUSTED", "PAS"),
    ics_lab(analyse_bin(prim, cfg, random = FALSE, ni = TRUE),
            "SENS2 FIXED CLUSTER", "PAS"),
    ics_lab(analyse_bin(trans, cfg), "SUPP1 TRANSITION AS WHO PARTOGRAPH", "FAS"),
    ics_lab(analyse_bin(expo, cfg, trt = "EXPCAT",
                        contrasts = list(expo_lv[1:2], expo_lv[c(1, 3)])),
            "SUPP2 EXPOSURE TIME", "PAS")
  )

  # secondary and supplementary dichotomous endpoints, complete case
  sec <- fas |>
    dplyr::filter(ATYPE == "BIN", !PARAMCD %in% mi_params,
                  PARCAT1 %in% c("SECONDARY WOMEN", "SECONDARY NEONATE",
                                 "SUPPLEMENTARY"))
  secondary <- lapply(unique(sec$PARAMCD), function(p) {
    dt <- sec[sec$PARAMCD == p, ]
    dt <- if (dt$APOP[1] == "VDS") {
      dt[dt$VDSFL == "Y" & dt$ANL01FL == "Y", ]
    } else {
      dt[dt$PASFL == "Y" & dt$ANL01FL == "Y", ]
    }
    lab(analyse_bin(dt, cfg), p, dt$PARAM[1], dt$PARCAT1[1],
        if (dt$PARCAT1[1] == "SUPPLEMENTARY") "SUPPLEMENTARY" else "SECONDARY",
        if (dt$APOP[1] == "VDS") "VDS" else "PAS")
  })

  rdeff <- dplyr::bind_rows(c(primary, secondary))
  fs::dir_create(path_rd())
  readr::write_rds(rdeff, path_rd("rdeff.rds"))
  rdeff
}
