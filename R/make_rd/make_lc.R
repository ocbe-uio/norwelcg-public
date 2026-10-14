# make_lc.R — the labour-curve model and the multiple imputation of the time
# of reaching the time origin (4 cm cervical dilatation) for time to vaginal
# delivery (SAP 5.1.1.5). Labour progression is no longer analysed in this SAP
# (item 62); the model serves only the imputation.
#
# Model: for each cervical examination of a woman in the vaginal delivery set,
#   log(hours from the examination to delivery) = natural cubic spline of the
#   dilatation found (3 df) x treatment + time interval + hospital (fixed) +
#   SAP 4.1.3 covariates + random intercept and slope on dilatation per woman
# (lme4), on examinations at >= 3 cm with 0 < time < 72 h (ADLP ANL01FL),
# with a single residual variance (SAP; item 43). Time is measured backwards
# from delivery (Zhang et al. 2002, 2010).

fit_lc <- function(adlp, adsl, cfg) {
  covs <- c(unlist(cfg$analysis$covariates$categorical),
            unlist(cfg$analysis$covariates$continuous))
  women <- adsl |>
    dplyr::filter(VDSFL == "Y") |>
    dplyr::select(USUBJID, TRT01P, STEP, SITEID, dplyr::all_of(covs)) |>
    dplyr::mutate(TRT01P = droplevels(TRT01P), STEP = droplevels(STEP),
                  SITEID = factor(SITEID))
  pc <- prep_covars(women, cfg)
  women <- pc$data
  ex <- adlp |>
    dplyr::filter(ANL01FL == "Y", CMN >= 3, USUBJID %in% women$USUBJID) |>
    dplyr::select(USUBJID, CMN, AVAL) |>
    dplyr::inner_join(women, by = "USUBJID")
  # spline knots fixed in the formula, so predictions use the same basis
  kn <- stats::quantile(ex$CMN, c(1, 2) / 3, names = FALSE)
  spl <- sprintf("splines::ns(CMN, knots = c(%g, %g), Boundary.knots = c(3, 10))",
                 kn[1], kn[2])
  form <- stats::reformulate(
    c(paste(spl, "* TRT01P"), "STEP", "SITEID", pc$terms, "(1 + CMN | USUBJID)"),
    response = "log(AVAL)"
  )
  fit <- lme4::lmer(form, data = ex,
                    control = lme4::lmerControl(calc.derivs = FALSE))
  list(fit = fit, women = women, terms = pc$terms,
       n_women = dplyr::n_distinct(ex$USUBJID), n_exams = nrow(ex))
}

# tail-stable draw from N(mu, s^2) truncated to (lo, hi): reflect to the lower
# tail when the interval lies in the upper tail; zero-mass guard -> nearest bound
rtnorm <- function(mu, s, lo, hi) {
  a <- (lo - mu) / s
  b <- (hi - mu) / s
  up <- a > 0
  pa <- stats::pnorm(ifelse(up, -b, a))
  pb <- stats::pnorm(ifelse(up, -a, b))
  z <- stats::qnorm(pa + stats::runif(length(mu)) * (pb - pa))
  z[up] <- -z[up]
  bad <- !is.finite(z)
  z[bad] <- ifelse(up, a, b)[bad]
  mu + s * z
}

# Multiple imputation of the time from k cm (cfg$analysis$tte$origin_cm, 4)
# to delivery (SAP 5.1.1.5) for the vaginal delivery set. The examination at
# which k cm was found is used as observed; otherwise log(time) is drawn from
# the woman's predictive distribution at k cm (her own curve: fixed effects +
# her random-effect prediction, variance = residual + conditional random-effect
# variance), truncated to lie between her first examination at >= k cm and her
# last examination below k cm, with the fixed effects drawn anew for each
# imputed dataset. Returns one row per woman per imputation (IMPN, T0 = hours
# from reaching k cm to delivery, T0IMPFL).
impute_t0 <- function(lcfit, adlp, cfg, k = cfg$analysis$tte$origin_cm %||% 4) {
  fit <- lcfit$fit
  w <- lcfit$women
  m <- cfg$analysis$mi$m_t0 %||% 30
  set.seed(cfg$analysis$mi$seed %||% 1)

  ex <- adlp |> dplyr::filter(ANL01FL == "Y", USUBJID %in% w$USUBJID)
  obsk <- ex |>
    dplyr::filter(CMN == k) |>
    dplyr::summarise(T0OBS = min(AVAL), .by = USUBJID)
  br <- ex |>
    dplyr::summarise(
      lw = if (any(CMN >= k)) max(AVAL[CMN >= k]) else 0,
      up = if (any(CMN < k)) min(AVAL[CMN < k]) else Inf,
      .by = USUBJID
    )
  w <- w |>
    dplyr::left_join(obsk, by = "USUBJID") |>
    dplyr::left_join(br, by = "USUBJID") |>
    dplyr::mutate(lw = dplyr::coalesce(lw, 0), up = dplyr::coalesce(up, Inf))
  imp <- is.na(w$T0OBS)
  nd <- w[imp, ]
  nd$CMN <- k

  mu <- stats::predict(fit, newdata = nd, re.form = NULL, allow.new.levels = TRUE)
  re <- lme4::ranef(fit, condVar = TRUE)$USUBJID
  pv <- attr(re, "postVar")
  xk <- c(1, k)
  prior <- drop(t(xk) %*% as.matrix(lme4::VarCorr(fit)$USUBJID) %*% xk)
  ix <- match(nd$USUBJID, rownames(re))
  cv <- vapply(ix, function(j) {
    if (is.na(j)) prior else drop(t(xk) %*% pv[, , j] %*% xk)
  }, numeric(1))
  s <- sqrt(stats::sigma(fit)^2 + cv)

  beta <- lme4::fixef(fit)
  tt <- stats::delete.response(stats::terms(nobars_(stats::formula(fit))))
  fvars <- intersect(all.vars(tt), names(nd)[vapply(nd, is.factor, logical(1))])
  Xk <- stats::model.matrix(tt, stats::model.frame(tt, nd, xlev = lapply(w[fvars], levels)))
  Xk <- Xk[, names(beta), drop = FALSE]
  bdraw <- MASS::mvrnorm(m, beta, as.matrix(stats::vcov(fit)))
  lo <- log(pmax(nd$lw, 1e-6))
  hi <- log(pmin(nd$up, 1e4))
  # inverted bracket (an exam below k cm recorded after one at >= k cm; review
  # items 13, 54(g)): keep the lower bound only
  hi[hi <= lo] <- log(1e4)

  dplyr::bind_rows(lapply(seq_len(m), function(j) {
    t0 <- w$T0OBS
    t0[imp] <- exp(rtnorm(mu + drop(Xk %*% (bdraw[j, ] - beta)), s, lo, hi))
    tibble::tibble(USUBJID = w$USUBJID, IMPN = j, T0 = t0,
                   T0IMPFL = dplyr::if_else(imp, "Y", "N"))
  }))
}
