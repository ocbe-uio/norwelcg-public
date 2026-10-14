# make_rdtte.R — time from 4 cm cervical dilatation to vaginal delivery (SAP
# 5.1.1.5-5.1.1.7 v0.9; items 60, 62), per imputed dataset of the time of reaching
# 4 cm (impute_t0()).
#
# Analysis set: the PAS (all caesarean sections from 4 cm, as the primary). With T = hours from 4 cm to
# delivery (first baby) and H the horizon (36 h), the analysis variable is
# Y = min(T, H) after a vaginal delivery and Y = H after a caesarean section;
# mean(Y) is the restricted mean time without vaginal delivery (H minus the
# area under the cumulative incidence curve of vaginal delivery up to H). A CS
# needs no time zero, so only the vaginal deliveries carry an imputed T.
#
#   SECONDARY   linear mixed model (lme4, REML): random cluster intercept,
#               treatment, time interval, SAP 4.1.3 covariates; with the
#               identity link the treatment coefficient is the marginal
#               difference in mean Y
#   SENS1       unadjusted: treatment, time interval, random cluster
#   SENS2       hospital as a fixed effect, HC3 standard errors (lm)
#   SUPP        horizons cfg$analysis$tte$supp_horizons (24, 48 h)
#   COMPONENT   difference in P(vaginal delivery) (binomial GLMM +
#               G-computation; minus the CS difference of the primary
#               analysis); difference in mean min(T, H)
#               among vaginal deliveries (VDS, same LMM)
#   SUPPORTIVE  vaginal delivery within h hours of 4 cm (supportive_hours),
#               binomial GLMM + G-computation as the dichotomous endpoints
# Per imputation the estimate and its model-based (SENS2: HC3) variance;
# combined by Rubin's rules. $cif: the descriptive cumulative incidence of
# vaginal delivery by hours since 4 cm and arm (empirical, i.e. Aalen-Johansen
# without censoring), on a 1-minute grid, averaged over the imputations (not
# adjusted for time interval); drawn as a step function.

make_rdtte <- function(imp0, adeff, cfg) {
  tte <- cfg$analysis$tte
  H <- tte$horizon %||% 36
  k0 <- tte$origin_cm %||% 4
  hz <- unlist(tte$supp_horizons %||% c(24, 48))
  hs <- unlist(tte$supportive_hours %||% c(6, 12))
  gk <- cfg$analysis$gh_nodes %||% 15

  d0 <- adeff |>
    dplyr::filter(PARAMCD == "ICS", PASFL == "Y", !is.na(TRT01P), !is.na(STEP)) |>
    dplyr::mutate(VD = MODE %in% c("SVD", "IVD"),
                  TRT01P = droplevels(TRT01P), STEP = droplevels(STEP),
                  SITEID = factor(SITEID))
  pc <- prep_covars(d0, cfg)
  d <- pc$data
  lv <- levels(d$TRT01P)
  M <- max(imp0$IMPN)
  z <- stats::qnorm(0.975)

  # linear model for response `resp`: treatment estimate, its variance and the
  # mean fixed-part prediction under each arm
  fit_lin <- function(dt, resp, terms, random = TRUE) {
    if (random) {
      fit <- lme4::lmer(stats::reformulate(c("TRT01P", "STEP", terms, "(1 | SITEID)"),
                                           response = resp),
                        data = dt, REML = TRUE,
                        control = lme4::lmerControl(calc.derivs = FALSE))
      b <- lme4::fixef(fit)
      V <- as.matrix(stats::vcov(fit))
      X <- lme4::getME(fit, "X")
      note <- if (lme4::isSingular(fit)) "singular fit" else ""
    } else {
      fit <- stats::lm(stats::reformulate(c("TRT01P", "STEP", "SITEID", terms),
                                          response = resp), data = dt)
      b <- stats::coef(fit)
      b <- b[!is.na(b)]
      V <- hc3_vcov(fit)
      X <- stats::model.matrix(fit)[, names(b), drop = FALSE]
      note <- ""
    }
    trt <- grep("^TRT01P", names(b), value = TRUE)
    m_ref <- mean(X[, colnames(X) != trt, drop = FALSE] %*% b[names(b) != trt])
    c(q = b[[trt]], u = V[trt, trt], m_ref = m_ref, m_int = m_ref + b[[trt]],
      singular = note == "singular fit")
  }
  # binomial GLMM + G-computation: RD and log RR with their variances
  fit_rd <- function(dt) {
    fit <- fit_bin(dt, c("TRT01P", "STEP", pc$terms))
    cb <- contrast_bin(gcomp_bin(fit, dt, "TRT01P", gk), lv[1], lv[2])
    c(q = cb$rd, u = cb$rd_se^2, m_ref = cb$risk_ref, m_int = cb$risk_int,
      singular = lme4::isSingular(fit))
  }

  runs <- list(
    list(id = "SECONDARY", h = H, terms = pc$terms, random = TRUE),
    list(id = "SENS1 UNADJUSTED", h = H, terms = character(), random = TRUE),
    list(id = "SENS2 FIXED CLUSTER, HC3", h = H, terms = pc$terms, random = FALSE)
  )
  runs <- c(runs, lapply(hz, function(h) {
    list(id = sprintf("SUPP HORIZON %d H", h), h = h, terms = pc$terms, random = TRUE)
  }))

  grid <- seq(0, H, by = (tte$cif_step_min %||% 1) / 60)   # minutes -> hours
  per <- lapply(seq_len(M), function(j) {
    ij <- imp0[imp0$IMPN == j, ]
    dj <- d
    dj$T <- ij$T0[match(dj$USUBJID, ij$USUBJID)]
    dj <- dj[!dj$VD | !is.na(dj$T), ]       # a vaginal delivery needs a time zero
    for (r in runs) dj[[paste0("Y_", r$h)]] <- ifelse(dj$VD, pmin(dj$T, r$h), r$h)
    main <- lapply(runs, function(r) fit_lin(dj, paste0("Y_", r$h), r$terms, r$random))
    names(main) <- vapply(runs, `[[`, "", "id")
    vd <- dj[dj$VD, ]
    vd$Y_vd <- pmin(vd$T, H)
    comp <- fit_lin(vd, "Y_vd", pc$terms)
    sup <- lapply(hs, function(h) {
      dh <- dj
      dh$AVAL <- as.numeric(dh$VD & dh$T <= h)
      fit_rd(dh)
    })
    names(sup) <- sprintf("VD within %g h", hs)
    cif <- vapply(lv, function(a) {
      ta <- sort(dj$T[dj$TRT01P == a & dj$VD])
      findInterval(grid, ta) / sum(dj$TRT01P == a)
    }, numeric(length(grid)))
    list(fits = c(main, list(COMPONENT_VDS = comp), sup), cif = cif, n = nrow(dj))
  })

  pool <- function(nm) {
    x <- do.call(rbind, lapply(per, function(p) p$fits[[nm]]))
    r <- rubin(x[, "q"], x[, "u"])
    tibble::tibble(est_ref = mean(x[, "m_ref"]), est_int = mean(x[, "m_int"]),
                   estimate = r[["est"]], se = r[["se"]],
                   lcl = r[["est"]] - z * r[["se"]], ucl = r[["est"]] + z * r[["se"]],
                   note = if (any(x[, "singular"] == 1)) "singular fit" else "")
  }
  lab_h <- function(h) sprintf("Restricted mean time without vaginal delivery, first %g h (difference, h)", h)
  rows <- list(
    dplyr::mutate(pool("SECONDARY"), measure = lab_h(H), analysis = "SECONDARY",
                  horizon = H, unit = "hours",
                  model = "LMM, random cluster; covariates"),
    dplyr::mutate(pool("SENS1 UNADJUSTED"), measure = lab_h(H), analysis = "SENS1 UNADJUSTED",
                  horizon = H, unit = "hours", model = "LMM, random cluster; unadjusted"),
    dplyr::mutate(pool("SENS2 FIXED CLUSTER, HC3"), measure = lab_h(H),
                  analysis = "SENS2 FIXED CLUSTER, HC3", horizon = H, unit = "hours",
                  model = "Linear model, hospital fixed; HC3 standard errors")
  )
  rows <- c(rows, lapply(hz, function(h) {
    dplyr::mutate(pool(sprintf("SUPP HORIZON %d H", h)), measure = lab_h(h),
                  analysis = "SUPPLEMENTARY", horizon = h, unit = "hours",
                  model = "LMM, random cluster; covariates")
  }))

  # component: P(vaginal delivery), no imputation involved
  pvd <- analyse_bin(dplyr::mutate(d0, AVAL = as.numeric(VD)), cfg)
  rows <- c(rows, list(
    tibble::tibble(est_ref = pvd$risk_ref, est_int = pvd$risk_int, estimate = pvd$rd,
                   se = pvd$rd_se, lcl = pvd$rd_lcl, ucl = pvd$rd_ucl, note = pvd$note,
                   measure = "Probability of vaginal delivery (difference)",
                   analysis = "COMPONENT", horizon = NA_real_, unit = "proportion",
                   model = "GLMM (logit), random cluster; G-computation"),
    dplyr::mutate(pool("COMPONENT_VDS"),
                  measure = sprintf("Mean of min(T, %g h) among vaginal deliveries (difference, h)", H),
                  analysis = "COMPONENT", horizon = H, unit = "hours",
                  model = "LMM, random cluster; covariates; VDS")
  ))
  rows <- c(rows, lapply(hs, function(h) {
    dplyr::mutate(pool(sprintf("VD within %g h", h)),
                  measure = sprintf("Vaginal delivery within %g h of %g cm (difference)", h, k0),
                  analysis = "SUPPORTIVE", horizon = h, unit = "proportion",
                  model = "GLMM (logit), random cluster; G-computation")
  }))

  vd_n <- sum(d$VD)
  results <- dplyr::bind_rows(rows) |>
    dplyr::mutate(
      PARAMCD = "TT4VD",
      PARAM = sprintf("Time from %g cm cervical dilatation to vaginal delivery", k0),
      population = dplyr::if_else(grepl("VDS", model), "VDS", "PAS"),
      n = dplyr::if_else(population == "VDS", vd_n, per[[1]]$n),
      n_ref = dplyr::if_else(population == "VDS", sum(d$VD & d$TRT01P == lv[1]),
                             sum(d$TRT01P == lv[1])),
      n_int = dplyr::if_else(population == "VDS", sum(d$VD & d$TRT01P == lv[2]),
                             sum(d$TRT01P == lv[2])),
      n_vd = vd_n,
      n_t0_imputed = sum(imp0$T0IMPFL[imp0$IMPN == 1 & imp0$USUBJID %in% d$USUBJID[d$VD]] == "Y"),
      m = M,
      .before = 1
    ) |>
    dplyr::relocate(measure, analysis, .after = PARAM)

  cif <- Reduce(`+`, lapply(per, `[[`, "cif")) / M
  cif <- tibble::tibble(hours = rep(grid, length(lv)),
                        TRT01P = factor(rep(lv, each = length(grid)), levels = lv),
                        cif = as.vector(cif))

  rdtte <- list(results = results, cif = cif)
  fs::dir_create(path_rd())
  readr::write_rds(rdtte, path_rd("rdtte.rds"))
  rdtte
}
