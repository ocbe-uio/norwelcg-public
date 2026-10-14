# rd_helpers.R — shared helpers for the analysis layer (SAP 4.1.2, 4.1.3):
# covariate preparation, binomial (G)LMM, G-computation integrating over the
# random cluster effect, non-inferiority / superiority tests, Rubin's rules.

# Covariates (SAP 4.1.3): categorical ones get a "(missing)" level; continuous
# ones are median-imputed, entered as restricted cubic splines with 3 knots at
# the 10th/50th/90th percentiles of the observed values (natural cubic spline,
# linear beyond the outer knots, 2 df), plus a missing indicator where at least
# `covariates$min_indicator` values are missing (default 10) — an indicator for
# a handful of women is not estimable (it made ordinal::clmm singular), so
# below that the median alone is used. Returns the data with the design columns
# added and their names. adjust = FALSE -> no covariates (sensitivity 1).
prep_covars <- function(dt, cfg, adjust = TRUE) {
  cv <- cfg$analysis$covariates
  if (!adjust || length(cv) == 0) return(list(data = dt, terms = character()))
  min_ind <- cv$min_indicator %||% 10
  terms <- character()
  for (v in unlist(cv$categorical)) {
    x <- as.character(dt[[v]])
    x[is.na(x)] <- "(missing)"
    nm <- paste0("C_", v)
    dt[[nm]] <- factor(x)
    if (nlevels(dt[[nm]]) > 1) terms <- c(terms, nm)
  }
  for (v in unlist(cv$continuous)) {
    x <- as.numeric(dt[[v]])
    miss <- is.na(x)
    q <- stats::quantile(x[!miss], c(0.1, 0.5, 0.9), names = FALSE)
    x[miss] <- q[2]
    b <- splines::ns(x, knots = q[2], Boundary.knots = q[c(1, 3)])
    for (j in seq_len(ncol(b))) {
      nm <- sprintf("S_%s_%d", v, j)
      dt[[nm]] <- as.numeric(b[, j])
      terms <- c(terms, nm)
    }
    if (sum(miss) >= min_ind) {
      nm <- paste0("M_", v)
      dt[[nm]] <- as.integer(miss)
      terms <- c(terms, nm)
    }
  }
  list(data = dt, terms = terms)
}

# Drop numeric covariate columns that are linearly dependent on earlier ones
# (e.g. two missing indicators with the same pattern). glmer/lmer/survreg drop
# aliased columns themselves; ordinal::clmm does not, and its Hessian is then
# singular. Sparse indicators are handled in prep_covars().
drop_aliased <- function(dt, terms) {
  num <- terms[startsWith(terms, "S_") | startsWith(terms, "M_")]
  if (length(num) == 0) return(terms)
  X <- cbind(1, as.matrix(as.data.frame(dt)[, num, drop = FALSE]))
  q <- qr(X)
  if (q$rank == ncol(X)) return(terms)
  aliased <- num[setdiff(seq_len(ncol(X)), q$pivot[seq_len(q$rank)]) - 1]
  setdiff(terms, aliased)
}

# Binomial GLMM (logit) with a random intercept for cluster, or a GLM with the
# cluster as a fixed effect (random = FALSE; `rhs` must then include SITEID).
fit_bin <- function(dt, rhs, random = TRUE) {
  if (random) {
    form <- stats::reformulate(c(rhs, "(1 | SITEID)"), response = "AVAL")
    lme4::glmer(form, data = dt, family = stats::binomial("logit"),
                control = lme4::glmerControl(optimizer = "bobyqa",
                                             calc.derivs = FALSE,
                                             optCtrl = list(maxfun = 2e5)))
  } else {
    stats::glm(stats::reformulate(rhs, response = "AVAL"), data = dt,
               family = stats::binomial("logit"))
  }
}

# fixed-effects part of a mixed-model formula (nobars moved from lme4 to
# reformulas; use reformulas when installed)
nobars_ <- function(f) {
  if (requireNamespace("reformulas", quietly = TRUE)) reformulas::nobars(f) else lme4::nobars(f)
}

# Gauss-Hermite rule (Golub-Welsch) for integrals against exp(-x^2).
gh_rule <- function(k = 15) {
  i <- seq_len(k - 1)
  J <- matrix(0, k, k)
  J[cbind(i, i + 1)] <- J[cbind(i + 1, i)] <- sqrt(i / 2)
  e <- eigen(J, symmetric = TRUE)
  list(x = e$values, w = sqrt(pi) * e$vectors[1, ]^2)
}

# Marginal (population-averaged) risk under each level of `trt` by
# G-computation over the rows of `dt` (SAP 4.1.2): each woman's probability is
# predicted with her own covariates and time interval and integrated over the
# random cluster effect N(0, sigma^2) by Gauss-Hermite quadrature (sigma = 0
# for a fixed-cluster GLM), then averaged. Gradients w.r.t. the fixed effects
# give delta-method standard errors; sigma is treated as known.
gcomp_bin <- function(fit, dt, trt = "TRT01P", k = 15) {
  is_mer <- inherits(fit, "merMod")
  beta <- if (is_mer) lme4::fixef(fit) else stats::coef(fit)
  beta <- beta[!is.na(beta)]
  V <- as.matrix(stats::vcov(fit))[names(beta), names(beta)]
  form <- if (is_mer) nobars_(stats::formula(fit)) else stats::formula(fit)
  tt <- stats::delete.response(stats::terms(form))
  fvars <- intersect(all.vars(tt), names(dt)[vapply(dt, is.factor, logical(1))])
  xlev <- lapply(dt[fvars], levels)
  sigma <- if (is_mer) sqrt(unlist(lme4::VarCorr(fit))[[1]]) else 0
  g <- gh_rule(k)
  nodes <- sqrt(2) * sigma * g$x
  wts <- g$w / sqrt(pi)
  res <- lapply(levels(dt[[trt]]), function(a) {
    nd <- dt
    nd[[trt]] <- factor(a, levels = levels(dt[[trt]]))
    X <- stats::model.matrix(tt, stats::model.frame(tt, nd, xlev = xlev))
    X <- X[, names(beta), drop = FALSE]
    P <- stats::plogis(outer(drop(X %*% beta), nodes, "+"))
    list(risk = mean(P %*% wts),
         grad = colMeans(X * drop((P * (1 - P)) %*% wts)))
  })
  names(res) <- levels(dt[[trt]])
  list(res = res, V = V, sigma = sigma)
}

# Absolute (RD) and relative (log RR) difference, int vs ref, delta method.
contrast_bin <- function(gc, ref, int) {
  r0 <- gc$res[[ref]]
  r1 <- gc$res[[int]]
  z <- stats::qnorm(0.975)
  g_rd <- r1$grad - r0$grad
  g_lr <- r1$grad / r1$risk - r0$grad / r0$risk
  rd <- r1$risk - r0$risk
  rd_se <- sqrt(drop(t(g_rd) %*% gc$V %*% g_rd))
  lrr <- log(r1$risk / r0$risk)
  lrr_se <- sqrt(drop(t(g_lr) %*% gc$V %*% g_lr))
  tibble::tibble(
    risk_ref = r0$risk, risk_int = r1$risk,
    rd = rd, rd_se = rd_se, rd_lcl = rd - z * rd_se, rd_ucl = rd + z * rd_se,
    lrr = lrr, lrr_se = lrr_se,
    rr = exp(lrr), rr_lcl = exp(lrr - z * lrr_se), rr_ucl = exp(lrr + z * lrr_se)
  )
}

# Non-inferiority (H0: RD >= margin) and superiority (H0: RD >= 0), one-sided
# p-values; conclusions from the two-sided 95% CI in a fixed sequence (SAP 2.1).
ni_tests <- function(rd, rd_se, margin) {
  ucl <- rd + stats::qnorm(0.975) * rd_se
  tibble::tibble(
    ni_margin = margin,
    p_ni  = stats::pnorm((rd - margin) / rd_se),
    p_sup = stats::pnorm(rd / rd_se),
    ni_concl  = ucl < margin,
    sup_concl = ucl < margin & ucl < 0
  )
}

# Heteroscedasticity-consistent (HC3) covariance of an lm fit (MacKinnon and
# White 1985), without the sandwich package: (X'X)^-1 X' diag(e_i^2 /
# (1 - h_i)^2) X (X'X)^-1, over the estimable (non-aliased) coefficients.
hc3_vcov <- function(fit) {
  b <- stats::coef(fit)
  X <- stats::model.matrix(fit)[, !is.na(b), drop = FALSE]
  e <- stats::residuals(fit) / (1 - stats::hatvalues(fit))
  bread <- solve(crossprod(X))
  V <- bread %*% crossprod(X * e) %*% bread
  dimnames(V) <- list(colnames(X), colnames(X))
  V
}

# Rubin's rules for a scalar estimate: q, u = per-imputation estimates and
# squared standard errors.
rubin <- function(q, u) {
  m <- length(q)
  t <- mean(u) + (1 + 1 / m) * stats::var(q)
  c(est = mean(q), se = sqrt(t))
}

# One dichotomous analysis: complete-case rows of `dt` (AVAL 0/1), treatment
# variable `trt`, one row per contrast (list of c(ref, int) level pairs; by
# default the two TRT01P levels). ni = TRUE adds the NI/superiority tests.
analyse_bin <- function(dt, cfg, trt = "TRT01P", contrasts = NULL,
                        adjust = TRUE, random = TRUE, ni = FALSE) {
  dt <- dt[!is.na(dt$AVAL) & !is.na(dt[[trt]]) & !is.na(dt$STEP), , drop = FALSE]
  dt[[trt]] <- droplevels(factor(dt[[trt]]))
  dt$STEP <- droplevels(dt$STEP)
  dt$SITEID <- factor(dt$SITEID)
  pc <- prep_covars(dt, cfg, adjust)
  dt <- pc$data
  lv <- levels(dt[[trt]])
  contrasts <- contrasts %||% list(lv[1:2])
  model <- if (random) "GLMM (logit), random cluster" else "GLM (logit), fixed cluster"

  counts <- function(cc) {
    tibble::tibble(
      contrast = paste(cc[2], "vs", cc[1]), model = model,
      n = nrow(dt),
      n_ref = sum(dt[[trt]] == cc[1]), n_int = sum(dt[[trt]] == cc[2]),
      ev_ref = sum(dt$AVAL[dt[[trt]] == cc[1]]),
      ev_int = sum(dt$AVAL[dt[[trt]] == cc[2]])
    )
  }
  fit <- tryCatch(
    fit_bin(dt, c(trt, "STEP", pc$terms, if (!random) "SITEID"), random),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(dplyr::bind_rows(lapply(contrasts, function(cc) {
      counts(cc) |> dplyr::mutate(note = paste("model failed:", conditionMessage(fit)))
    })))
  }
  notes <- character()
  if (inherits(fit, "merMod")) {
    notes <- unlist(fit@optinfo$conv$lme4$messages)
    if (lme4::isSingular(fit)) notes <- c(notes, "singular fit")
  }
  gc <- gcomp_bin(fit, dt, trt, k = cfg$analysis$gh_nodes %||% 15)
  out <- dplyr::bind_rows(lapply(contrasts, function(cc) {
    dplyr::bind_cols(counts(cc), contrast_bin(gc, cc[1], cc[2]))
  })) |>
    dplyr::mutate(cluster_sd = gc$sigma, note = paste(notes, collapse = "; "))
  if (ni) out <- dplyr::bind_cols(out, ni_tests(out$rd, out$rd_se, cfg$analysis$ni_margin))
  out
}
