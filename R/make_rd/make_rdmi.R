# make_rdmi.R — ADEFF -> reporting dataset for the dichotomous endpoints with
# multiple imputation (SAP 5.1.1.4). From SAP v0.9 only the arterial cord pH
# (perineal support is in a later SAP; item 69).
#
#   CORDPH7  arterial cord pH < 7.00, PAS: for women with no
#            measured baby, the first baby's arterial pH is imputed by
#            predictive mean matching (m = cfg$analysis$mi$m_cordph) and
#            dichotomised; auxiliaries venous pH, arterial/venous base excess,
#            Apgar 1 and 5 min, NICU <= 2 h, mode of delivery. Women with at
#            least one measured baby keep their observed value. Missing
#            arterial pH is assumed missing at random given the imputation-
#            model variables (hospital, time interval, mode of delivery and the
#            auxiliaries; SAP 5.1.1.4, item 56). n_miss = number not recorded.
#
# Imputation model: the analysis-model variables (treatment, time interval,
# hospital as a fixed effect, SAP 4.1.3 covariates as prepared for the model)
# plus the auxiliaries. Per imputed dataset: the GLMM and G-computation of
# rd_helpers.R; RD and log RR combined by Rubin's rules.

make_rdmi <- function(adeff, cfg) {
  need <- c("CORDPH7", "PHA", "PHV", "BEA", "BEV", "APGAR1", "APGAR5", "NICU2H")
  wide <- adeff |>
    dplyr::filter(PARAMCD %in% need) |>
    dplyr::select(USUBJID, PARAMCD, AVAL) |>
    tidyr::pivot_wider(names_from = PARAMCD, values_from = AVAL)
  wd <- adeff |>
    dplyr::filter(PARAMCD == "ICS", FASFL == "Y") |>
    dplyr::select(USUBJID, TRT01P, STEP, SITEID, PASFL, VDSFL,
                  MODE, MODEDTL, ROBSON, AGE, BMIPREG, HEIGHT, BWT, GA) |>
    dplyr::left_join(wide, by = "USUBJID")
  pas <- wd[wd$PASFL == "Y", ]
  mi <- cfg$analysis$mi

  fac <- function(x) factor(x)
  runs <- list(
    list(PARAMCD = "CORDPH7", PARAM = "Arterial umbilical cord pH < 7.00 (any baby)",
         PARCAT1 = "SECONDARY NEONATE", population = "PAS",
         data = pas, target = "PHA",
         aux = c("PHV", "BEA", "BEV", "APGAR1", "APGAR5", "NICU2H", "MODE"),
         m = mi$m_cordph,
         derive = function(ci, d) dplyr::if_else(!is.na(d$CORDPH7), d$CORDPH7,
                                                 as.numeric(ci$PHA < 7)))
  )

  rdmi <- dplyr::bind_rows(lapply(runs, function(r) {
    res <- mi_analyse(r$data, r$target, r$aux, cfg, r$m, r$derive)
    dplyr::mutate(res, PARAMCD = r$PARAMCD, PARAM = r$PARAM, PARCAT1 = r$PARCAT1,
                  analysis = if (r$PARCAT1 == "SUPPLEMENTARY") "SUPPLEMENTARY" else "SECONDARY",
                  population = r$population, .before = 1)
  }))
  fs::dir_create(path_rd())
  readr::write_rds(rdmi, path_rd("rdmi.rds"))
  rdmi
}

# Multiple imputation + analysis of one dichotomous endpoint. `target` is the
# variable imputed (binary 0/1 -> logistic regression; numeric -> pmm);
# `derive(ci, d)` turns an imputed dataset into the 0/1 endpoint (default:
# the imputed target itself).
mi_analyse <- function(d, target, aux, cfg, m, derive = NULL) {
  d$TRT01P <- droplevels(d$TRT01P)
  d$STEP <- droplevels(d$STEP)
  d$SITEID <- factor(d$SITEID)
  for (v in aux) if (is.character(d[[v]])) d[[v]] <- factor(d[[v]])
  binary <- all(stats::na.omit(d[[target]]) %in% c(0, 1))
  pc <- prep_covars(d, cfg, TRUE)
  d <- pc$data
  pred <- c("TRT01P", "STEP", "SITEID", pc$terms)
  md <- as.data.frame(d[, c(target, aux, pred)])
  if (binary) md[[target]] <- factor(md[[target]], levels = c(0, 1))
  meth <- mice::make.method(md)
  meth[pred] <- ""
  imp <- mice::mice(md, m = m, method = meth, maxit = cfg$analysis$mi$maxit %||% 10,
                    seed = cfg$analysis$mi$seed, printFlag = FALSE)
  lv <- levels(d$TRT01P)
  k <- cfg$analysis$gh_nodes %||% 15

  per <- lapply(seq_len(m), function(i) {
    ci <- mice::complete(imp, i)
    dt <- d
    dt$AVAL <- if (is.null(derive)) as.numeric(as.character(ci[[target]])) else derive(ci, d)
    fit <- fit_bin(dt, c("TRT01P", "STEP", pc$terms))
    gc <- gcomp_bin(fit, dt, "TRT01P", k)
    dplyr::bind_cols(contrast_bin(gc, lv[1], lv[2]),
                     tibble::tibble(ev_ref = sum(dt$AVAL[dt$TRT01P == lv[1]]),
                                    ev_int = sum(dt$AVAL[dt$TRT01P == lv[2]]),
                                    cluster_sd = gc$sigma))
  }) |> dplyr::bind_rows()

  # (local names differ from the tibble columns: tibble() evaluates its
  # arguments sequentially, so `rd` would refer to the new column)
  z <- stats::qnorm(0.975)
  rd_c <- rubin(per$rd, per$rd_se^2)
  lr_c <- rubin(per$lrr, per$lrr_se^2)
  tibble::tibble(
    contrast = paste(lv[2], "vs", lv[1]),
    model = sprintf("GLMM (logit), random cluster; MI (m = %d)", m),
    n = nrow(d), n_ref = sum(d$TRT01P == lv[1]), n_int = sum(d$TRT01P == lv[2]),
    ev_ref = mean(per$ev_ref), ev_int = mean(per$ev_int),
    n_miss = sum(is.na(d[[target]])),
    risk_ref = mean(per$risk_ref), risk_int = mean(per$risk_int),
    rd = rd_c[["est"]], rd_se = rd_c[["se"]],
    rd_lcl = rd_c[["est"]] - z * rd_c[["se"]], rd_ucl = rd_c[["est"]] + z * rd_c[["se"]],
    lrr = lr_c[["est"]], lrr_se = lr_c[["se"]], rr = exp(lr_c[["est"]]),
    rr_lcl = exp(lr_c[["est"]] - z * lr_c[["se"]]),
    rr_ucl = exp(lr_c[["est"]] + z * lr_c[["se"]]),
    cluster_sd = mean(per$cluster_sd), note = ""
  )
}
