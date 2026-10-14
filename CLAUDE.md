# CLAUDE.md — NORWELCG trial analysis

Instructions for Claude (Claude Code and Cowork) working in this repository.
Adapted from the template for the NORWELCG trial.

## What this project is

Statistical analysis of **NORWELCG**: a stepped-wedge cluster-randomised trial
of the WHO **Labour Care Guide (LCG)** vs the **WHO partograph** in 10 Norwegian
delivery units (clusters), inclusion 01.04.2025–26.05.2026, 12 steps × 5 weeks.
Primary endpoint: intrapartum caesarean section; **non-inferiority**, margin
+1.5 pp on the absolute risk difference LCG − WHO (decided 2026-09-11; the
protocol's sample size was computed for equivalence with the same margin).
Analyses: GLMM with random cluster effect, fixed treatment + time interval
(step); marginal (population-averaged) risk differences by G-computation over
the random cluster effect, delta-method standard errors.

The user is the study statistician, responsible for the SAP and all code.
Protocol: `docs/protocol/`. SAP source: **`docs/sap/sap_norwelcg.qmd`** (from
v0.8, converted 2026-09-11; v0.83 on 2026-09-29; v0.9 on 2026-10-13; **v1.0 of
14 October 2026, signed**: `docs/sap/NORWELCG SAP v1.0 2026-10-14 sign.pdf` is the
authoritative record (Word/PDF before signature alongside); the qmd source matches
it apart from the hand-filled signature dates). Any change from now on is a formal
amendment (v1.1, version-history row, re-signed before unblinding). `quarto render`
→ docx via `docs/sap/templates/sap_reference.docx`, plus html; it writes
`SAP_NORWELCG.docx` / `.html` in `docs/sap` (not kept in the folder since the
clean-up) — render a scratch copy for checks, **never with `--output-dir`**.
All drafts, circulated and returned versions (v0.7–v0.9, the investigators'
v0.85 feedback, old qmd snapshots) are in `docs/sap/drafts/`.
Investigators edit circulated Word copies, partly **without** track changes —
when porting a returned docx, diff its full text against the version sent,
not just the tracked changes. Reviewer comments from Word live in the
qmd as `<!-- COMMENT … -->` lines; TransCelerate template guidance is kept
only as `<!-- CPT guidance … -->` comments (not rendered). The SAP covers the **primary publication only** — other endpoints are
deliberately deferred to later SAPs/publications.

**The SAP is the source of truth.** Code and reports are validated against it,
not the other way around. When the SAP, code, and report disagree, flag it —
do not silently "fix" code to match a guess about intent.
**`docs/sap/sap_data_review.md`** is the living SAP↔data↔code findings log
(open items, decisions, blind-review issues) — update it as findings arise.

## Reference documents (docs/sap/templates/)

- **`estimands_examples.md`** — TransCelerate estimand examples; the pattern for
  specifying estimands.
- **`SOP_STAT01_Statistics.md`** — OUS CTU statistics SOP (ICH E6/GCP, E9);
  follow for process and deliverables.
- **`SAP_CoreBWE_v005.Rmd`** — TransCelerate SAP section structure.

Markdown copies are for search; original docx/signed versions are authoritative.

## Data

**Not Viedoc.** The EDC delivers one flat Stata `.dta` file **per study
period** — intervention (LCG), transition (the 5-week teaching step) and
control (WHO partograph) — each **one row per woman** (twin data in `tv2_*`
columns). The **transition file has the same structure as the control file**
(statistician, 2026-09-09). Paths are keyed by period label in `cfg$raw_files`.
Codebooks: `metadata/raw_codebook.txt` (intervention) and
`metadata/raw_codebook_ctr.txt` (control, and hence transition). Quirks that
matter:

- Stata truncates names to 32 chars and renames dotted checkbox items to
  `v8, v9, …` **positionally** — the files must be aligned by variable
  **label** (which carries the full dotted name), never by column name.
  `read_norwel_raw()` does this and adds `treatment`, whose values are the
  **period labels** (`intervention` / `transition` / `control`), i.e. the true
  allocation.
- The record key **`nokkel`** (format `INT-NNNNN`) is the subject id and its
  **prefix CTR / TRAN / INT is the study period** = the source file. The
  treatment is the period of the documentation form, not hospital × time of
  birth (SAP v0.83, item 62): the LCG form was taken into use at 08:00 on
  each hospital's crossover date (women already in labour stayed on the
  previous form); control and transition share a form and were split by the
  scheduled transition date from 08:00. The transition period is excluded
  from the PAS (included as control in primary SUPP2).
- A few variables are period-specific (intervention: `samvalg_*`,
  `stotteperson.*`, `tidsintervall_LCG_*`; control **and** transition:
  `tiltakslinjen_*`, `avdelingens_*`, an extra midwife-presence band) → NA in
  the periods that lack them.
- Maternal age is `alder`. Timestamps are `str16` ISO-local strings (typed
  copies `ny*`) with occasional **sentinel/garbage values (years ~150–999)**
  — never derive calendar windows from observed min/max. `cx_k` = the time of
  the examination at which *k* cm was found (confirmed, DM 6); only ~43% of
  women have a `cx_4cm` time.

## Pipeline architecture

`targets` pipeline; **no SDTM stage** (the raw table is already one row per
participant — SDTM would add nothing):

```
data/raw (3 .dta | anon rds) -> ADaM (R/make_ad) -> RD (R/make_rd) -> report
        R/make_raw/make_raw_norwel.R
```

- **`make_raw_norwel(cfg)`** — mode switch: `sham` reads
  `data/raw/<export>_anon/<export>_anon.rds`; `true` reads the per-period
  `.dta` files (`unlist(cfg$raw_files)`) via `read_norwel_raw()` (safe env
  only). Renames columns to full sanitised label
  names (truncation undone) and keeps labels.
- **ADaM (3 datasets, decided 2026-07-08):**
  - `adsl` — one row/woman: `SUBJID` = `nokkel`, `USUBJID` =
    STUDYID-`nokkel`; SITEID (cluster); BIRTHDTM; STEPN/STEP from time of
    birth on the `cfg$sw` calendar, steps starting at 08:00; `FORMPER` (key
    prefix) → TRT01P/A (NA in transition); `PERIODC` = period by the
    randomised schedule, kept only for the blinded form-vs-schedule check;
    FASFL, PASFL, VDSFL, TRNSFL, PSTRFL, EXPOSN; SAP §4.1.3 covariates and
    baseline characteristics.
  - `adeff` — BDS, one row/woman/PARAM: all per-woman endpoints; `PARCAT1` =
    PRIMARY / SECONDARY WOMEN / SECONDARY NEONATE / SUPPLEMENTARY / AUXILIARY /
    DESCRIPTIVE; `APOP` = PAS or VDS; `ANL01FL` = "N" for women excluded from
    an endpoint (intervention at ≤ 3 cm; descriptive endpoint not applicable);
    imputed-with-"No" rows flagged `DTYPE = "IMPUTED"`.
  - `adlp` — one row per cervical examination: dilatation found (`CMN`) and
    hours from the examination to delivery; input to the labour-curve model.
- `R/make_rd/` — analysis layer: `rd_helpers.R` (covariates, GLMM,
  G-computation over the random cluster effect by Gauss–Hermite, delta
  method, NI tests, Rubin, HC3); `make_rdeff` (primary, sensitivity,
  supplementary, dichotomous secondaries), `make_rdmi` (cord pH — multiple
  imputation), `make_rdsub`
  (Robson subgroup), `fit_lc` + `impute_t0` + `make_rdtte` (time from 4 cm to
  vaginal delivery: labour-curve imputation of the 4 cm time, LMM on the
  restricted time without vaginal delivery), `make_rddsc` (descriptive).
  Report: `reports/statistical_analysis.qmd` (reads the targets store).
  A full `tar_make` takes ~45 min.
- The template's Viedoc/SDTM files were removed on 2026-10-14 (SDTM stage,
  example ADaM/RD datasets, `make_raw.R`, `make_shamrand.R`, `visits.yml`).
  `make_rdtear.R` (ordinal tear analysis) is kept for a later SAP but is not in
  the pipeline. `config/cfg.yml` still has an unused `specs:` block (editing
  cfg.yml invalidates every target).

### Trial-specific analysis decisions (statistician; details in the review log)

- **Twins/neonatal endpoints:** worst baby per woman (event if either twin has
  it); analysis unit stays the woman. Mode of delivery = the most operative
  across the babies.
- **Primary endpoint** counts **all CS from 4 cm** in both periods (SAP
  v0.9, item 69); the 5 CS recorded at 3 cm (cervix retracted after
  admission) are counted with those at 4 cm. No principal stratum and no
  5 cm analysis any more (`PSTRFL` removed, item 70). Supplementary analyses
  of the primary: SUPP1 transition as WHO partograph, SUPP2 exposure time.
- **Secondary endpoints** in the PAS, **including the CS at 4 cm**:
  amniotomy / oxytocin / epidural counted **whatever the dilatation** (SAP
  v0.9, investigators' request; no 4 cm window). Episiotomy and OASIS
  (grade 3–4) in the VDS, composite supplementary in the PAS (CS = no event).
  Perineal support, medical pain relief, degree of tears, companionship are
  in later SAPs (`make_rdtear.R` kept but not in the pipeline). Time to
  vaginal delivery runs from 4 cm, CS = 36 h (composite), restricted mean
  over 36 h (items 60, 62).
- Labour progression is **not** in this SAP (later SAP).
- FASFL = "Y" for all rows (export contains only eligible admissions); PASFL
  also requires the birth inside the inclusion window.

## Conventions

- **Language:** R, tidyverse style. Pin packages with `renv`.
- **Config over hard-coding:** study id, arms (CTR = WHO partograph, reference;
  INT = LCG), run mode, export stem, the per-period raw-file paths, and the
  stepped-wedge calendar (`sw:`) live in `config/cfg.yml`. Anonymiser config in
  `config/anon.yml`.
- **Run mode:** `cfg$mode` is `sham` during development and `true` only after
  database lock. Never run on true allocation before lock.
- **Analysis population:** `filter_pop()` on `cfg$analysis$popfl` (= PASFL);
  the primary estimand uses the whole PAS (SAP v0.9; no principal stratum).
- **Naming:** `make_<adam>()`, `make_rd<topic>()`.
- **No patient data in git:** `data/raw/` and `data/ad/` are git-ignored.
- **Tests:** `tests/testthat/` (`testthat::test_file` per file); the anonymiser
  suite runs on synthetic fixtures mimicking the real structure.

## Data anonymisation & safe/development environments

Patient data stays in the **safe environment** (no LLM access). Code is
developed here (dev, LLM-accessible) against an anonymised copy, then moved to
the safe environment to run on real data. "Anonymised" = relative to the
development environment (recipient holds no re-identification keys), per CJEU
C-413/23 P (EDPS v SRB). See `docs/data_anonymisation_specification.md` and
`docs/data_anonymisation_plan.md`.

- **Anonymiser:** `R/make_anon/make_anon.R` driven by `config/anon.yml`
  (flat-file design, NOT the template's Viedoc design):
  - `drop` columns removed (`created`, `answer_time_ms`);
  - **synthetic key**: the real record key `nokkel` (prefix CTR/INT/TRAN = true
    period) is removed and rebuilt in the same format, prefix from the permuted
    period, numbers 1..n random within prefix (`synthetic_ids:`; no map kept);
  - **timing**: all timestamps of a row shifted by one random whole-day offset,
    bounded so the shifted anchor (delivery time `nyfodselstidspunkt`, with
    fallbacks) stays inside the **explicit** trial window (`window:` in
    anon.yml — explicit because of the sentinel dates); out-of-window anchors
    parked on a random in-window date. `make_anon` **stops** on any date-time
    column not listed in `timing:`/`drop:` (deviation D-1, spec §14);
  - **block-consistent permutation** of everything else (gates travel with
    conditional children; `joint:` couples amniotomy+oxytocin; `tv2` block
    restricted to twin rows); marginals preserved, linkage broken;
  - **`treatment` is permuted too** → the anon copy carries a *random* study
    period with true period sizes (three levels since 2026-09-09); no separate
    sham-randomisation step exists or is needed.
- **Run in the SAFE environment only**, in a fresh process:
  `Rscript R/make_anon/run_anon.R` (never re-call `make_anon()` in an old
  session — it keeps old definitions while re-reading anon.yml, deviation
  D-2). It calls `make_anon(unlist(cfg$raw_files), cfg)` — a **named** vector
  of the per-period `.dta` paths, the names becoming the `treatment` values —
  which writes `data/raw/<export>_anon/` (movable, incl. `anon_manifest.csv`
  with the code version) and `data/raw/anon_keys/offset_map.csv` (the
  re-identification key), then runs `anon_verify` and the synthetic-key check.
  **In dev, check `anon_manifest.csv` `anon_code_version` = `ANON_CODE_VERSION`
  before using a new copy.**

Cardinal rules — enforce these:

- **anon_keys never leave the safe environment.** Never commit or export them.
- Only **code** travels dev → safe; only **anonymised data** travels safe → dev.
  After changing anonymiser code in dev, the safe server must get the updated
  code **before** re-running.
- Permutation breaks cross-variable and within-row relationships by design:
  endpoint **marginals are real**, treatment effects and step×treatment
  structure are **not**. Develop consistency/edge-case logic on synthetic
  fixtures (see tests), not on the anon copy.
- The data remain personal for the controller (who holds the keys; the list
  linking `nokkel` to hospital records is held by the PIs). No trial-specific
  DPO assessment (2026-10-02); the general handling of relative anonymisation
  is being clarified in an external process — see specification.

## Division of labor: Claude Code vs Cowork

Both act on the **same working tree**. Commit or stash before switching tools.

- **Claude Code** owns the pipeline: R functions, `targets`, tests, `renv`, git.
- **Cowork** owns documents and review: SAP/protocol editing, the mock-up report
  as deliverable, planning, cross-document consistency checks.

### Standing procedure: SAP <-> code <-> report consistency check

1. Extract the SAP (objectives, estimands, analysis methods).
2. Compare against the report narrative **and** the actual code — the code is
   often right where the report prose is stale.
3. Classify findings: substantive vs wording vs numbering; note anon-data
   limitations separately from real inconsistencies.
4. Update the single review document `docs/sap/sap_data_review.md`.

## Database-lock checklist

Before final analysis on true data (safe environment), confirm:

- [ ] `config/cfg.yml` `mode: true`, correct `raw_files:` paths.
- [ ] `read_norwel_raw()` label-alignment report checked (expected with
      transition ≡ control: ~163 variables shared by all three files, 53 absent
      from transition+control, 3 absent from intervention; investigate
      deviations).
- [ ] `nokkel` unique, prefixes CTR / TRAN / INT only and matching the source
      files (ADSL stops / warns otherwise).
- [ ] STEPN populates 1–12 from time of birth; form period × step pattern
      (`blinded_checks.R`, `period_schedule`) matches the randomised sequence
      apart from women in labour at a change of period.
- [ ] Final blinded review on the final export done (item 52:
      `cleaning_check.R`, `blinded_checks.R`, blinded counts quoted in the SAP)
      and the other open items in `docs/sap/sap_data_review.md` resolved.
- [ ] Country-to-continent lookup (item 58) in place (birthweight percentile
      dropped from the baseline table in SAP v0.9; BWPCT still derived in ADSL).
- [ ] Cleaned public snapshot of the repository prepared (review item 66):
      decide whether deviations D-1/D-2 are included; personal names
      replaced by roles unless consent; pooled blinded figures agreed with
      the PIs; dev demo "effects" removed; no data, keys, record keys or
      publisher PDFs; built from the files, not from the git history.
- [ ] Analysis code reviewed and version-locked; `renv.lock` committed.
- [ ] SAP, code, and report reconciled (consistency check passed).
- [ ] Any post-lock change documented and justified.

## User preferences

Concise and direct; treat the user as an expert statistician (PhD, 15+ yrs in
trials). Default to markdown for documents. Do not restate the question or
summarise at the end. R/tidyverse for code.
