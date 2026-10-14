# test-make_lc.R — the labour-curve model and the multiple imputation of the
# time of reaching the time origin (make_lc.R) on simulated labours.

here::i_am("tests/testthat/test-make_lc.R")
source(here::here("R", "make_rd", "rd_helpers.R"))
source(here::here("R", "make_rd", "make_lc.R"))
source(here::here("R", "external", "functions.R"))

arms <- c("WHO partograph", "LCG")
test_cfg <- list(analysis = list(covariates = list(), gh_nodes = 15,
                                 mi = list(seed = 1, m_t0 = 3),
                                 tte = list(origin_cm = 4)))

# Woman i reaches k cm tau_i(k) = exp(a_i + delta * LCG + c * (10 - k)) hours
# before delivery; each woman is examined at a random subset of 2-10 cm.
sim_labours <- function(n = 1500, delta = log(1.2), c = 0.35, seed = 7) {
  withr::with_seed(seed, {
    women <- tibble::tibble(
      USUBJID = sprintf("W%05d", seq_len(n)),
      SITEID = sprintf("S%02d", sample(1:6, n, TRUE)),
      STEP = factor(sample(1:12, n, TRUE), levels = 1:12),
      TRT01P = factor(sample(arms, n, TRUE), levels = arms),
      VDSFL = "Y", a = stats::rnorm(n, -0.8, 0.4)
    )
    ex <- purrr::map(seq_len(n), function(i) {
      k <- sort(sample(2:10, sample(2:5, 1)))
      tibble::tibble(USUBJID = women$USUBJID[i], CMN = k,
                     AVAL = exp(women$a[i] + delta * (women$TRT01P[i] == arms[2]) +
                                  c * (10 - k) + stats::rnorm(length(k), 0, 0.2)),
                     ANL01FL = "Y")
    }) |> dplyr::bind_rows()
    list(adsl = dplyr::select(women, -a), adlp = ex,
         true4 = exp(women$a + delta * (women$TRT01P == arms[2]) + c * 6))
  })
}

test_that("rtnorm stays inside its bounds, including far-tail intervals", {
  withr::local_seed(1)
  x <- rtnorm(rep(0, 500), 1, 5, 6)
  expect_true(all(x >= 5 & x <= 6))
  y <- rtnorm(rep(0, 50), 1, 40, 41)          # zero mass in double precision
  expect_true(all(is.finite(y) & y >= 40 & y <= 41))
  z <- rtnorm(rep(0, 50), 1, -Inf, Inf)
  expect_true(all(is.finite(z)))
})

test_that("labour-curve model and the 4 cm imputation keep observed times and brackets", {
  s <- sim_labours()
  lc <- fit_lc(s$adlp, s$adsl, test_cfg)
  expect_equal(lc$n_women, nrow(s$adsl))

  imp <- impute_t0(lc, s$adlp, test_cfg)
  expect_equal(nrow(imp), nrow(s$adsl) * 3)
  expect_named(imp, c("USUBJID", "IMPN", "T0", "T0IMPFL"))
  # observed 4 cm times are kept
  obs <- s$adlp[s$adlp$CMN == 4, ]
  i1 <- imp[imp$IMPN == 1, ]
  expect_equal(i1$T0[match(obs$USUBJID, i1$USUBJID)], obs$AVAL)
  expect_setequal(i1$USUBJID[i1$T0IMPFL == "N"], obs$USUBJID)
  # imputed times respect the bracket: at least the time of the first exam at
  # >= 4 cm, at most that of the last exam below 4 cm
  br <- s$adlp |>
    dplyr::summarise(lw = if (any(CMN >= 4)) max(AVAL[CMN >= 4]) else 0,
                     up = if (any(CMN < 4)) min(AVAL[CMN < 4]) else Inf, .by = USUBJID)
  chk <- dplyr::inner_join(i1[i1$T0IMPFL == "Y", ], br, by = "USUBJID")
  expect_true(all(chk$T0 >= chk$lw - 1e-8))
  ok <- chk$up > chk$lw
  expect_true(all(chk$T0[ok] <= chk$up[ok] + 1e-8))
  # imputed values track the true 4 cm times
  tr <- s$true4[match(chk$USUBJID, s$adsl$USUBJID)]
  expect_gt(stats::cor(log(chk$T0), log(tr)), 0.8)
  # another origin (5 cm) works through the argument
  imp5 <- impute_t0(lc, s$adlp, test_cfg, k = 5)
  o5 <- s$adlp[s$adlp$CMN == 5, ]
  j1 <- imp5[imp5$IMPN == 1, ]
  expect_equal(j1$T0[match(o5$USUBJID, j1$USUBJID)], o5$AVAL)
})
