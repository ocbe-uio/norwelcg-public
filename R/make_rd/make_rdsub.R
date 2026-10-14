# make_rdsub.R — exploratory subgroup analysis of the primary endpoint by Robson
# group (SAP 8.2; item 62). The primary GLMM (PAS, all CS from 4 cm;
# binomial, logit, random cluster intercept, time interval, SAP 4.1.3
# covariates) with a treatment x Robson group interaction; the absolute risk
# difference within each group by G-computation over the women of that group
# (delta method, as rd_helpers.R); heterogeneity by a likelihood-ratio test of
# the interaction. Robson groups with fewer than
# cfg$analysis$subgroup$min_events intrapartum CS in the analysis set (both
# periods together, i.e. known before unblinding) are combined into one group.
# Exploratory: no multiplicity adjustment, no NI conclusion within subgroups.

make_rdsub <- function(adeff, cfg) {
  min_ev <- cfg$analysis$subgroup$min_events %||% 50
  dt <- adeff |>
    dplyr::filter(PARAMCD == "ICS", PASFL == "Y",
                  !is.na(AVAL), !is.na(TRT01P), !is.na(STEP)) |>
    dplyr::mutate(TRT01P = droplevels(TRT01P), STEP = droplevels(STEP),
                  SITEID = factor(SITEID))
  lv <- levels(dt$TRT01P)

  rob <- dplyr::coalesce(as.character(dt$ROBSON), "(missing)")
  ev <- tapply(dt$AVAL, rob, sum)
  small <- names(ev)[ev < min_ev]
  comb <- "Combined small groups"
  grp <- ifelse(rob %in% small, comb, rob)
  # Robson groups in numeric order, then the combined group and missing
  num <- suppressWarnings(readr::parse_number(unique(grp)))
  ord <- unique(grp)[order(is.na(num), num, unique(grp) == "(missing)")]
  dt$RGRP <- factor(grp, levels = ord)

  # Robson enters as the grouped factor, so only the continuous covariates here
  cfg_c <- cfg
  cfg_c$analysis$covariates$categorical <- NULL
  pc <- prep_covars(dt, cfg_c)
  dt <- pc$data
  fit0 <- fit_bin(dt, c("TRT01P", "RGRP", "STEP", pc$terms))
  fit1 <- fit_bin(dt, c("TRT01P * RGRP", "STEP", pc$terms))
  lrt <- stats::anova(fit0, fit1)
  p_int <- lrt[["Pr(>Chisq)"]][2]
  notes <- c(unlist(fit1@optinfo$conv$lme4$messages),
             if (lme4::isSingular(fit1)) "singular fit")

  k <- cfg$analysis$gh_nodes %||% 15
  rdsub <- dplyr::bind_rows(lapply(levels(dt$RGRP), function(g) {
    dg <- dt[dt$RGRP == g, ]
    cnt <- tibble::tibble(
      group = g,
      groups_combined = if (g == comb) paste(sort(small), collapse = "; ") else "",
      n = nrow(dg), n_ref = sum(dg$TRT01P == lv[1]), n_int = sum(dg$TRT01P == lv[2]),
      ev_ref = sum(dg$AVAL[dg$TRT01P == lv[1]]), ev_int = sum(dg$AVAL[dg$TRT01P == lv[2]])
    )
    if (min(cnt$n_ref, cnt$n_int) == 0) return(cnt)
    dplyr::bind_cols(cnt, contrast_bin(gcomp_bin(fit1, dg, "TRT01P", k), lv[1], lv[2]))
  })) |>
    dplyr::mutate(PARAMCD = "ICS", PARAM = "Intrapartum caesarean section",
                  analysis = "SUBGROUP ROBSON", population = "PAS, principal stratum",
                  model = "GLMM (logit), random cluster; treatment x Robson group",
                  p_interaction = p_int, min_events = min_ev,
                  note = paste(notes, collapse = "; "), .before = 1)

  fs::dir_create(path_rd())
  readr::write_rds(rdsub, path_rd("rdsub.rds"))
  rdsub
}
