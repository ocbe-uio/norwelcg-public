# make_rdtear.R — degree of perineal tear (SAP v0.85 §5.1.1.5; not used from v0.9): proportional-odds
# (cumulative logit) GLMM with a random intercept for cluster and fixed
# effects for treatment, time interval and the SAP 4.1.3 covariates
# (ordinal::clmm), complete case.
#
#   TEAR   vaginal delivery set                      (secondary)
#   TEARC  PAS, CS = no tear                         (supplementary, composite)
#
# Common cumulative odds ratio (odds of a higher grade, LCG vs WHO) with a
# Wald 95% CI; marginal probability of each grade by treatment by
# G-computation integrating over the random cluster effect; absolute
# difference in the probability of a third- or fourth-degree tear (OASIS),
# delta method over the threshold and fixed effects.

make_rdtear <- function(adeff, cfg) {
  runs <- list(
    list(p = "TEAR", analysis = "SECONDARY", population = "VDS",
         dt = adeff[adeff$PARAMCD == "TEAR" & adeff$VDSFL == "Y", ]),
    list(p = "TEARC", analysis = "SUPPLEMENTARY", population = "PAS",
         dt = adeff[adeff$PARAMCD == "TEARC" & adeff$PASFL == "Y", ])
  )
  rdtear <- dplyr::bind_rows(lapply(runs, function(r) {
    analyse_ord(r$dt, cfg) |>
      dplyr::mutate(PARAMCD = r$p, PARAM = r$dt$PARAM[1], analysis = r$analysis,
                    population = r$population, .before = 1)
  }))
  fs::dir_create(path_rd())
  readr::write_rds(rdtear, path_rd("rdtear.rds"))
  rdtear
}

analyse_ord <- function(dt, cfg, k_oasis = 3) {
  dt <- dt[!is.na(dt$AVAL) & !is.na(dt$TRT01P) & !is.na(dt$STEP), , drop = FALSE]
  dt$TRT01P <- droplevels(dt$TRT01P)
  dt$STEP <- droplevels(dt$STEP)
  dt$SITEID <- factor(dt$SITEID)
  dt$Y <- factor(dt$AVAL, levels = sort(unique(dt$AVAL)), ordered = TRUE)
  pc <- prep_covars(dt, cfg)
  dt <- pc$data
  pc$terms <- drop_aliased(dt, pc$terms)       # clmm does not drop aliased columns
  lv <- levels(dt$TRT01P)
  form <- stats::reformulate(c("TRT01P", "STEP", pc$terms, "(1 | SITEID)"), response = "Y")
  fit <- tryCatch(ordinal::clmm(form, data = dt, link = "logit", Hess = TRUE),
                  error = function(e) e)
  base <- tibble::tibble(model = "Proportional-odds GLMM (ordinal::clmm)",
                         n = nrow(dt), n_ref = sum(dt$TRT01P == lv[1]),
                         n_int = sum(dt$TRT01P == lv[2]))
  if (inherits(fit, "error")) {
    return(dplyr::mutate(base, note = paste("model failed:", conditionMessage(fit))))
  }
  alpha <- fit$alpha
  beta <- fit$beta
  # vcov() fails when the Hessian is singular in the variance parameter (a
  # cluster SD at 0, as on the anonymised copy): fall back to the threshold +
  # fixed-effect block, i.e. the covariance with the cluster SD treated as
  # known (as in the G-computation of rd_helpers.R)
  note <- ""
  V <- tryCatch(as.matrix(stats::vcov(fit)), error = function(e) NULL)
  if (is.null(V)) {
    ab <- c(names(alpha), names(beta))
    V <- solve(fit$Hessian[seq_along(ab), seq_along(ab)])
    dimnames(V) <- list(ab, ab)
    note <- "vcov given the cluster SD (Hessian singular in the variance parameter)"
  }
  trt <- grep("^TRT01P", names(beta), value = TRUE)
  z <- stats::qnorm(0.975)
  or_se <- sqrt(V[trt, trt])

  # G-computation: P(Y <= j | x, u) = F(alpha_j - x'beta - u), u ~ N(0, sigma^2)
  sigma <- as.numeric(fit$ST[[1]])
  gh <- gh_rule(cfg$analysis$gh_nodes %||% 15)
  nodes <- sqrt(2) * sigma * gh$x
  wts <- gh$w / sqrt(pi)
  tt <- stats::delete.response(stats::terms(nobars_(form)))
  fvars <- intersect(all.vars(tt), names(dt)[vapply(dt, is.factor, logical(1))])
  cuts <- names(alpha)
  j_oasis <- which(cuts == paste0(k_oasis - 1, "|", k_oasis))   # P(Y <= 2)
  arm <- lapply(lv, function(a) {
    nd <- dt
    nd$TRT01P <- factor(a, levels = lv)
    X <- stats::model.matrix(tt, stats::model.frame(tt, nd, xlev = lapply(dt[fvars], levels)))
    X <- X[, names(beta), drop = FALSE]
    eta <- drop(X %*% beta)
    cum <- vapply(alpha, function(al) {
      mean(stats::plogis(outer(al - eta, nodes, "-")) %*% wts)
    }, numeric(1))
    Fo <- stats::plogis(outer(alpha[j_oasis] - eta, nodes, "-"))
    dF <- drop((Fo * (1 - Fo)) %*% wts)
    # gradient of P(Y >= k_oasis) = 1 - P(Y <= k_oasis - 1)
    g <- stats::setNames(numeric(nrow(V)), rownames(V))
    g[cuts[j_oasis]] <- -mean(dF)
    g[names(beta)] <- colMeans(X * dF)
    list(prob = unname(diff(c(0, cum, 1))), oasis = 1 - unname(cum[j_oasis]), grad = g)
  })
  g <- arm[[2]]$grad - arm[[1]]$grad
  rd <- arm[[2]]$oasis - arm[[1]]$oasis
  rd_se <- sqrt(drop(t(g) %*% V %*% g))
  probs <- stats::setNames(c(arm[[1]]$prob, arm[[2]]$prob),
                           c(paste0("p", levels(dt$Y), "_ref"), paste0("p", levels(dt$Y), "_int")))
  dplyr::bind_cols(
    base,
    tibble::tibble(
      or = exp(beta[[trt]]), or_lcl = exp(beta[[trt]] - z * or_se),
      or_ucl = exp(beta[[trt]] + z * or_se),
      oasis_ref = arm[[1]]$oasis, oasis_int = arm[[2]]$oasis,
      oasis_rd = rd, oasis_rd_se = rd_se,
      oasis_rd_lcl = rd - z * rd_se, oasis_rd_ucl = rd + z * rd_se,
      cluster_sd = sigma, note = note
    ),
    tibble::as_tibble(as.list(probs))
  )
}
