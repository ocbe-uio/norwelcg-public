# NORWELCG — statistical analysis (pre-unblinding snapshot)

> **This is a frozen snapshot made after database lock and before unblinding.**
> The statistical analysis plan (SAP v1.0) was signed on 14 October 2026; the
> trial database was locked before that. The snapshot is built from the files of
> the private analysis repository at tag `pre-unblinding` (commit `4d4a1e4`,
> 14 October 2026). The final analyses are run from that tag; any change made
> after unblinding is documented separately and is not part of this snapshot.

**What is here**

- `docs/sap/NORWELCG SAP v1.0 2026-10-14 sign.pdf` — the signed SAP (the
  authoritative version); `sap_norwelcg.qmd` is its source, and
  `docs/sap/drafts/` holds the earlier drafts, the circulated versions and the
  investigators' returned comments.
- `docs/sap/sap_data_review.md` — the review log of all findings and decisions
  from checking the SAP against the data and the code, in order. Numerical
  "effects" quoted from development runs in this log come from an anonymised
  copy with a permuted treatment and carry no information about the trial
  result.
- The complete analysis code (`R/`, `_targets.R`, `config/`, `tests/`,
  `renv.lock`).
- `reports/` — the final mock-up statistical report (table shells). Its numbers
  were produced on the anonymised copy, in which treatment is randomly permuted;
  they are **not** trial results.
- `docs/data_anonymisation_specification.md` and `…_plan.md` — how the
  development copy was anonymised, including the deviation log (§14).
- `CLAUDE.md` — the working instructions for the AI coding assistant used in the
  development (see the AI statement in SAP §2.5).

**No participant data are included.** Compared with the tagged files, this
snapshot leaves out the codebooks of the export (they contain example values or
small counts from the trial data) and third-party or internal reference
documents (an institutional SOP and TransCelerate templates), and replaces two
example record keys by `INT-NNNNN` / `TRAN-NNNNN`. Added: `LICENSE`,
`CITATION.cff`, `.zenodo.json` and this notice.

**Licences.** Code: MIT. Documents: CC BY 4.0 (see `LICENSE`).
**Citation.** See `CITATION.cff`.

---


Analysis code for **NORWELCG**, the Norwegian WHO Labour Care Trial: a
stepped-wedge cluster-randomised trial of the WHO **Labour Care Guide (LCG)**
versus the **WHO partograph** in 10 Norwegian delivery units (ClinicalTrials.gov
NCT05791630). Inclusion 1 April 2025 – 26 May 2026, twelve 5-week steps.

- **Primary endpoint:** intrapartum caesarean section (all caesarean sections
  from 4 cm cervical dilatation), non-inferiority with a margin of +1.5
  percentage points on the absolute risk difference LCG − WHO partograph.
- **Model:** generalised linear mixed model with a random cluster effect and
  fixed effects for treatment, time interval and prognostic covariates;
  population-averaged risk differences by G-computation over the random
  cluster effect, delta-method standard errors.

The statistical analysis plan (SAP) is the source of truth for the analyses:
`docs/sap/sap_norwelcg.qmd`; the version sent for signature is
`docs/sap/NORWELCG SAP v1.0 2026-10-14.docx` (and `.pdf`), earlier drafts are in
`docs/sap/drafts/`. Findings and decisions from checking the SAP against the
data and the code are logged in `docs/sap/sap_data_review.md`.

## Pipeline

A [`targets`](https://docs.ropensci.org/targets/) pipeline (`_targets.R`):

```
data/raw  (anonymised rds | per-period .dta)     R/make_raw/
   -> ADaM: adsl, adeff, adlp                      R/make_ad/
   -> reporting datasets and models                R/make_rd/
   -> report                                       reports/statistical_analysis.qmd
```

There is no SDTM stage: the export is one row per woman. The export comes as one
Stata file per study period (control, transition, intervention); the files are
aligned by variable label in `read_norwel_raw()`.

```r
renv::restore()        # pinned packages (renv.lock)
targets::tar_make()    # full build, about 45 minutes
```

`config/cfg.yml` holds the study settings (arms, stepped-wedge calendar,
covariates, multiple-imputation settings, file paths). `mode: sham` during
development; `mode: true` only after database lock, in the secure environment.

## Development on anonymised data

Patient data stay in a secure environment without access to AI tools. The code
is developed on an anonymised copy, then moved to the secure environment and run
on the real data. Only code travels to the secure environment; only anonymised
data travel back.

```
SECURE:  raw .dta files --Rscript R/make_anon/run_anon.R--> data/raw/<export>_anon/   (moved out)
                                                            data/raw/anon_keys/        (never exported)
DEV:     develop pipeline, tests and mock-up report on the anonymised copy
SECURE:  updated code --> blinded checks / final analysis on the real data
```

The anonymised copy keeps the marginal distributions but breaks the links
between variables: treatment (study period) is permuted, timestamps are shifted
and record keys replaced, so it carries no treatment effect. See
`config/anon.yml`, `docs/data_anonymisation_specification.md` and
`docs/data_anonymisation_plan.md`.

Blinded scripts for the secure environment (no treatment comparison):
`R/blinded_review/cleaning_check.R`, `blinded_checks.R`, `covariate_check.R`
and `sap_numbers.R` (the pooled numbers quoted in the SAP); each takes `--anon`
to run on the anonymised copy.

## Layout

```
config/          cfg.yml (study settings), anon.yml (anonymiser)
metadata/        codebooks, codelists, hospitals and lookups (see metadata/README.md)
R/make_raw/      import of the per-period exports
R/make_anon/     anonymiser (secure environment only)
R/make_ad/       ADaM: adsl, adeff (endpoints), adlp (cervical examinations)
R/make_rd/       analyses: binary GLMM + G-computation, multiple imputation,
                 subgroup, time to vaginal delivery, descriptive summaries
R/blinded_review/ blinded data checks
R/helpers/, R/external/  shared utilities
docs/protocol/   protocol and eCRF
docs/sap/        SAP source, review log, data-cleaning rules, templates
reports/         mock-up statistical report
tests/testthat/  unit tests on synthetic fixtures
data/            raw exports and derived datasets (git-ignored)
```

## Tests

```r
testthat::test_dir("tests/testthat")
```

The anonymiser and the derivations are tested on synthetic fixtures that mimic
the structure of the export, not on the anonymised copy.

## Conventions

R with tidyverse style; configuration over hard-coding; no patient data, keys or
record keys in git. Working rules for this repository, including the
database-lock checklist, are in `CLAUDE.md`.
