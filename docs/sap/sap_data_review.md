# SAP ↔ data ↔ code review — NORWELCG

Living log of findings from checking the SAP (`docs/sap/sap_norwelcg.qmd`;
the Word v0.7/v0.8 before 2026-09-11) against the raw exports (`_20260708`,
final `_20260909`) and the pipeline code, maintained per the standing
consistency-check procedure in CLAUDE.md. Questions to the PIs and data
managers: `docs/sap/questions_PI_DM.md`. Data-cleaning rules:
`docs/sap/data_cleaning_rules.md`.

**Layout.** Open issues first, grouped by who acts next; then the closed
issues — an index with closing date and outcome, followed by the full record
of each item in number order. Item numbers are permanent (code comments, the
SAP and the questions file refer to them); items 44–59 were opened on
2026-09-14 from the loose ends of closed items ("from" gives the origin).
§5.1.1 subsections were renumbered on 2026-09-11 (item 39), so records
written before that may use the old numbers.

## Open issues (updated 2026-10-14)

### Investigators (PIs)

None open (2026-10-14).

### Data managers

None open (2026-10-02).

### Blinded data review (safe side)

None open (2026-10-14; database locked).


### Statistician (methods and SAP)

None open (2026-10-14).

### Pipeline

None open (2026-10-14).

### Anonymisation and governance

None open (2026-10-02); the public snapshot is item 66.


66. **Publish a cleaned snapshot of the repository** (statistician,
    2026-10-02; before unblinding and the final analyses — CLAUDE.md
    database-lock checklist). The review log is to be published (the SAP's
    AI statement refers to it). Checked 2026-10-02: no e-mail addresses,
    record keys, hospital names, local paths or individual-level data.
    Before publishing: (1) deviations D-1/D-2 (D-2: a dev copy carried the
    real, permuted `nokkel`; deleted the same day) only after the DPO
    assessment (59), also in the anonymisation specification §14;
    (2) personal names (investigators as authors of comments and
    decisions; A. Staff's advice) → roles unless they consent — also the
    COMMENT lines in the SAP source and `questions_PI_DM.md`; (3) pooled
    blinded figures from the final export (N, period sizes, CS rate 7.5%,
    missing counts) — PIs to agree; (4) effect-like numbers from dev demo
    runs on permuted data (P(VD) / HR in item 39, tear OR in 42) → remove
    the numbers; (5) cosmetic: "session scratchpad" references, tone of
    item 25. Snapshot = the current files (not the git history), without
    `data/`, `outputs/`, `docs/sap/refs/` (publisher PDFs) and working
    Word files. *2026-10-02*: no trial-specific DPO assessment (59 closed);
    whether D-1/D-2 are included in the snapshot is the statistician's
    decision when building it.

## Closed issues

| # | Issue | Closed | Outcome | Follow-up |
|---|---|---|---|---|
| C | Open confirmations 1–8 (MI specifications, twin rules, PO check) | 2026-09-11 | 1–6 confirmed; 7 twin 1's mode if twin 2's missing; 8 no PO check. |  |
| 1 | ADaM structure | 2026-07-08 | ADSL, ADEFF (BDS), ADLP (BDS); no SDTM stage. |  |
| 2 | Twins / neonatal endpoints | 2026-07-08 | Worst baby per woman; the woman is the unit (extended to delivery mode in 41(1)). |  |
| 3 | Principal stratum `PSTRFL` | 2026-09-11 | Symmetric: CS at ≤ 4 cm excluded in both periods; SAP aligned (item 33). |  |
| 4 | Amniotomy missing from the endpoint table | 2026-09-11 | Row added in v0.8. |  |
| 5 | Time from 5 cm to delivery / labour progression unmapped | 2026-09-11 | Two endpoints; methods decided in item 39. |  |
| 6 | Maternal age not in the export | 2026-09-11 | `alder` in the final export → `AGE`. |  |
| 7 | Continent of origin | 2026-09-11 | Grouped by continent (PI 6); lookup as a metadata file. | 58 |
| 8 | Birthweight percentiles | 2026-09-11 | Dropped from the SAP (item 34). |  |
| 9 | Ward-level covariates | 2026-09-11 | Not used for adjustment (item 34); `metadata/hospitals.csv` holds strata and schedule. |  |
| 10 | Perineal support imputation | 2026-09-11 | VDS; missing = not recorded; multiple imputation (41(10)). |  |
| 11 | Step calendar off-by-one / inclusion date | 2026-09-11 | Time of birth defines inclusion, period and step; 26 May 2026 → step 12 (item 38). |  |
| 12 | CS with missing dilation | 2026-09-11 | None in the final export (item 31). | 52 (DM 8) |
| 16 | Population-averaged risk not operationalised | 2026-09-11 | G-computation integrating over the random effect (item 35). |  |
| 17 | Equivalence decision rule | 2026-09-11 | Superseded by non-inferiority (item 32). |  |
| 18 | Covariate adjustment contradiction | 2026-09-11 | Adjustment set decided (item 34). |  |
| 19 | Sensitivity analyses vs symmetric `PSTRFL` | 2026-09-11 | Re-specified (items 33, 36). |  |
| 20 | Labour progression: category and missing data | 2026-09-11 | Superseded by item 39. |  |
| 21 | Transition period not handled | 2026-09-11 | PAS excludes transition periods; included as control in SUPP3 (items 28, 36); implemented (item 42). | 45 |
| 22 | Crossover calendar; `TRT01P` was the form, not the assignment | 2026-09-11 | `TRT01P` from hospital × time of birth and the schedule; form period kept separately (item 42). | 44, 53 |
| 23 | Primary summary measure vs margin | 2026-09-11 | Absolute RD primary (item 27). |  |
| 24 | Final-export columns unknown to the anonymiser | 2026-09-11 11:08 | Anonymiser fixed (timing, synthetic key, stop on unknown date-times); D-1/D-2 logged; verified copy `20260911`. | 51, 59 |
| 26 | §1.1 table as the endpoint master list | 2026-09-11 | Adopted. | 56 |
| 27 | Primary summary measure = absolute RD | 2026-09-11 | Relative difference supplementary. |  |
| 28 | Transition period = design feature | 2026-09-11 | Treatment attribute and analysis sets, by the randomised schedule. | 45 |
| 29 | Analysis sets | 2026-09-11 | FAS / PAS / VDS; no per-protocol set. |  |
| 30 | Vaginal-birth-only endpoints | 2026-09-11 | Principal stratum in the VDS; composite supplementary in the PAS. |  |
| 31 | Primary endpoint missing data | 2026-09-11 | None at blinded review; complete case as fallback. | 53 |
| 32 | Non-inferiority with superiority step | 2026-09-11 | Upper 95% CI limit < +1.5 pp, then < 0 (fixed sequence). | 25 |
| 33 | Principal stratum = 5 cm, symmetric | 2026-09-11 | SENS1 treatment policy → SUPP1; 4 cm threshold → SUPP2 (item 36). |  |
| 34 | Covariate adjustment set | 2026-09-11 | Robson, age, BMI, height, birth weight, GA (splines, missing indicator); blinded covariate check. |  |
| 35 | Marginalisation | 2026-09-11 | G-computation over the random cluster effect (Gauss–Hermite). |  |
| 36 | Sensitivity vs supplementary (ICH E9(R1)) | 2026-09-11 | Sensitivity: unadjusted, hospital fixed; supplementary 1–4. |  |
| 37 | Secondary endpoint list reconciled with §1.1 | 2026-09-11 | Cord pH and tear grade added; perineal support definition. | 47, 52 |
| 38 | PI/DM meeting answers | 2026-09-11 | Consequences implemented in SAP and code. |  |
| 39 | Labour progression, time zero, 5 cm window, time-to-event model | 2026-09-11 | Labour-curve model; 5 cm time multiply imputed (m = 30); Weibull mixture, RMST to 24 h (estimator and horizon superseded by 60). | 54, 55, 60 |
| 40 | §5.1.1.4 and §5.1.1.11 aligned | 2026-09-11 | Dichotomous secondaries: primary model, CIs only. |  |
| 41 | Secondary endpoints, one at a time | 2026-09-11 | All 17 decided; (3)–(5) revised the same day (pre-5 cm use excluded). | 46, 47, 49, 52, 53 |
| 42 | Pipeline phase 3: implementation and deviations | 2026-09-14 | (a), (e), (h), (i) accepted 2026-09-13 (item 43); (j) decided 2026-09-14. | 44 (b), 52 (c, d), 54 (f, g) |
| 43 | Statistician's review of the implementation | 2026-09-14 | Single residual variance; cleaning check; renv; codelists; descriptive tables; general missing-indicator rule. | 48, 57, 58 |
| 44 | Actual crossover dates per hospital | 2026-09-29 | Step dates = `cfg$sw`, from 08:00; period now from the source dataset (item 62). | 63 |
| 45 | Transition-period instructions | 2026-09-29 | Control form used in transition; split from control by date from 08:00. |  |
| 46 | Scalp lactate testing as an endpoint | 2026-09-29 | Later SAP; not mentioned in this SAP. |  |
| 47 | Cord blood gas sampling | 2026-09-29 | Missing arterial pH MCAR (investigators); MI kept. |  |
| 25 | Pooled CS rate below the planning assumption | 2026-09-29 | No sentence added to the SAP (statistician). |  |
| 48 | English codelists | 2026-09-29 | Validated by the investigators; two labels changed in `codelists.csv`. |  |
| 49 | Variable semantics (DM 6, 11, 12, 13) | 2026-09-29 | `cx_k` confirmed; continuous external CTG assumed to include the admission CTG; DM 12/13 as item 62. |  |
| 50 | CONSORT flow counts | 2026-09-29 | Not known; flow from the export only. |  |
| 51 | Updated codebooks | 2026-10-02 | Generated in dev from the anonymised final export; no DM delivery needed. |  |
| 59 | Anonymisation follow-ups | 2026-10-02 | New copy `20261001_anon` verified; `anon.yml` mirrored; no trial-specific DPO assessment; linking list held by the PIs. | 66 |
| 13 | Negative / implausible labour timings | 2026-10-02 | Final rule: examinations outside (0, 72) h before delivery not used; rule 4 flag only, limits from 4 cm. |  |
| 14 | Implausible anthropometrics | 2026-10-02 | Kept as recorded (implausible but possible). |  |
| 15 | `vet_ikke` neonate sex | 2026-10-02 | Shown as "Unknown"; birthweight percentile missing for these. |  |
| 54 | Remaining implementation deviations | 2026-10-02 | (f) and (g) accepted; no SAP text. |  |
| 55 | Verify references cited from memory | 2026-10-02 | All verified (PubMed, full texts); Zhang, Andersen & Keiding, Kenny reworded; Ware Branch D. |  |
| 56 | SAP ready for circulation | 2026-10-02 | Comments resolved; §7, §10, §12, version history, abbreviations, legends, AI statement written (v0.84). |  |
| 58 | Country of origin → continent lookup | 2026-10-02 | `metadata/country_continent.csv` (UN M49); CONTINENT in ADSL; Norway row kept. |  |
| 65 | SAP ↔ code ↔ report check of the v0.83 build | 2026-10-02 | (a)–(i) implemented: SAP wording, twin-2 CS, denominators, SDM/companionship LCG-only with `sdm_items.csv`, report fixes. | 57 |
| 60 | Time to vaginal delivery: estimator and horizon | 2026-09-29 | Difference in mean Y = min(T, 36 h), CS = 36 h, linear mixed model; replaces the Weibull mixture and the 24 h horizon; time-zero imputation kept; origin 4 cm and CS at 4 cm included (item 62). | 55, 61 |
| 61 | Time to vaginal delivery: code | 2026-09-29 | `make_rdtte` rewritten (LMM on Y, MI of the 4 cm time, Rubin); tested. | 57 |
| 62 | Investigators' feedback and SAP v0.82 → v0.83 | 2026-09-29 | Treatment by source dataset; secondaries from 4 cm incl. CS at 4 cm; labour progression removed; pH MI kept (MCAR); Robson subgroup; v0.82 edits ported. | 61, 63, 64 |
| 63 | SAP v0.83 in the pipeline | 2026-09-29 | Implemented and tested; SUBJID = `nokkel`; full rebuild pending. | 57 |
| 67 | Statistician's edits of v0.84 (`SAP_NORWELCG v0.84 ICO.docx`) | 2026-10-06 | Ported to the qmd; RMST ↔ linear model on Y explained (pseudo-observations, Andersen, Hansen & Klein 2004); section cross-reference bug fixed. |  |
| 68 | Statistician's comments on the mock-up report (`statistical_analysis commICO.docx`) | 2026-10-07 | Treatments named "WHO partograph" / "LCG" throughout (cfg arms → TRT01P, period labels, SUPP2/SUPP3, column headers); Y/N and 0/1 → Yes/No; Parity label; open-items section removed; SAP v1.0 reference added. Tests pass; rebuild needed (57). | 57 |
| 57 | Rebuild | 2026-10-14 | Full `tar_make()` on the SAP v1.0 code (statistician). |  |
| 64 | Birthweight percentile reference and §12.1 completeness | 2026-10-14 | Percentile removed from the SAP; §12.1 completed by the investigators. |  |
| 69 | Investigators' feedback on v0.85 → SAP v0.9 / v1.0 | 2026-10-14 | Primary = all CS from 4 cm (no principal stratum); amniotomy/oxytocin/epidural at any dilatation; episiotomy/OASIS in the VDS; endpoints moved to §12.1; signature page; v1.0 for signature. | 52 |
| 70 | SAP v0.9 in the pipeline | 2026-10-14 | Implemented, tested and rebuilt. | 52 (live-fetus check) |
| 71 | Repository clean-up; `raw_file` tracked the old anon copy | 2026-10-14 | Template files removed, new README; file targets now depend on `cfg` (analyses always read `cfg$export`, so results unaffected). |  |
| 52 | Final blinded data review before database lock | 2026-10-14 | Database locked; SAP numbers confirmed; no woman with a dead fetus at admission; cleaning check no longer needed. |  |
| 53 | Blinded aggregate checks | 2026-10-14 | Not run; no longer needed after lock. |  |
| 72 | SAP v1.0 signed | 2026-10-14 | Signed: `NORWELCG SAP v1.0 2026-10-14 sign.pdf` (authoritative). Last-minute investigator edits before signature, in the §12.1 table: "Neonatal morbidity"; skin-to-skin "for at least one hour after birth"; NICU-admission-reasons morbidity row removed. Ported to the qmd; a render of the qmd matches the signed docx apart from the hand-filled signature dates and the Word-built table of contents. Drafts in `docs/sap/drafts/`, reference documents in `docs/sap/templates/`. No code impact. |  |

### Record of the closed issues

Full text as logged, in number order. Items 1–3 were decided on 2026-07-08;
4–11 and 12–25 were raised while building the ADaM and analysis layers
(2026-07-08 to 2026-09-11); 26–43 come from the SAP v0.8 pass and the
implementation. Review of this log by the statistician ("Review updates"), reflected per item below: items 4, 6 resolved; 5, 7, 9, 10, 11, 21 decided; 16–20 carried into the section-by-section SAP v0.8 pass.

#### C. Open confirmations 1–8 — closed 2026-09-11


Specifications written into the SAP (or proposed) during the endpoint pass
without an explicit decision. Section numbers are those after the C/C\*
removal (2026-09-11).

1. **Perineal support — multiple imputation** (§5.1.1.4, first paragraph
   after the covariate list): chained equations, **m = 20**; imputation
   model = treatment, time interval, **hospital as a fixed effect**,
   primary covariates, plus auxiliaries vaginal delivery mode, perineal
   tear grade and episiotomy. (item 41(10))
2. **Cord pH < 7.00 — multiple imputation** (§5.1.1.4, second paragraph):
   predictive mean matching on the continuous arterial pH, then
   dichotomised at 7.00; **m = 30**; auxiliaries venous pH, base
   excess/deficit, Apgar at 1 and 5 min, NICU ≤ 2 h, delivery mode;
   analysis-model variables as in 1. (item 41(15))
3. **Cord pH — twins under MI**: a woman with at least one measured baby is
   scored from her measured babies; imputation only when no baby was
   measured ("any baby measured" read together with MI). (item 41(15))
4. **5 cm time imputation** (§5.1.1.7): imputation model with treatment,
   treatment × dilation, time interval, hospital (fixed), primary
   covariates; residual variance by dilation; parameters redrawn per
   imputed dataset; **m = 30**. The same model serves labour progression
   (§5.1.1.5), where negative simulated times are set to 0. (item 39)
5. **Weibull mixture** (§5.1.1.7): **hospital as a fixed effect** in the
   Weibull part (no random-effect Weibull available; ICC ≈ 0.0001); random
   cluster intercept in the logistic part. (item 39)
6. **Amniotomy / oxytocin / epidural before 5 cm** (§4.1.3): presented in
   the **baseline table only, not as adjustment covariates** (reading of
   "presented as baseline covariates"). (item 41(3)–(5))
7. **Twin-2 delivery mode missing (4 women)**: proposal — the woman's mode
   is the most operative among the babies with a recorded mode; not yet in
   the SAP text. (item 41(1))
8. **Proportional-odds check for perineal tears**: add a diagnostic
   sentence to §5.1.1.6 (e.g. separate binary splits), or leave it out?
   (item 41(9))

*Status 2026-09-11 (statistician)*: **1–6 confirmed**; **8 decided — no
proportional-odds check in the SAP**; **7 decided — twin 1's mode is used
when twin 2's is not recorded** (4 women; twins, not triplets — the export
has a twin-2 block only); SAP §4.1.1 updated; records queried with the DMs
(DM 15). All confirmations closed.

#### 1. ADaM structure — closed 2026-07-08

*Outcome: ADSL, ADEFF (BDS), ADLP (BDS); no SDTM stage.*

**ADaM structure** — three datasets: ADSL (subject-level), ADEFF (all
per-woman endpoints, BDS), ADLP (labour-progression intervals, BDS). No
SDTM stage: the raw table is already one row per participant.

#### 2. Twins / neonatal endpoints — closed 2026-07-08

*Outcome: Worst baby per woman; the woman is the unit (extended to delivery mode in 41(1)).*

**Twins / neonatal endpoints** — worst baby per woman: Apgar <7 @5 min or
NICU ≤2 h counts if *either* twin meets it; analysis unit stays the woman.

#### 3. Principal stratum `PSTRFL` — closed 2026-09-11

*Outcome: Symmetric: CS at ≤ 4 cm excluded in both periods; SAP aligned (item 33).*

**Principal stratum (PSTRFL)** — symmetric: intrapartum CS at **≤4 cm**
dilation excluded in *both* arms ("reached 5 cm" stratum applied literally).
163/30,938 excluded in the July export; 343/36,324 CS at 3–4 cm in the final
export. Note the SAP prose (1.2) says WHO-arm "before 4 cm" — still so in
**v0.8**; **the SAP text should be aligned** with the decided symmetric
rule, pending PI answer on whether ≤4 cm CS were registered in the LCG
period (item 19). *Resolved 2026-09-11 (item 33).*

#### 4. Amniotomy missing from the endpoint table — closed 2026-09-11

*Outcome: Row added in v0.8.*

**Amniotomy** missing from the endpoint-definition table (5.1.1.1).
*Resolved 2026-09-11*: row added in v0.8 (D, complete case) — matches ADEFF
`AMNIO`.

#### 5. Time from 5 cm to delivery / labour progression unmapped — closed 2026-09-11

*Outcome: Two endpoints; methods decided in item 39.*

**"Total time from 5 cm dilation to delivery"** had no endpoint mapped.
*Decided 2026-09-11 (v0.8)*: two endpoints.
- **Time from 5 cm to vaginal delivery** — TTE, "generalised linear mixed
  Weibull model"; CS "imputed with infinite time" (never a vaginal
  delivery; censoring rejected). *Open methods issue (closed 2026-09-11 — Weibull mixture, item 39):* infinite times keep
  CS in the risk set for ever — this is the **Fine–Gray subdistribution**
  set-up with CS as competing event. A plain Weibull likelihood cannot take
  them (log S(∞) = −∞). Candidates: Weibull **mixture-cure** model (cure
  fraction = CS), Fine–Gray with cluster-robust small-sample SEs, or CIF
  comparison at fixed times. The estimand then combines CS risk and speed
  of delivery — the SAP should say so.
- **Labour progression** — cervical dilation 5→10 cm by time, repeated
  measures LMM (hourly categorical time × treatment, calendar period ×
  continuous time, random cluster and woman slopes; "or at least we will
  try it"). *Open methods issue (closed 2026-09-11 — labour-curve model, item 39):* the data record the **time** each cm is
  observed (dilation fixed by design, time random), so cm-on-time regression
  conditions on the outcome; plus 10 cm ceiling and CS dropout. Final
  export: only **39%** have a `cx_5cm` time; first observed cm ≥5 is 6–10 cm
  for 58%, and 13% have only `cx_10cm` — consistent with `cx_k` = exam time
  at which *k* cm was found (DM question). Alternative: repeated per-cm
  durations (log-normal / interval-censored, Zhang et al. 2010).
- *Code status*: `make_rdlp` still runs TT5TODLV as LMM + Gamma GLMM; no
  TTE or RM code yet. Taken together with item 20 in the SAP pass.
*(decided: SAP; methods decided 2026-09-11)* — continued in item 39 (CS rule decided;
time zero and progression model for discussion).

#### 6. Maternal age not in the export — closed 2026-09-11

*Outcome: `alder` in the final export → `AGE`.*

**Maternal age** — *Resolved 2026-09-11*: `alder` is in the final export
(18–54, no missing; not in the July export). Goes into ADSL as AGE; the
FAS "≥ 18 years" criterion holds.

#### 7. Continent of origin — closed 2026-09-11

*Outcome: Grouped by continent (PI 6); lookup as a metadata file. Open follow-up: items 58.*

**Continent of origin** — *Decided 2026-09-11*: country → group lookup for
`landbakgrunn` as data, `metadata/country_continent.csv` (not cfg.yml).
Grouping (continent vs Statistics Norway country groups) asked of the PIs.

#### 8. Birthweight percentiles — closed 2026-09-11

*Outcome: Dropped from the SAP (item 34).*

**Birthweight percentiles** need an external growth standard (GA × sex).
*Pending PIs* (asked 2026-09-11). Post-birth measurement but not
affected by the partograph, so a legitimate adjustment covariate; the SAP
should say so and state which twin is used. *Resolved 2026-09-11:
percentiles dropped (item 34).*

#### 9. Ward-level covariates — closed 2026-09-11

*Outcome: Not used for adjustment (item 34); `metadata/hospitals.csv` holds strata and schedule.*

**Ward-level covariates** — *Decided 2026-09-11*: source is the
randomisation document (`docs/protocol/NORWELCG-randomisation.pdf`): births
(FHI), CS %, birth stratum (cut-off 2900), CS stratum (cut-off 12.3 %),
stratum 1–4, and the randomised cluster number. All 10 `fodested` codes
map one-to-one. To build: `metadata/hospitals.csv` (also supplies the
crossover calendar, item 22). Randomisation was **stratified** on births ×
CS rate — an argument for the stratification factors in the primary model
(item 18). "Hospital level" has no source — asked of the PIs.
*2026-09-11*: hospital-level covariates are not used for adjustment
(absorbed by the cluster random effect, item 34); `metadata/hospitals.csv`
is still needed for the crossover calendar (item 22).

#### 10. Perineal support imputation — closed 2026-09-11

*Outcome: VDS; missing = not recorded; multiple imputation (41(10)).*

**Perineal support imputation** — *Decided 2026-09-11*: keep "impute
missing with No", but restrict the target population to **vaginal
deliveries** (v0.8 table). Notes: (a) conditions on a post-randomisation
variable — acceptable for a secondary endpoint, label it so; (b) final
export (re-anonymised copy with the joint delivery-mode/perineal block,
item 24): missing for **4,014 vaginal deliveries** (3,406 spontaneous, 525
vacuum, 83 forceps) — the "No" imputation would touch 12% of the
restricted population; DM asked what missing means, PIs asked whether
operative vaginal deliveries are in the denominator; (c) 1,279/2,712 CS
carry a value (20 "yes") and 7 CS (all at 10 cm) a perineal tear —
blind-review consistency check.

#### 11. Step calendar off-by-one / inclusion date — closed 2026-09-11

*Outcome: Time of birth defines inclusion, period and step; 26 May 2026 → step 12 (item 38).*

**Step calendar off-by-one** — *Decided 2026-09-11*: day 421 (26.05.2026)
goes into step 12, per the SAP inclusion window. **New:** inclusion appears
to be by **delivery** date (all cleaned deliveries fall in the window; 34
cleaned admissions are before 01.04.2025, up to 64 days), whereas ADSL
derives STEPN from the raw admission time. Proposal: STEP from delivery
date (50 rows on day 421), or cleaned admission clamped to the window —
DM asked which date defined inclusion and form. *Resolved 2026-09-11
(item 38): time of birth defines inclusion, period and step; day 421 →
step 12.*

#### 12. CS with missing dilation — closed 2026-09-11

*Outcome: None in the final export (item 31). Open follow-up: items 52 (DM 8).*

**CS with missing dilation** (5 women in July). *2026-09-11*: every CS in
the final export has a dilation (2,712/2,712) — confirm correction at
source (DM question). *Resolved at blinded review 2026-09-11 (item 31).*

#### 13. Negative / implausible labour timings — closed 2026-10-02

*Outcome: Final rule: examinations outside (0, 72) h before delivery not used; rule 4 flag only, limits from 4 cm.*

Content as logged while open:

13. **Negative / implausible labour timings** (part of 52; rules 1, 3, 4).
    ~86 negative consecutive cm-to-cm intervals (5→6 … 8→9; none 9→10 or
    10 cm → delivery) and 11 implausible years in the latent-phase start.
    The `ny*` columns are typed copies, not cleaned versions (DM 2). The
    final export is much cleaner than July's.

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 14. Implausible anthropometrics — closed 2026-10-02

*Outcome: Kept as recorded (implausible but possible).*

Content as logged while open:

14. **Implausible anthropometrics** (part of 52; rules 5–7). Final export:
    0 heights outside 130–220 cm, 1 pre-pregnancy weight outside 35–250 kg
    (July: up to 769 cm and 894 kg).

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 15. `vet_ikke` neonate sex — closed 2026-10-02

*Outcome: Shown as "Unknown"; birthweight percentile missing for these.*

Content as logged while open:

15. **`vet_ikke` neonate sex** (1 row). Decoded as "Unknown"
    (`codelists.csv`); check that the baseline table shows it sensibly.

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 16. Population-averaged risk not operationalised — closed 2026-09-11

*Outcome: G-computation integrating over the random effect (item 35).*

**"Population-averaged (marginal)" not operationalised in the SAP** (4.1.2):
with a logit GLMM the conditional (cluster-effect-at-zero) and marginal
(integrated over the random intercept) risk scales differ. Code
(`make_rdeff`) uses G-computation with the random effect set to zero
(`re.form = NA`), delta-method SEs via {marginaleffects}.
*2026-09-11*: agreed to settle in the SAP pass. Proposal: G-computation
**integrated over the random-intercept distribution** (Gauss–Hermite) and
the pooled analysis-set covariates as primary, `re.form = NA` as a check;
with ICC ≈ 0.0001 (σ_u ≈ 0.018) the two coincide to ~3rd decimal, but the
SAP must name one. GEE with 10 clusters not recommended. *Resolved
2026-09-11 (item 35): G-computation integrating over the random effect.*

#### 17. Equivalence decision rule — closed 2026-09-11

*Outcome: Superseded by non-inferiority (item 32).*

**Equivalence decision rule**. *2026-09-11*: the text is in **§11 Sample
size** ("If the 95% confidence interval … lies completely within −delta to
+delta … significance level (alpha) of 5%") and 4.1.2 ("presented with a
95% confidence interval"). "95% CI inside ±1.5 pp" = TOST at **2.5%** per
side (ICH E9 convention for clinical equivalence). Proposal: keep the 95%
CI rule, reword alpha as "two-sided 5% (each one-sided test at 2.5%)";
code `eq_p` then to move to α = 0.025 per side (not yet changed).
Back-calculate 23,650 in the §11 pass to confirm which rule the sample size
used. *Superseded 2026-09-11 (item 32): non-inferiority, upper limit of
the 95% CI < +1.5 pp.*

#### 18. Covariate adjustment contradiction — closed 2026-09-11

*Outcome: Adjustment set decided (item 34).*

**Covariate adjustment contradiction**: 4.1.3 says the covariate list is
used "in all primary and secondary statistical models", but 4.1.2 and
5.1.1.4–5.1.1.9 specify treatment + time interval only. Code fits treatment + step,
covariates via `cfg$analysis$covariates` (empty). *2026-09-11*: to settle
in the SAP pass. Starting position: treatment + step + randomisation
stratification factors + a short list of strongly prognostic individual
covariates; missing covariates by missing-indicator / simple imputation
(valid under randomisation); unadjusted model as sensitivity.
*Resolved 2026-09-11 (item 34).*

#### 19. Sensitivity analyses vs symmetric `PSTRFL` — closed 2026-09-11

*Outcome: Re-specified (items 33, 36).*

**Sensitivity analyses vs symmetric PSTRFL** (4.1.4): SENS2 ("CS at 4 cm in
the LCG period") needs re-specification. *2026-09-11*: statistician to
check with the PIs whether LCG-period women with CS at ≤4 cm were
registered. Settled by one safe-side table: period × CS at ≤4 cm.
*Resolved 2026-09-11 (item 33).*

#### 20. Labour progression: category and missing data — closed 2026-09-11

*Outcome: Superseded by item 39.*

**Labour progression: category and missing-data conflict** (5.1.1.1,
5.1.1.5).
*2026-09-11*: superseded by the v0.8 RM specification (item 5); to be
discussed at length together with item 5. *(closed 2026-09-11 — see
item 39)*

#### 21. Transition period not handled — closed 2026-09-11

*Outcome: PAS excludes transition periods; included as control in SUPP3 (items 28, 36); implemented (item 42). Open follow-up: items 45.*

**Transition period not handled anywhere** (SAP 1.4 Study Design, Figure 1;
protocol §4).
Counting transition women as either arm biases the risk difference toward
zero — **toward equivalence**, i.e. anti-conservative for NORWELCG.
Recommendation was to exclude transition cluster-periods from the primary
analysis (design-based, fixed by the randomised sequence; matches Figure 1),
with sensitivity analyses (a) transition as LCG, (b) exposure-time model
(Kenny et al. 2022). References: Copas et al. *Trials* 2015;16:352; Hemming,
Taljaard et al. *BMJ* 2018;363:k1614 (CONSORT SW); Kasza, Taljaard & Forbes
*Stat Med* 2019;38:4686–4701; Kasza & Forbes *Biometrics* 2019;75:144–152;
Kenny et al. *Stat Med* 2022;41:4311–4339.
*Decided 2026-09-11 (v0.8)*: the primary analysis set **excludes** all
women included during the transition period (estimand table); **SENS3**
includes them **as control** (staff trained but told to wait until the
period ended). Wording fixes: "conservative towards the
**non-inferiority** assessment" → equivalence; under ICH E9(R1) SENS3 is
a *supplementary* analysis (it changes the treatment assignment of the
transition women). Suggest keeping the exposure-time model as exploratory.
Final export: 3,038 transition women (8.4%) → 33,286 remain vs 23,650
required. Figure 1: steps 1–2 contain no LCG cells and step 12 no control
cells after the exclusion; steps 3–11 contain both.
*(SAP wording closed, item 28; code pending item 22)*

#### 22. Crossover calendar; `TRT01P` was the form, not the assignment — closed 2026-09-11

*Outcome: `TRT01P` from hospital × time of birth and the schedule; form period kept separately (item 42). Open follow-up: items 44, 53.*

**No cluster → crossover-date calendar in the repo; `TRT01P` is the form
used, not the assignment.** `make_adsl` derives `TRT01P` from the source
file. Needed: a cluster → sequence / crossover table; `TRT01P` from that
calendar; `TRNSFL` and exposure time in ADSL; the primary filter dropping
`TRNSFL == "Y"`. Blind-review check: raw `treatment` (form) vs
calendar-assigned arm by cluster × step.
*Status 2026-09-09*: transition export received; raw + anonymiser layer
read it as `treatment == "transition"`; downstream untouched (transition
rows get `TRT01P = NA` and are silently dropped — a side effect, not the
decision).
*Status 2026-09-11*: the calendar is available in the randomisation
document — cluster *c* (randomised hospital) has transition in step *c*+1
and LCG from step *c*+2 (Figure 1). To go into `metadata/hospitals.csv`
(item 9) once the PIs confirm the **actual** crossover dates; `swap`
(item 24) may bear on the form-vs-calendar discordance.
*2026-09-11 (later)*: the `nokkel` prefix carries the same information as
`treatment` — the period of the **file/form** — not the calendar
assignment. Design: ADSL derives the calendar-assigned period (site ×
date × crossover table) as TRT01P; the file/form period is kept separately.
In dev the two disagree at random (site and dates randomised independently)
— expected, and it exercises the discordance code. On real data: prefix vs
file should agree 100%; file vs calendar is the blind-review check (DMs
asked). *(open)*

#### 23. Primary summary measure vs margin — closed 2026-09-11

*Outcome: Absolute RD primary (item 27).*

**Primary summary measure vs equivalence margin** *(new 2026-09-11)*. The
v0.8 estimand table makes the **relative** difference the primary summary
measure and the absolute difference supplementary, but the equivalence
margin (±1.5 pp) and the sample size are on the **absolute** risk
difference. For an equivalence conclusion the absolute RD must be primary
(or a relative margin defined). Code: `make_rdeff` reports both, `eq_p` on
the RD. *Resolved 2026-09-11* (item 27): absolute RD primary.

#### 24. Final-export columns unknown to the anonymiser — closed 2026-09-11 11:08

*Outcome: Anonymiser fixed (timing, synthetic key, stop on unknown date-times); D-1/D-2 logged; verified copy `20260911`. Open follow-up: items 51, 59.*

**Final export (`_20260909`) carries columns the anonymiser did not know**
*(new 2026-09-11)*: `nokkel` (record key; prefix CTR/INT/TRAN = true
period), `alder`, `swap` (0/1, control + transition files only, 48 ones),
and seven cleaned timestamps `ny*` (typed Stata datetimes). The `ny*`
columns were **permuted with their true calendar values instead of
shifted** — no row linkage (permuted), but the copy deviates from the
specification ("true calendar date hidden") and the `ny*` intervals are
unusable in development. *Fixed in code 2026-09-11*: `ny*` added to
`timing` (and gates), anchor now `nyfodselstidspunkt` (fallback list),
`nokkel` dropped, perineal groups permuted jointly with delivery mode,
`alder` added to the risk-readout quasi-identifiers; `make_anon` now
**stops** on any date-time column not in `timing`/`drop`, and rows with no
anchor get a random offset instead of none (latent bug; no effect so far —
admission was never missing).
*Done 2026-09-11*: safe-side re-run → `data/raw/20260911_anon`
(`export: "20260911"`), verified in dev: `nokkel` absent (rds and dta);
every `ny*` value equals its original timestamp on the same row, i.e. both
carry the same row offset; shifted deliveries inside the window; no
admission after delivery; gated `ny*` blank where the gate is off;
marginals of non-timing columns identical to the previous copy; no key
file anywhere in dev. `_20260909_anon` **deleted** from dev. The risk
readout now includes age (worst-case k = 1; 36,234 unique on the 9
quasi-identifiers) — not informative here, since each quasi-identifier is
permuted independently. Deviation recorded as D-1 in
`docs/data_anonymisation_specification.md` §14 (assessment field left for
the statistician/DPO). *Still to do*: regenerate codebooks; `swap` and the
`ny*` derivation asked of the DMs.
*Later 2026-09-11*: dropping `nokkel` broke schema parity (spec §10) and
left code that uses the key untestable in dev. `anon.yml` now rebuilds it
as a **synthetic** key (`synthetic_ids`): same format, prefix from the
permuted period label, numbers 1..n in random order within prefix; nothing
derived from the real key, no map kept (spec §6.1). All other columns are
unchanged relative to the verified `20260911` copy (same seed, draws
appended after the permutation). Also fixed: `anon_verify` matched skip
columns by config token, not the resolved column, so it flagged the
Stata-truncated latent-phase timing column and reported
`marginals_ok = FALSE` spuriously; it now resolves tokens like
`make_anon` (regression test added).
*Re-run 10:49, 2026-09-11 — deviation D-2*: the copy carried the **real**
`nokkel`, permuted, not the synthetic key (prefix agrees with the period
at chance level; prefix totals = true period sizes). Most likely a stale R
session on the safe side (earlier `make_anon()` + new `anon.yml`; the
commit 1bf6908 had both new files). Fixes: `nokkel` in `drop` as well
(fail-safe for older code); `anon_manifest.csv` records the code version
that ran; `Rscript R/make_anon/run_anon.R` runs in a fresh process and
stops before transfer if the synthetic-key check fails. Logged as D-2
(spec §14).
*Resolved 2026-09-11 11:08*: D-2 copy deleted; fresh-process run
verified (manifest `2026-09-11.3`, config hash = committed `anon.yml`;
synthetic `nokkel` prefix = period on every row, numbers 1..n random
within period; timing, gates, perineal block and marginals as before).
*(open: D-1/D-2 assessment, codebooks)*

#### 25. Pooled CS rate below the planning assumption — closed 2026-09-29

*Outcome: No sentence added to the SAP (statistician).*

Open 2026-09-11 to 2026-09-29 (PI 10). The pooled rate (7.5% vs 10.5%
assumed) is noted; the SAP keeps the margin of +1.5 pp without discussing
it at the observed rate ("it is what it is", statistician 2026-09-29).

#### 26. §1.1 table as the endpoint master list — closed 2026-09-11

*Outcome: Adopted. Open follow-up: items 56.*

**§1.1 objectives/endpoints table** is the primary lookup for endpoints
(endpoint list still to be confirmed with the research group).

#### 27. Primary summary measure = absolute RD — closed 2026-09-11

*Outcome: Relative difference supplementary.*

**Primary summary measure = absolute risk difference**, relative
difference supplementary — resolves item 23. Aligned in the §1.2 estimand
sentence and table, §4.1 and §4.1.2.

#### 28. Transition period = design feature — closed 2026-09-11

*Outcome: Treatment attribute and analysis sets, by the randomised schedule. Open follow-up: items 45.*

**Transition period = design feature, not an intercurrent event.**
Handled through the treatment attribute (LCG once implemented; the
transition period belongs to neither condition) and the analysis sets;
membership by the randomised crossover schedule (hospital × date), not by
the documentation form. Treatment row added to the §1.2 estimand table;
rationale corrected (including transition women is anti-conservative for
equivalence) — closes the item 21 wording point. *Open:* §4.1.4 calls the
analysis including transition periods a *sensitivity* analysis, but it
changes the treatment attribute, i.e. a *supplementary* analysis under
E9(R1) — *resolved 2026-09-11 (item 36): moved to supplementary.*

#### 29. Analysis sets — closed 2026-09-11

*Outcome: FAS / PAS / VDS; no per-protocol set.*

**Analysis sets (§3):** FAS (all eligible women, all periods — analysis
including transition periods, trial flow); PAS (FAS minus deliveries in
the hospital's transition period — primary and secondary analyses); VDS
(PAS ∩ vaginal delivery). The principal-stratum exclusion (§1.2) applies
within each set. **No per-protocol set**: post-randomisation deviations
are handled through the estimand (ICH E9(R1)), not by analysis-set
selection.

#### 30. Vaginal-birth-only endpoints — closed 2026-09-11

*Outcome: Principal stratum in the VDS; composite supplementary in the PAS.*

**Vaginal-birth-only endpoints** (perineal support, episiotomy): CS is an
intercurrent event handled by a principal-stratum strategy, estimated in
the VDS; supplementary composite strategy (CS = no event) in the PAS
(§1.3). Episiotomy moved to the VDS in the §5.1.1.1 table (was "Imputed
with No" on all women). *Open (closed 2026-09-11 — all vaginal deliveries, item 38):* instrumental deliveries in the VDS (PI
question).

#### 31. Primary endpoint missing data — closed 2026-09-11

*Outcome: None at blinded review; complete case as fallback. Open follow-up: items 53.*

**Primary endpoint — missing data at blinded review: none.** Final
export (9 Sep 2026): `forlosningsmetode` (source of ICS) recorded for
36,324/36,324 women, and `cx_akutt_sectio` for every intrapartum CS, so
PSTRFL is fully determined. Checked on the anonymised copy, whose column
value multisets (NA included) equal the source; no allocation information
used. SAP §1.2 estimand table and §4.1.2 now state this, keeping
complete-case handling as the fallback. *Lock check*: repeat on the locked
database (safe side).

#### 32. Non-inferiority with superiority step — closed 2026-09-11

*Outcome: Upper 95% CI limit < +1.5 pp, then < 0 (fixed sequence). Open follow-up: items 25.*

**Primary hypothesis = non-inferiority** (statistician, 2026-09-11).
Standard of care (WHO partograph) vs new care (LCG): a lower CS rate with
the LCG is favourable, not a failure of equivalence. H0: RD (LCG − WHO) ≥
+1.5 pp; non-inferiority concluded if the upper limit of the two-sided
95% CI < +1.5 pp (one-sided α = 2.5%). The protocol's design section
already says non-inferiority; its sample size was calculated for
equivalence (two one-sided tests) with the same margin, which gives at
least that power for the single NI test — over-powered, and the realised
N exceeds 23,650. Written into SAP §2.1, §10 (dated, pre-lock, no
unblinded data) and §11 (protocol text untouched); supersedes item 17.
"Equivalence" wording in §1.2/§1.3/§3 changed to non-inferiority; the VDS
principal-stratum assumption no longer leans on the primary result. Note
for the margin justification: at the observed pooled rate (7.5%) +1.5 pp
is a ~20% relative increase (~14% at the planned 10.5%).
*Code (phase 3)*: `make_rdeff` `eq_p` (TOST) → one-sided NI p-value vs
+0.015; `cfg$analysis$eq_margin` → `ni_margin`.
*Decided 2026-09-11*: superiority step added — tested only after
non-inferiority is shown; concluded if the upper 95% CI limit < 0 (fixed
sequence, no α adjustment; SAP §2.1, §2.2 — secondary endpoints remain
unadjusted). *Code*: add a one-sided superiority p-value next to the NI
one.

#### 33. Principal stratum = 5 cm, symmetric — closed 2026-09-11

*Outcome: SENS1 treatment policy → SUPP1; 4 cm threshold → SUPP2 (item 36).*

**Principal stratum = 5 cm, symmetric** (statistician and PIs,
2026-09-11). The tools define active labour differently (WHO 4 cm, LCG
5 cm), so "in need of a partograph" is tool-defined; the estimand targets
women who reach 5 cm without a CS (CS at ≤ 4 cm excluded in both periods,
as `PSTRFL` already implements). LCG-period CS at 4 cm *are* recorded, but
registration may be incomplete — hence 5 cm stays primary. SAP §1.2
(intercurrent-event row) and §2.3 rewritten: membership is determined
during labour, not at baseline; assumption = the tool does not affect CS
before 5 cm; residual bias (partograph-prompted CS at 4 cm excluded from
the WHO period) runs against the LCG, i.e. conservative for NI. §4.1.4:
SENS1 = treatment policy (all PAS women, no exclusion); SENS2 = 4 cm
threshold (CS at 4 cm counted in both periods; incomplete LCG capture
would favour the LCG). Resolves items 3 and 19. *Note*: only 5 CS are
below 4 cm in the final export, so SENS1 and SENS2 will be nearly
identical — kept as two analyses (statistician, 2026-09-11): they answer
different questions (treatment policy vs choice of threshold).

#### 34. Covariate adjustment set — closed 2026-09-11

*Outcome: Robson, age, BMI, height, birth weight, GA (splines, missing indicator); blinded covariate check.*

**Covariate adjustment (§4.1.3) — decided 2026-09-11.** Primary model
adjusted for Robson group (9 groups), maternal age, pre-pregnancy BMI,
height, birth weight (first twin) and Norway vs other origin; continuous
covariates as restricted cubic splines (3 knots, 10/50/90th pct).
Hospital-level covariates and stratification factors not added (constant
within hospital; absorbed by the random cluster effect). Missing
covariates: missing-indicator method (replaces the §2.4 random-draw
rule). Secondary endpoints: adjustment set per endpoint after blinded
review (§5 pass). Remaining list → baseline table; birthweight
percentiles dropped. Covariate derivations added as SAP §12.2.
Resolves items 8 and 18. *Data (anon, real marginals)*: education 7.9%
missing, origin 3.4%, others ≤ 1%; Robson, parity, previous CS,
induction, age complete.
*Later 2026-09-11*: splines are the default for continuous covariates
in the secondary analyses too, unless stated per endpoint. Education
(and the other listed characteristics) to be decided after a **blinded,
pooled safe-side check** of prognostic strength:
`Rscript R/blinded_review/covariate_check.R` — no treatment, time or
hospital in the model, period label dropped, aggregate output only
(drop-one LR tests, candidates added one at a time, c-statistics). Not
possible in dev: permutation breaks covariate–outcome links.
*Result (statistician, safe side, 2026-09-11)*: strongest predictors
Robson group, height, birth weight, age, BMI and gestational age;
education and hypertensive disorders borderline by LR. **Gestational age
added** to the set (Robson separates only term/preterm); education and
hypertension not included. SAP §4.1.3 updated, with the blinded-review
basis stated. Norway vs other contributed little — **dropped**
(statistician). Final set: Robson, age, BMI, height, birth weight,
gestational age. *Code*: `cfg$analysis$covariates` = ROBSON, AGE,
BMIPREG, HEIGHT, BWT, GA; AGE (from `alder`) and GA in ADSL.

#### 35. Marginalisation — closed 2026-09-11

*Outcome: G-computation over the random cluster effect (Gauss–Hermite).*

**Marginalisation (§4.1.2) — decided 2026-09-11: G-computation**
(standardisation) over the analysis set, integrating over the random
cluster effect (Gauss–Hermite); absolute RD primary, ratio
supplementary; delta-method SEs; the 95% CI gives the NI/superiority
conclusions. Resolves item 16. *Code*: current `make_rdeff` uses
`re.form = NA` (cluster effect at 0) — switch to integration.

#### 36. Sensitivity vs supplementary (ICH E9(R1)) — closed 2026-09-11

*Outcome: Sensitivity: unadjusted, hospital fixed; supplementary 1–4.*

**§4.1.4/§4.1.5 restructured per ICH E9(R1) — decided 2026-09-11.**
Sensitivity (same estimand): (1) unadjusted model, (2) hospital as fixed
effect. Supplementary (different estimand): (1) treatment policy for
CS < 5 cm, (2) 4 cm threshold, (3) transition periods included as
control (FAS), (4) exposure-time model — separate LCG effects for the
first 5-week step after transition and later steps (Kenny et al. 2022).
Resolves item 28's open point.

#### 37. Secondary endpoint list reconciled with §1.1 — closed 2026-09-11

*Outcome: Cord pH and tear grade added; perineal support definition. Open follow-up: items 47, 52.*

**Secondary endpoint list reconciled with §1.1 (statistician,
2026-09-11).** §1.1 is the master list; "\*" = primary analysis in this
SAP, further detail in other SAPs (so \* endpoints stay in §5.1.1).
Changes: cord pH < 7.00 added to §5.1.1.2 (D, worst baby, CC among babies
with a measured arterial pH); "Perineal support" → "Occurrence of perineal
support" (definition = recorded technique: Ritgen/modified Ritgen or
supporting flat-hand grip); "Degree of perineal tears" (\* in §1.1, was
missing from §5.1.1) added — Ord (none/1st/2nd/3rd–4th = OASIS), CC, VDS;
time from 5 cm → "to **vaginal** delivery" in §1.1 and §5.1.1.1;
§5.1.1.2 converted to a grid table; Apgar missing handling = CC (4
missing). VDS endpoint lists in §1.3/§3 now include perineal tears.
*Data (anon, real marginals/within-block)*:
- cord pH: arterial measured in 72.5% (27.5% missing — selective
  sampling? ask DM/PIs; check by hospital at blinded review); pH < 7.00
  in 124 women (0.47% of measured). **28 arterial and 47 venous values
  outside 6.5–7.8** (decimal slips, e.g. 73601) — cleaning rule at blind
  review.
- perineal support among vaginal deliveries: 28,957 yes / 641 no /
  **4,014 missing** → 97.8% of recorded are "yes"; imputing "No" makes
  "no" ~6× more common than recorded — the estimate would reflect
  documentation. *Open (closed 2026-09-11 — effect endpoint with multiple imputation, items 38, 41(10))*: keep as an effect endpoint (and missing-data
  rule), or descriptive only; also whether it moves from §12.1 into
  §1.1.
- perineal tears among vaginal deliveries: 16,929 yes / 16,307 no / 376
  missing; grades 1st 7,857, 2nd 8,569, 3a–4 556.
*Code (phase 3)*: ADEFF lacks cord pH (worst baby, with plausibility
limits) and degree of perineal tears (ordinal); PERSUP/EPIS/tears on
`VDSFL`.

#### 38. PI/DM meeting answers — closed 2026-09-11

*Outcome: Consequences implemented in SAP and code.*

**PI/DM meeting answers (2026-09-11)** — see the answers section of
`questions_PI_DM.md`. Consequences:
- `swap` legacy → dropped in `anon.yml` (next safe-side run); no bearing
  on item 22.
- `ny*` = typed copies of the timestamps (items 13, 24): either may be
  used; prefer the typed `ny*` in ADSL/ADLP.
- Period and step from hospital × **time of birth** (resolves item 11);
  `nokkel` prefix should match the file; SAP §3/§1.3/§1.2 updated.
- `alder` = age at admission, whole years (§12.2); continent grouping
  for country of origin (item 7; lookup still to build).
- Occurrence of perineal support = analysis variable, VDS = **all**
  vaginal deliveries (item 10); missing = **not recorded** → the
  "impute No" rule is withdrawn, handling to be decided — *closed: multiple imputation, item 41(10)* (§5.1.1.1 cell
  says so); support technique = descriptive (§5.1.1.3). Both moved from
  §12.1 into §1.1.
- Perineal tear = categorical 0–4 (3a–3c → 3), §5.1.1.1.
- CS at 4 cm in the LCG period registered → SENS2 wording (§4.1.5).
- Open for later: labour progression / time zero (items 5, 20; *closed 2026-09-11, item 39*), DM 6/8/
  9/10, PI 1/2.

- *Pipeline consequences (phase 3)*: ADSL needs the calendar-assigned period
  (TRT01P), `TRNSFL`, and population flags `FASFL`/`PASFL`/`VDSFL`;
  `cfg$analysis$popfl` / `filter_pop()` move from FAS to PAS; ADEFF perineal
  support and episiotomy analysed on `VDSFL`, plus the composite
  supplementary on PAS.
- *Flagged for later passes*: §1.3 bullet "outcome events at ≤ 4 cm are
  removed" — for secondary endpoints this is also an outcome-window question
  (are events before 5 cm counted?), separate from the principal stratum —
  settle in the §5 pass. (NI vs equivalence: item 32; principal-stratum
  wording: item 33.) *2026-09-11*: decided per endpoint in item 41(3)–(5);
  §1.3 reworded.

#### 39. Labour progression, time zero, 5 cm window, time-to-event model — closed 2026-09-11

*Outcome: Labour-curve model; 5 cm time multiply imputed (m = 30); Weibull mixture, RMST to 24 h. Open follow-up: items 54, 55.*

**Labour progression, time zero, outcome window — for discussion; CS
rule for time to vaginal delivery decided (statistician, 2026-09-11).**
- *Data (anon copy; within-row timings are real)*: `cx_k` behaves as the
  time of the vaginal examination at which *k* cm was found (DM 6,
  empirically — confirm with the DMs): 24,833 women have gaps between
  observed cm, no tied times, and the median time from the first exam at
  ≥ 5 cm to birth falls with the dilation found (5 cm 5.2 h, 6 cm 3.7 h
  … 10 cm 0.4 h). First exam at ≥ 5 cm: 5 cm 14,003 (39%), 6–9 cm
  16,884, 10 cm 4,859, none 578. The 5 cm time is bracketed below by an
  exam < 5 cm in ~70% (median width 2–3 h, 90th pct 7–12 h); the rest
  have no lower bound. Admission → birth: median 10 h, 99th pct 111 h;
  574 admissions after the first ≥ 5 cm exam. Exam times are clock
  times (11% on :00). **Every exam-based time origin depends on
  examination frequency, which the tool may change.** Delivery mode is
  permuted apart from the timings, so dilation × delivery-mode checks
  are not possible in dev.
- *Open, for discussion (all three closed 2026-09-11 — see below and item 41)*: (a) labour-progression endpoint (§1.1,
  §5.1.1.7) — whether in this SAP and with which model (options raised:
  defer to the labour-progression SAP; interval-censored per-cm
  durations; v0.8 LMM); (b) time zero for time to vaginal delivery
  (first exam ≥ 5 cm with dilation as covariate; admission;
  interval-censored 5 cm time); (c) outcome window for amniotomy,
  oxytocin and epidural (at risk at 5 cm; initiation ≥ 5 cm else "no";
  any use). *(c) decided 2026-09-11: item 41(3)–(5).* PI 8/9 and DM 6 feed into (a)–(b).
- *Decided*: in time to vaginal delivery, a CS is assigned the longest
  observed time to vaginal delivery + 100 h — a composite (worst-rank)
  strategy; SAP §5.1.1.1 table and §5.1.1.9 updated. "Longest observed"
  specified as over the analysis set, both periods pooled (per-arm maxima
  would build a difference into the imputed values) — *superseded by the Weibull mixture (no +100 h)*; it
  must be taken after the blinded-review cleaning of implausible times
  (item 13), or one entry error sets the value.
- *Methods point (closed 2026-09-11 — Weibull mixture)*: with ~7.5% of the set at one imputed value, a
  Weibull GLMM fit and its model-based median depend on the +100 h
  choice and the Weibull shape is misspecified by the point mass. A
  median (quantile) or rank-based summary is invariant to the imputed
  value as long as fewer than half are CS. Decide with (b).
- *CS handling revisited (statistician, 2026-09-11)*: keep CS in the
  risk set and censor them at the last vaginal birth — the Fine–Gray
  subdistribution set-up for "censoring-complete" data (Fine & Gray,
  JASA 1999); parametric versions Jeong & Fine 2006/2007 (defective
  Gompertz). Makes the +100 h value irrelevant. Checked in dev (all
  women; time zero from the item 39(b) model, one draw; CS in stratum
  2,369 = 6.7%, censored at 66.5 h). Quantiles of the CIF of vaginal
  delivery (h from 5 cm):

  | model | q10 | q25 | q50 | q75 | q90 |
  |---|---|---|---|---|---|
  | empirical | 1.01 | 1.98 | 4.48 | 9.07 | 16.00 |
  | Weibull, CS censored | 0.42 | 1.61 | 5.24 | 13.32 | 26.35 |
  | log-normal, CS censored | 0.91 | 1.96 | 4.60 | 10.77 | 23.15 |
  | log-logistic, CS censored | 0.94 | 2.02 | 4.36 | 9.42 | 20.32 |
  | mixture: P(VD) × Weibull (VD times) | 0.94 | 2.20 | 4.69 | 8.81 | 16.09 |
  | mixture: P(VD) × log-normal | 1.10 | 2.02 | 4.01 | 8.43 | 21.21 |

  A plain Weibull cannot plateau: shape pulled from 1.19 (VD only) to
  0.74, median 17% and 90th pct 65% too long, implied CS mass 1.0% vs
  6.7%. The Weibull mixture (Larson & Dinse, J R Stat Soc C 1985;34:201–211; mixture
  cure model with "cure" = CS) reproduces the whole curve. Same
  pattern with time zero = first exam ≥ 5 cm (Weibull median +10%,
  mixture −1.5%; defective Gompertz fitted the CS mass but median −9%,
  q90 +41%). *Decided — see below.* Scripts in the session scratchpad
  (`subdist_fit.R`, `subdist_imp.R`).
- *Statistician prefers the Weibull mixture (2026-09-11)*; asked how to
  get a treatment effect on time. The incidence part gives an OR/RD
  for eventual vaginal delivery (≈ the complement of the primary
  within the stratum); the latency part gives an AFT time ratio / HR
  (HR = TR^−shape) **conditional on vaginal delivery** — reportable,
  not a causal effect on its own; the mean time is infinite (CS
  never). Overall effect by **G-computation** of the marginal CIF per
  arm: ratio/difference of CIF medians and/or the difference in
  restricted mean time without vaginal delivery up to a horizon τ.
  The two likelihoods factorise → independent estimates; CIs by
  parameter simulation within each imputation, Rubin's rules across.
  Dev demo (one imputed time zero; hospital fixed in the Weibull part,
  cluster effect 0 in the incidence part; no covariates or step; 300
  draws; 51 s including the imputation fit): P(VD) 93.4% vs 93.2%;
  CIF median 4.72 vs 4.64 h, ratio 1.018 (1.000–1.041); restricted
  mean to 24 h 6.77 vs 6.70 h, difference 0.07 (−0.07 to 0.20); TR
  among VD 1.021 (1.003–1.043), HR 0.976 (0.952–0.996). Treatment is
  permuted in dev — machinery check only. Script `mix_gcomp.R`
  (scratchpad). *Summary measure: decided below.*
- ***Decided (statistician, 2026-09-11)*** — *estimator and horizon
  superseded 2026-09-29 by item 60*: **Weibull mixture model**
  (logistic GLMM for P(VD) × Weibull AFT for time among VD); CS are
  neither censored nor given a time (replaces the "+100 h" rule; the
  composite strategy stays). **Primary summary = difference in
  restricted mean time without vaginal delivery over the first 24 h
  after 5 cm** (G-computation; CS contribute the full 24 h);
  supplementary: ratio of CIF medians; components: difference in
  P(VD), TR and HR among VD (conditional on VD, not interpreted
  alone); 95% CIs by parameter simulation within each imputation,
  Rubin's rules across. SAP §1.3 summary-measure list (tears measures
  added too), §5.1.1.1 row and §5.1.1.9 rewritten; Larson & Dinse
  added to the references. Supersedes the "+100 h" decision and the
  Weibull methods point above. *My specification (confirmed 2026-09-11)*: hospital
  as a fixed effect in the Weibull part (no random-effect Weibull in
  the installed packages; ICC ≈ 0.0001), random cluster intercept in
  the logistic part.
- *Code (phase 3)*: `make_rdlp` TTE — per imputed dataset `glmer`
  incidence + `survreg` Weibull latency, G-computed CIF, RMST to 24 h
  and median, simulation CIs, Rubin's rules; drop the `TT5TODLV`
  LMM/Gamma runs.
- *(a) Labour progression — proposal and dev demo (2026-09-11)*.
  Statistician's idea: time from 5 cm to 6, 7, 8, 9 and 10 cm shown as
  a connected "staircase" per arm (as in Zhang et al., Obstet Gynecol
  2010; the LCG time limits come from cm-by-cm analyses, Oladapo et
  al., PLoS Med 2018). Proposal: reuse the reverse-time labour-curve
  model of (b) with treatment × dilation (+ step, hospital, covariates)
  on the vaginal deliveries (principal stratum, as the VDS endpoints).
  Each woman's curve gives τ(k), the hours before delivery at k cm, so
  the time from 5 to k cm is τ(5) − τ(k); G-computation with
  population random-effect draws (common across arms) gives the mean
  hours from 5 cm to each k per arm (the figure); contrast = difference
  in mean time 5 → 10 cm, per-cm differences in the figure; CIs by
  parameter simulation. Time is the natural response, since the data
  record the time at which each cm was found (the v0.8 dilation-by-hour
  LMM does not fit that structure).
  Dev demo (30,673 VD women, 101,737 exams; hospital fixed, no
  covariates or step; 200 draws; 7 s): mean hours from 5 cm to
  6/7/8/9/10 cm = 0.97/1.47/2.02/2.86/3.78 (WHO) vs
  0.99/1.48/2.03/2.91/3.87 (LCG); difference at 10 cm 0.10 h (−0.00 to
  0.18) — null by construction. 0.7% of simulated curves do not
  decrease (random slope) — truncate. In-sample check (10,552 women
  with observed 5 and 10 cm exams): observed 5 → 10 cm mean 4.82 h,
  median 3.66 vs fitted 4.33 / 3.70 — median right, mean ~10% low
  (shrinkage). Caveats: per-cm times are latent (between exams) and
  depend on the spline form; raw consecutive-exam intervals are longer
  (median 1–2 h per cm) because they cannot be shorter than the exam
  spacing; here the 5 cm point is model-based for every woman, unlike
  the observed-or-imputed time zero of (13). Script `lp_curve.R`
  (scratchpad). *Decided — see below.*
- *Decided (statistician, 2026-09-11)*: headline contrast =
  **difference in mean time from 5 to 10 cm** (per-cm differences in
  the figure/table); §12.1 rows "time from one cm to the next" and
  "total time 5 → 10 cm" **kept, with a cross-reference** to this
  endpoint (further analyses in the labour-progression SAP). Approach
  (labour-curve model) pending (*decided below*) — statistician asked what the response
  log(hours to delivery) means; SAP text not yet written.
- ***(a) Decided (statistician, 2026-09-11)***: **labour-curve model**
  (reverse time from delivery; the same model as the 5 cm imputation)
  in the **VDS**, G-computed mean time from 5 cm to 6–10 cm per arm as
  a staircase figure, headline = difference in mean time 5 → 10 cm,
  CIs by parameter simulation; negative simulated times set to 0.
  Replaces the v0.8 repeated-measures LMM. SAP: §1.1 row ("Labour
  progression: time from 5 cm to 6, 7, 8, 9 and 10 cm cervical
  dilatation"), §5.1.1.1 row (VDS, handled by the mixed model/MAR),
  §5.1.1.7 rewritten, §3 VDS and §1.3 VDS bullet (time to vaginal
  delivery = the analysis without the VD assumption), §1.3
  summary-measure list, §12.1 cross-references. **References added at
  the statistician's request**: Zhang et al. 2002 (AJOG 187:824–828),
  Zhang et al. 2010 (Obstet Gynecol 116:1281–1287), Oladapo et al.
  2018 (PLoS Med 15:e1002492) — *cited from memory; verify details,
  and whether Zhang's curves were traced back from delivery or from
  full dilation (SAP wording kept neutral: "the end of labour")*.
- *Code (phase 3)*: `make_adlp` → one exam-level BDS (τ, dilation) for
  VDS women; `make_rdlp` → labour-curve fit (with `nlme`/`glmmTMB`
  for the dilation-specific residual variance), G-computation, figure;
  the current TT5TO6…TT9TO10 per-interval LMMs go.
- §5.1.1.5–6 (C / C\* methods) are now unused by any endpoint —
  candidate for removal (planned earlier, deferred until (a)).
  ***Removed 2026-09-11 (statistician)***, together with the §1.3
  summary-measure line "difference in mean for continuous endpoints"
  (the C/C\* legend stays — the descriptive table uses C\*). **Later
  sections renumber**: repeated measures (labour progression) §5.1.1.7
  → §5.1.1.5, ordinal §5.1.1.8 → .6, time to event §5.1.1.9 → .7,
  sensitivity §5.1.1.10 → .8, supplementary §5.1.1.11 → .9. Section
  numbers in the items of this log written before this point are the
  old ones.
- §5.1.1.5–6 (C / C\* methods) kept until (a) is settled — per-cm
  durations may need them.
- *(b) Model-based imputation of the 5 cm time — tried in dev
  (2026-09-11, statistician's request)*. Reverse-time labour-curve
  model: log(hours to delivery) at each exam = natural spline of the
  dilation found (3 df) + random intercept and slope (on dilation) per
  woman (lme4; exams 3–10 cm, 0 < τ < 72 h; 116,709 exams, 36,189
  women; fit ~1 s). τ(5) is drawn from the woman's predictive normal
  (residual + conditional random-effect variance), truncated to her
  bracket [first exam ≥ 5 cm, last exam < 5 cm], with a tail-stable
  draw. Only vaginal deliveries need it (CS get max + 100 h).
  Validation: women with a 5 cm exam, exams 5..k−1 masked to mimic
  "first found at k cm" (3,000 per scenario):

  | first found at | rule | bias (h) | median abs. error (h) | 90% coverage |
  |---|---|---|---|---|
  | 6 cm | model | −0.13 | 0.97 | 0.91 |
  | 6 cm | first exam | −2.91 | 2.25 | – |
  | 6 cm | midpoint (69% bracketed) | +0.87 | 0.83 | – |
  | 8 cm | model | −0.93 | 1.41 | 0.86 |
  | 8 cm | first exam | −4.34 | 3.55 | – |
  | 8 cm | midpoint (63%) | +0.07 | 1.17 | – |
  | 10 cm | model | −0.66 | 1.46 | 0.82 |
  | 10 cm | first exam | −4.91 | 3.75 | – |
  | 10 cm | midpoint (62%) | −0.52 | 1.32 | – |

  The model removes most of the landmark bias and works for every
  woman; the midpoint is competitive but unavailable for 30–38%.
  Coverage falls below nominal when more exams are missing →
  refine (dilation-specific residual variance, parameter draws).
  Caveats: dev used all women (delivery mode is permuted apart from
  the timings) — production fits vaginal deliveries only with
  treatment, step, hospital, covariates and treatment × dilation in
  the imputation model; assumes women without a 5 cm exam follow the
  same curve given their observed exams. Scripts were in the session
  scratchpad (`t5_impute2.R`, `t5_scen.R`), not in the repo.
- ***(b) Decided (statistician, 2026-09-11)***: **model-based multiple
  imputation** of the 5 cm time for vaginal deliveries without a 5 cm
  exam; where an exam found 5 cm, that exam is time zero (used as
  observed); **no sensitivity analysis**. SAP §5.1.1.1 row and §5.1.1.9
  written (the "no missing data anticipated" sentence replaced).
  *My specification (confirmed 2026-09-11)*: imputation model with treatment,
  treatment × dilation, step, hospital (fixed), primary covariates;
  residual variance by dilation; parameters drawn per imputation;
  **m = 30**; the CS value (longest time + 100 h) determined within
  each imputed dataset.
- *Still open (closed 2026-09-11 — Weibull mixture, below)*: the analysis model for this endpoint — Weibull GLMM vs
  a median/rank summary, given the CS point mass (methods point
  above); and (a) labour progression.
- *Code (phase 3)*: imputation step — lme4 cannot fit a
  dilation-specific residual variance, so `nlme::lme` with `varIdent`
  or `glmmTMB` with a dispersion formula; ADLP `TT5TODLV` from the
  imputed time zero; replaces the current LMM/Gamma runs in
  `make_rdlp`.

#### 40. §5.1.1.4 and §5.1.1.11 aligned — closed 2026-09-11

*Outcome: Dichotomous secondaries: primary model, CIs only.*

**§5.1.1.4 and §5.1.1.11 aligned (2026-09-11).** Dichotomous secondary
endpoints: primary model and G-computation (integrating over the random
effect), absolute and relative differences with unadjusted 95% CIs, no
hypothesis tests or margins, covariates per endpoint after the blinded
review, VDS/PAS as per endpoint, missing data per table. Supplementary
for the VDS endpoints: composite strategy (CS = no event) in the PAS
(item 30). Supplementary "all events" analyses for the intrapartum
interventions wait for item 39(c).

#### 41. Secondary endpoints, one at a time — closed 2026-09-11

*Outcome: All 17 decided; (3)–(5) revised the same day (pre-5 cm use excluded). Open follow-up: items 46, 47, 49, 52, 53.*

**Secondary endpoints, one at a time (statistician, 2026-09-11).**
*(1) Spontaneous vaginal delivery (SVD)* — decided:
- Definition: vaginal delivery without forceps or vacuum, **any
  presentation** (vaginal breech is coded `spontan_vaginal_fodsel`; ~1,200
  breech at birth, Robson 6 + 7 = 1,116). SVD + IVD + ICS exhaust the
  stratum, so RD(SVD) = −(RD(ICS) + RD(IVD)); stated in §5.1.1.4.
- **Twins: woman-level mode = most operative across babies** (CS >
  instrumental > spontaneous) — **also for the primary ICS** (SAP §4.1.1
  updated). 495 twin women; twin 2: 315 spontaneous, 86 instrumental,
  90 CS, **4 missing**. Proposal for the 4: most operative among the
  recorded babies; safe-side table twin 1 × twin 2 mode (number of
  combined deliveries) at blinded review. *Decided 2026-09-11: twin
  1's mode is used when twin 2's is missing (SAP §4.1.1); DM 15.* Until then the §4.1.2 "no
  missing data" statement is verified for twin 1 only.
- Estimand as primary (PAS, 5 cm stratum, treatment policy); covariates
  = primary set; missing-data cell "No missing data observed in blind
  review" (statistician). SAP §5.1.1.1 row and §5.1.1.4 updated.

*(2) Instrumental vaginal delivery (IVD)* — decided: forceps and vacuum
**combined** (vacuum 3,751, forceps 482; 4,233 / 36,324 = 11.7%
pooled). Mode of delivery is one exclusive classification — spontaneous
vaginal / instrumental vaginal / CS; a CS after a failed instrumental
attempt is a CS, never an IVD (95 CS give "failed forceps/vacuum" as
main reason). Twins, stratum, covariates (primary set) and missing-data
wording as SVD. SAP §5.1.1.1 row, §4.1.1 (failed-attempt sentence) and
§5.1.1.4 covariate list updated. *Code*: current `IVD` = `tang`/`vakuum`
on twin 1, which already excludes failed attempts; needs the twin rule.

*(3) Amniotomy* — decided: renamed **"Occurrence of amniotomy during
labour"** (§1.1, §5.1.1.1); event = amniotomy at **≥ 5 cm**; earlier
amniotomy ~~= no event (woman stays in PAS ∩ stratum)~~ → woman
excluded from this endpoint (*revised, see below*); supplementary: any
amniotomy (§5.1.1.11); covariates = primary set.
- *Data (anon; amniotomy, dilation and reason are one permutation block,
  so the cross-tab is valid)*: 12,474 amniotomies (34.3%), 1 missing
  status; dilation ≤ 4 cm 6,304, ≥ 5 cm 6,006, not recorded 164.
  Tool-driven reasons are almost all ≥ 5 cm: WHO action line 414/440,
  LCG first-stage time interval 279/281; 26 of 744 tool-reason
  amniotomies at ≤ 4 cm (20 action line at 4 cm — WHO-prompted events
  missed by the window, small). ≤ 4 cm is mostly "poor contractions"
  (4,363) and "other" (1,296); 5,862 inductions by amniotomy → the
  `amniotomi` item very likely includes induction amniotomy (DM to
  confirm; moot under the 5 cm window).
- Missing: the 164 amniotomies without dilation are **counted as
  events** (statistician); the missing-data cell states the blind-review
  numbers. The 1 woman with missing status: imputed as "no"
  (statistician; replaced complete case).
- *Code (phase 3)*: `AMNIO` from `amniotomi` & (`cervix_apning_amniotomi`
  ≥ 5 cm or blank); `AMNIOANY` = current definition, supplementary.
- §1.3 bullet "outcome events at ≤ 4 cm removed from the analysis set"
  now contradicts the amniotomy rule (earlier events = no event, woman
  kept) — *reworded 2026-09-11* (§1.3: stratum applies; ≥ 5 cm events
  for amniotomy/oxytocin/epidural, earlier → woman excluded from that
  endpoint (revised); no window for the other endpoints).

*(4) Oxytocin* — decided: mirrors amniotomy. Renamed **"Use of
oxytocin during labour"**; event = infusion **started at ≥ 5 cm**
(incl. second stage); started earlier ~~= no event, woman kept~~ →
woman excluded (*revised, see below*);
supplementary: any use; covariates = primary set; 106 infusions without
start dilation counted as events, 1 missing status imputed as "no"
(statistician; replaced complete case).
- *Data (anon; infusion, start dilation, reason, doses one block)*:
  13,417 infusions (36.9%); start ≤ 4 cm 4,303, ≥ 5 cm 9,008 (10 cm
  5,021), not recorded 106. Reasons: poor contractions/other 10,251,
  WHO action line 1,298, LCG first-stage interval 748, LCG second-stage
  394, ward second-stage limits 233, blank 494. Tool-reason starts at
  ≤ 4 cm: 106 of 2,673 (action line 92, 84 of them at 4 cm; LCG 14) —
  WHO-prompted 4 cm augmentation missed by the window, still small.
  3,805 inductions by oxytocin (link not checkable in dev).
- *(Moot after the revision below.)* Accepted consequence: the endpoint
  is *initiation* in active labour —
  an induction infusion running through active labour scores "no" (no
  stop time in the data).
- *Code (phase 3)*: `OXY` from `oxytocin_infusjon` &
  (`cx_oppstart_oxytocin_infusjon` ≥ 5 cm or blank); `OXYANY`
  supplementary; impute "No" only for missing status.

*(5) Epidural* — decided: mirrors oxytocin. Renamed **"Use of epidural
analgesia during labour"**; event = epidural **started at ≥ 5 cm**;
started earlier ~~= no event, woman kept~~ → woman excluded (*revised,
see below*); supplementary: any epidural;
covariates = primary set; 462 epidurals without start dilation counted
as events; 15 women with unknown status (medical pain relief gate
missing) imputed as "no".
- *Data (anon; gate, types and start dilation one block)*: 19,634
  epidurals (54.1%); start ≤ 4 cm 11,444, ≥ 5 cm 7,728, not recorded
  462 → windowed event rate ~22.5%. No reason item, so tool-driven
  starts can't be seen. 60% of epidurals start before 5 cm, so the
  any-use supplementary carries more weight than for oxytocin/amniotomy.
- *Code (phase 3)*: `EDA` from `type_medikamentell_smertelindring
  .epidural` & (`cx_start_eda` ≥ 5 cm or blank); `EDAANY`
  supplementary; impute "No" for missing status (as now).

*Common to (3)–(5) (statistician)*: missing status → "no" (1 amniotomy,
1 oxytocin, 15 epidural). Interventions started before 5 cm (recorded
dilation ≤ 4 cm) are **presented as baseline characteristics** (SAP
§4.1.3, §12.2 rows added). Read as the baseline table, **not** as
adjustment covariates — *confirmed 2026-09-11*: adjusting would condition on events
that, at 4 cm in the WHO period, the partograph may have prompted.
*Code*: ADSL flags for amniotomy / oxytocin / epidural before 5 cm.

*(6) Medical pain relief in labour\** — decided: **any use in labour,
no 5 cm window** (timing recorded only for epidural; the SAP cell says
so); all methods as recorded — epidural, spinal, pudendal, nitrous
oxide, other (the "?" removed); 16 missing status imputed as "no";
covariates = primary set.
- *Data (anon)*: 27,057 yes (74.5%), 9,251 no, 16 missing; among yes:
  epidural 19,634, nitrous oxide 9,715, pudendal 4,739, other 2,937,
  spinal 1,961.
- **Blind-review check (safe side)**: spinal and pudendal × mode of
  delivery (and × perineal tear) — if spinal is mostly CS anaesthesia,
  or pudendal mostly instrumental/repair, the endpoint partly mirrors
  delivery mode; revisit the definition then. Not possible in dev
  (delivery mode is a separate permutation block).
- *Code*: `MEDPR` as now (gate, impute "No").

*(7) Intermittent fetal monitoring\** — decided: **exclusive
intermittent** — intermittent ticked and neither continuous external CTG
nor STAN/internal CTG (SAP and `IFM` unchanged in substance); women
converted to continuous are not events; no 5 cm window (no timing);
"none" (107) and nothing ticked (2) = no event, a ticked intermittent
box overrides "none"; covariates = primary set.
- *Data (anon; the `fosterovervaking.*` checkboxes are one block, no
  NA)*: intermittent 17,028, external CTG 23,571, STAN/internal 22,800,
  scalp lactate 2,440, none 107. Exclusive intermittent 6,145 (16.9%);
  intermittent + continuous 10,883; any continuous 30,073 (82.8%);
  remainder 106 (none 102, nothing 2, lactate only 2) → endpoints (7)
  and (8) are near-complements, RD(7) ≈ −RD(8).
- *DM question*: does "continuous external CTG" also capture the
  admission CTG (`innkomst_ctg`, 24,391 yes)? If so, exclusive
  intermittent is understated.
- *Code*: `IFM` as now (boxes only; handles "none"/no tick); impute
  flag has no effect (no NA).

*(8) Continuous fetal monitoring\** — decided: **D, any continuous**
(external CTG or STAN/internal CTG ticked, with or without
intermittent); "none"/nothing ticked = no event; no 5 cm window;
covariates = primary set; "Cat?" and "?" removed from the SAP row.
30,073 (82.8%): external only 7,273, STAN/internal only 6,502, both
16,298. Type of continuous monitoring stays descriptive (§1.1 #).
*Code*: `CFM` as now.
- **Scalp lactate testing** (reviewers Stivang, Bernitz; 2,440 = 6.7%,
  same block, no NA): whether to add it as an endpoint is **put to the
  PIs** (questions file, PI 11); SAP comment annotated.

*(9) Degree of perineal tears\** — decided: ordinal 0–4 (3a–3c → 3;
highest grade if several are ticked — 61 women), VDS;
**proportional-odds GLMM** (random cluster, treatment, step, primary
covariates): common cumulative OR (Wald 95% CI) **plus G-computed
marginal category probabilities and the RD for grade ≥ 3 (OASIS)**;
missing = complete case (391: 376 no tear status, 15 tear without
grade). SAP §5.1.1.1 row and §5.1.1.8 rewritten. Supplementary
composite (CS = no tear, PAS) as decided (item 30).
- *Data (anon; tears and delivery mode one joint block)*: VDS 33,612 —
  0: 16,307 (49.1%), 1: 7,793 (23.5%), 2: 8,566 (25.8%), 3: 513
  (1.5%), 4: 42 (0.1%). 7 CS carry a grade-1 tear (item 10c).
- *Code (phase 3)*: ADEFF `PERTEAR` (ordinal) on `VDSFL`. `ordinal`
  is **not installed** (add to renv) for `clmm`; the marginal
  probabilities integrating over the random effect need a hand-written
  G-computation (Gauss–Hermite) with delta-method SEs ({marginaleffects}
  support for `clmm` to be checked).
- *Open (statistician)*: a proportional-odds check (e.g. separate
  binary splits or partial PO) as a model diagnostic — not in the SAP.
  *Decided 2026-09-11: leave it out.*

*(10) Occurrence of perineal support* — decided: VDS, primary
covariates, composite supplementary (item 30); missing (not recorded)
handled by **multiple imputation** under MAR (statistician). Resolves
the item 10 / 37 / 38 missing-data point. SAP §5.1.1.1 cell and a
§5.1.1.4 paragraph written; *my specification, confirmed 2026-09-11*: FCS
(chained equations), **m = 20** (≥ % missing), imputation model =
analysis-model variables (treatment, step, **hospital as fixed
effect**, covariates) + auxiliaries vaginal delivery mode, tear grade,
episiotomy (their own missing values imputed in the same run); GLMM +
G-computation per imputed set; Rubin's rules on the RD/ratio.
- *Data (anon; support, tears and delivery mode one joint block)*:
  VDS yes 28,957 (86.2%), no 641 (1.9%), not recorded 4,014 (11.9%;
  spontaneous 11.6%, vacuum 14.0%, forceps 17.2%) → 97.8% of recorded
  are "yes". Tear rate: support yes 51.1%, no 44.7%, **missing 51.0%**
  — the missing group resembles "yes"; tear status is also missing
  more often when support is (3.6% vs 0.8%). 919 "yes" without a
  technique (descriptive type only). CS: 1,279 carry a value (20
  "yes") — outside the VDS.
- Documentation form differs by period, so missingness may depend on
  treatment; MAR given treatment is covered by the imputation model.
- *Code (phase 3)*: `PERSUP` without impute-"No"; MI step (mice) before
  `fit_bin_glmm`, pooling of G-computed RD/ratio. `mice` is **not
  installed** (add to renv, with `ordinal`).

*(11) Episiotomy* — decided: VDS, composite supplementary (item 30),
covariates = primary set, no window; **8 women with missing status
imputed as "no"** (as the other interventions). 7,471 episiotomies
(20.6% of all women). Episiotomy is permuted on its own in the anon
copy, so the VDS rate and episiotomies recorded for CS can't be
computed in dev — **safe-side check** at blinded review. *Code*:
`EPIS` on `VDSFL` (now on the FAS), impute "No" as now.

*(12) Postpartum haemorrhage > 1000 ml* — decided: **> 1000 ml as in
the protocol** (estimated blood loss within 2 h, `blodtap_ml_inntil_
2timer_pp`); **complete case** for the 181 (0.5%) without blood loss
(replaces "Imputed with No" — a clinical outcome, as tears); all women
in PAS ∩ stratum, no window, covariates = primary set.
- *Data (anon, marginal)*: > 1000 ml 3,128 (8.6%); **heaping at exactly
  1,000 ml (595)** — ≥ 1000 would give 3,723 (10.3%); SAP cell states
  that 1,000 ml is not an event. Median 400, 99th pct 2,300, max 7,900
  (6 > 5,000 — plausible for massive PPH, no cleaning rule proposed).
  Blood loss is permuted on its own, so PPH × delivery mode can't be
  checked in dev.
- *Code*: `PPH1000` = `pph > 1000` already; drop impute-"No".
- (13) time to vaginal delivery and (14) labour progression: parked,
  item 39.

*(15) Arterial umbilical cord pH < 7.00\** — decided: worst baby;
**multiple imputation** for missing arterial pH; twins: "any baby
measured" (statistician) — read together with MI as: a woman with at
least one measured baby is scored from her measured babies, MI only
when no baby is measured (*my reading, confirmed 2026-09-11*); implausible values
**flagged to the DMs** (DM 14), handling after the query still open;
covariates = primary set. SAP §5.1.1.2 row and a §5.1.1.4 paragraph
written (the perineal-support MI paragraph moved after the covariate
list with it).
- *Data (anon; arterial/venous pH and BE/BD one block)*: twin 1
  arterial measured 26,332 (72.5%), < 7.00 117; twin 2 328/495, < 7.00
  7. Missing arterial: venous only 5,321, no gas 4,699. Implausible
  (outside 6.5–7.8): 28 twin 1 — 10 (×13), 9, 7.86–8.12 (×4), decimal
  slips 7179/7195/7214/7218/7259/7267/725/74.2/73601, 3290/3372; 1 twin
  2; 47 venous. No plausible rescue would be an event. Paired: 24,731
  with both plausible, arterial − venous median −0.092, **arterial >
  venous 4.3%** (swapped/single-vessel?) — 1 of the 117 events.
- *My specification (confirmed 2026-09-11)*: FCS with PMM on continuous arterial pH,
  then dichotomised; **m = 30** (≥ % missing); auxiliaries venous pH,
  BE/BD, Apgar 1 and 5 min, NICU ≤ 2 h, delivery mode; analysis-model
  variables incl. hospital as fixed effect; Rubin's rules.
- **MAR is doubtful if sampling is selective** → PI 12 (routine vs
  selective cord gas) and a **safe-side blinded check of the arterial
  measurement rate by hospital** (pooled over periods).
- *Code (phase 3)*: ADEFF cord pH parameter (worst measured baby;
  plausibility limits after the DM query); MI step shared with
  perineal support.

*(16) Apgar score < 7 at 5 minutes\** — decided: worst baby among the
babies with a score; **complete case** (4 first-born, 3 second-born
twins without a score); **stillbirths as recorded** (Apgar 0 = event;
no special rule); covariates = primary set. SAP §5.1.1.2 row and
covariate bullet updated.
- *Data (anon; Apgar 1/5/10 one block)*: twin 1 < 7: 516 (1.4%); twin
  2 < 7: 26 of 495; worst baby 542 (1.5%); Apgar 0 at 5 min: 4 (twin
  1); 2 babies not live-born (`levendefodt` is a separate block, so
  stillbirth × Apgar can't be checked in dev).
- *Code*: `APGAR5L7` via `worst()`; make sure a missing twin-2 score
  does not turn a woman's result NA when twin 1 is scored.

*(17) Admittance to NICU within 2 hours\** — decided (carry-over):
worst baby; **no missing data observed in blind review** (replaces
"Imputed with No"); stillborn babies as recorded (not admitted = no
event); covariates = primary set; reasons presented descriptively.
- *Data (anon; admission and reason one block)*: twin 1 1,815 (5.0%),
  twin 2 142 of 495 (29%); reasons: respiratory 689, prematurity 585,
  other 238, suspected asphyxia 165, infection 65, hypoglycaemia 31,
  none given 42.
- *Code*: `NICU2H` as now; impute flag has no effect.

**Pass status (2026-09-11)**: **all §1.1 secondary endpoints done** —
(13) imputed time zero, Weibull mixture, restricted mean to 24 h; (14)
labour-curve model, mean time 5 → 10 cm (item 39). Open
confirmations are now listed at the top of this document: m = 20 /
m = 30 and the MI model specifications (10, 15); twin reading for cord
pH (15); pre-5 cm interventions as baseline table, not adjustment
(3–5); PO diagnostic (9). §1.3 bullet reworded (2026-09-11; revised
below). Questions out: PI 11–12, DM 11–14.

**Revision (statistician, 2026-09-11, later) — (3)–(5)**: women whose
amniotomy, oxytocin infusion or epidural was performed or started at
**≤ 4 cm are removed from the analysis of that endpoint** (at risk at
5 cm; a principal stratum analogous to the primary), replacing
"earlier = no event, woman kept". Unchanged: ≥ 5 cm events, unknown
dilation counted as events (164 / 106 / 462), missing status → "no",
any-use supplementary on all women (now stated to include the excluded
women), pre-5 cm use in the baseline table. SAP §1.3, §4.1.3,
§5.1.1.1 (three rows) and §5.1.1.11 updated.
- Each endpoint now has its own analysis set. Excluded (anon, recorded
  dilation ≤ 4 cm): amniotomy 6,304, oxytocin 4,303, **epidural 11,444
  (31.5% of women)**.
- Assumption (as for the primary stratum): the tool does not affect
  whether the intervention happens before 5 cm. In the WHO period some
  4 cm events are partograph-prompted (action line at 4 cm: amniotomy
  20, oxytocin 84) — excluding them removes WHO-driven events, a small
  bias against the LCG if it lowers intervention rates. Spontaneous
  rupture of membranes before 5 cm can't be identified by dilation, so
  "at risk of amniotomy" is only partly defined.
- *Code (phase 3)*: the ADSL pre-5 cm flags double as per-parameter
  exclusion flags (`AMNIO`, `OXY`, `EDA` analysis rows drop them; the
  `*ANY` supplementaries keep them). Episiotomy is its own
  permutation block in the anon copy, so its auxiliary role can't be
  tested with real associations in dev.
- *Code (phase 3)*: `make_adeff` ICS/SVD/IVD and ADSL `ICSFL`/`PSTRFL`
  from both twins. There is no twin-2 CS dilation variable: a CS for
  twin 2 only (twin 1 vaginal) is at full dilation → `CXCSN` = 10, in
  the stratum (else `PSTRFL` would go NA and silently drop the woman).
  `make_rdeff` runs the secondaries on the FAS
  **without** `PSTRFL` (`pstr = FALSE`) — move to PAS + stratum.

#### 42. Pipeline phase 3: implementation and deviations — closed 2026-09-14

*Outcome: (a), (e), (h), (i) accepted 2026-09-13 (item 43); (j) decided 2026-09-14. Open follow-up: items 44 (b), 52 (c, d), 54 (f, g).*

**Pipeline phase 3 — first implementation (2026-09-11, dev, anon copy).**
Built from the decisions of items 26–41; runs on `20260911_anon`.
- *ADaM*: `metadata/hospitals.csv` (cluster, strata, planned transition /
  LCG step from the randomisation document; tracked target). ADSL: time
  of birth → `STEPN` (26 May → step 12), `PERIODC` by hospital × step,
  `TRT01P` from the schedule (NA in transition), `FORMPER` + discordance
  flag, woman-level `MODE` (most operative; twin 2 missing → twin 1;
  twin-2-only CS → `CXCSN` 10), `PSTRFL`/`PSTR4FL`, `FASFL`/`PASFL`/
  `VDSFL`/`TRNSFL`, `EXPOSN`, `AGE`, `GA`, before-5 cm flags. ADEFF:
  `ATYPE`, `APOP`, `ANL01FL`; all endpoints of item 41 incl. tears,
  cord pH, supplementary and MI auxiliaries. ADLP: one row per
  examination (dilatation, hours to delivery).
  *Dev check*: 36,324 women, steps 1–12 complete, PAS 33,250, VDS
  30,670, transition 3,074; stratum exclusions 343 (4 cm: 5);
  before-5 cm 6,304 / 4,303 / 11,444 — as in the item 41 counts.
- *Analysis*: `rd_helpers.R` (covariate splines + missing indicators,
  binomial GLMM, G-computation over the random effect by Gauss–Hermite,
  NI/superiority, Rubin); `make_rdeff` (primary, SENS1–2, SUPP1–4,
  complete-case secondaries/supplementaries), `make_rdmi` (MI: perineal
  support, composite, cord pH), `make_rdtear` (`ordinal::clmm`, OASIS
  RD), `make_lc` + `impute_t5` (labour-curve fit, 5 cm imputation),
  `make_rdtte` (Weibull mixture, restricted mean to 24 h, median ratio),
  `make_rdlp` (staircase). Report rewritten; tests rewritten/added (6
  files, synthetic fixtures with known truth).
  *Dev result (noise by construction)*: primary RD −0.16 pp (−0.90 to
  0.58), 7 s; singular fit (cluster SD 0 on the anon copy).
- **Deviations / provisional — for the statistician**:
  (a) labour-curve model has a **single residual variance** (SAP
  §5.1.1.5/§5.1.1.7: "may differ by dilatation") — lme4 limitation;
  needs `glmmTMB` (dispersion formula) or `nlme::varIdent`.
  (b) **planned** crossover schedule (PI 1).
  (c) ADLP plausibility 0 < time to delivery < 72 h (provisional, item 13).
  (d) cord pH outside 6.5–7.8 → missing until the DM 14 answer.
  (e) G-computation standard errors treat the cluster SD as known.
  (f) 5 cm imputation redraws the fixed effects per imputation but not
  the variance components / woman-level predictions; labour-progression
  CIs are percentile intervals from fixed-effect draws with the
  random-effect draws held fixed.
  (g) inverted exam brackets (exam < 5 cm after one ≥ 5 cm): upper bound
  dropped.
  (h) **renv not set up**; `mice` and `ordinal` installed into the
  system R library.
  (i) figure colours = the reference palette's first two categorical
  slots (documented as validated); the palette validator itself could
  not be run (no `node`).
  (j) **ordinal model (tears)**: missing indicators with < 10 missing
  values are dropped (value stays median-imputed) — with 1 woman missing
  gestational age the indicator is not estimable in `clmm` (singular
  Hessian; the build failed). Applied only in `analyse_ord` for now;
  glmer/lmer/survreg cope. *To decide*: make it a general rule in
  `prep_covars` (SAP §4.1.3 would then read "a missing indicator where
  at least 10 values are missing") — re-runs all analyses (~45 min).
  If `vcov()` still fails, the covariance given the cluster SD is used
  (noted in the output).
  *Dev result*: tear OR 0.99 (0.93–1.04), OASIS 1.68% vs 1.66%,
  cluster SD 0.004; MI endpoints (`rdmi`, 30 min): perineal support
  RD −0.17 pp (−0.66 to 0.32), cord pH < 7.00 −0.13 pp (−0.36 to 0.09).

#### 43. Statistician's review of the implementation — closed 2026-09-14

*Outcome: Single residual variance; cleaning check; renv; codelists; descriptive tables; general missing-indicator rule. Open follow-up: items 48, 57, 58.*

**Statistician's review of the implementation (2026-09-13).**
- **Single residual variance accepted**: SAP §5.1.1.5 and §5.1.1.7 now say
  "a single residual variance" (deviation 42(a) closed).
- **Crossover dates**: PI 1 rewritten as analysis-blocking — the pipeline
  assigns the period from the *planned* schedule in
  `metadata/hospitals.csv` until the actual dates arrive.
- **Cleaning document**: `docs/sap/data_cleaning_rules.md` (24 rules with
  thresholds, rationale and what the analysis does with the values) and
  `R/blinded_review/cleaning_check.R` — blinded, run on the safe side,
  writes `outputs/cleaning_flags.csv` (record key, rule, variable, value)
  and `outputs/cleaning_summary.csv`. Thresholds in `CLEANING_LIMITS`.
  *Dev run (anon copy)*: 5,980 flagged values in 5,589 records —
  perineal support not recorded after a vaginal delivery 4,014,
  arterial pH above venous 1,074, tear status missing 376, cord pH out
  of range 75, base excess out of range 102, negative or overlong
  cm-to-cm intervals ~200, the rest small. Two rules were corrected
  after that run: below 5 cm only negative or very long (> 14 days)
  examination times are flagged (induction and the latent phase make
  long intervals normal — 434 false flags at 1 cm), and base *deficit*
  has its own range (positive by definition; 208 false flags).
- **Cluster SD treated as known**: accepted (42(e) closed).
- **renv initialised** (42(h) closed): `renv.lock` with 355 packages,
  R 4.6.0, `.Rprofile` activation; the library was hydrated from the
  system library, nothing recompiled. *Safe side*: pull the repo and run
  `renv::restore()`.
- **Figure colours** accepted (42(i) closed).
- **English translations of the coded values**: `metadata/codelists.csv`
  (tracked pipeline input) applied by `decode_cat()` when ADSL and ADEFF
  are built, so all tables read in English. Derived flags still read the
  raw codes. Unknown codes are kept and warned about. The table is with
  the investigators for validation (**PI 13**). Country of origin (148
  values) is *not* translated — it is grouped by continent (item 7, the
  lookup is still to be built).
- **Descriptive tables for the non-binary endpoints** (SAP §6): `rddsc`
  gains `$ordinal` (tear grades by arm, in each endpoint's own set),
  `$numeric` (cord gases, Apgar, blood loss) and `$t5obs` (observed time
  from the 5 cm examination to delivery); report sections added.
- **(j) decided (statistician, 2026-09-14): the rule is general.** A
  missing indicator is included only where **at least 10 values are
  missing**; below that the median alone is used. SAP §4.1.3 says so,
  `prep_covars()` applies it to every model (`cfg$analysis$covariates$
  min_indicator`), and `drop_aliased()` now only removes linearly
  dependent columns (still needed for `clmm`). Closes deviation 42(j).
  **The analyses have NOT been re-run**: every target from `adsl`
  downstream is outdated by design until the statistician has reviewed
  the current output and any further changes are in (~35 min rebuild).
  Affected in the final export: gestational age (1 missing) and birth
  weight (3) lose their indicators; height (118) and BMI (289) keep
  them — so almost no numerical change is expected.

#### 44. Actual crossover dates per hospital — closed 2026-09-29

*Outcome: Step dates = `cfg$sw`, from 08:00; period now from the source dataset (item 62). Open follow-up: item 63.*

Open 2026-09-14 to 2026-09-29 (PI 1). **Answer (investigators,
2026-09-29)**: steps start on Tuesdays 1 Apr (week 14), 6 May, 10 Jun,
15 Jul, 19 Aug, 23 Sep, 28 Oct, 2 Dec 2025, 6 Jan, 10 Feb, 17 Mar and
21 Apr 2026 (week 17) — identical to `cfg$sw` (start 2025-04-01, 5-week
steps). Periods change at **08:00** (SAP v0.82 comments): the LCG form was
used for women entering active labour after 08:00 on the crossover date;
women already in labour stayed on the control form even if they gave birth
later; control and transition (same form) were split by date from 08:00.
With the treatment now taken from the source dataset (item 62), no
hospital-specific calendar is needed for the treatment; `hospitals.csv`
remains for the strata and the blinded form-vs-schedule check (53).

#### 45. Transition-period instructions — closed 2026-09-29

*Outcome: Control form used in transition; split from control by date from 08:00.*

Open 2026-09-14 to 2026-09-29 (PI 2). The control-period form was used
during transition, so the women could not be separated by form; there was
no change in practice on the transition date and staff had not yet been
trained; the data managers split control and transition by the scheduled
date from 08:00 (Stivang, Buerengen, SAP v0.82 comments). Supports
supplementary analysis 2 (transition periods as control; numbered 3
before item 62).

#### 46. Scalp lactate testing as an endpoint — closed 2026-09-29

*Outcome: Later SAP; not mentioned in this SAP.*

Open 2026-09-14 to 2026-09-29 (PI 11). "Occurrence of fetal scalp lactate
testing" becomes an endpoint of a later SAP; no mention or description in
this SAP (investigators). The reviewer comments in the qmd carry a
resolution note.

#### 47. Cord blood gas sampling — closed 2026-09-29

*Outcome: Missing arterial pH MCAR (investigators); MI kept.*

Open 2026-09-14 to 2026-09-29 (PI 12). Investigators: arterial pH can be
assumed missing completely at random. *Decided (statistician,
2026-09-29)*: arterial cord pH < 7.00 stays an analysed secondary endpoint
(v0.82 had changed its §1.1 marker to "#", reverted to "*", as for Apgar
< 7) and the **multiple imputation is kept** (valid under MCAR, recovers
information from venous pH); the SAP states MCAR as the investigators'
assessment. The safe-side measurement rate by hospital (53) remains a
useful check.

#### 48. English codelists — closed 2026-09-29

*Outcome: Validated by the investigators; two labels changed in `codelists.csv`.*

Open 2026-09-14 to 2026-09-29 (PI 13). The investigators validated
`metadata/codelists.csv`; the statistician's edit (uncommitted on
2026-09-29) changes `langsom_fremgang` to "Prolonged labour" (the SAP
wording, item 62) and the second-stage oxytocin phases to "Passive second
stage, descending" / "Active second stage, pushing". The file parses
without problems (trailing space after the closing quote is harmless).

#### 49. Variable semantics — closed 2026-09-29

*Outcome: `cx_k` confirmed; continuous external CTG assumed to include the admission CTG; DM 12/13 as item 62.*

Open 2026-09-14 to 2026-09-29.
- DM 6 **confirmed**: `cx_k` = the time of the examination at which *k*
  cm was found (the 4 cm imputation relies on it).
- DM 11: "Yes, this is assumed" — read as: the continuous external CTG
  checkbox is assumed to include the admission CTG. Consequence: exclusive
  intermittent monitoring may be understated and continuous monitoring
  overstated; one sentence added to both monitoring rows of the SAP endpoint
  table (2026-09-29). *Reading to be confirmed by the statistician.*
- DM 12 and DM 13: answered 2026-09-29 (item 62).

#### 50. CONSORT flow counts — closed 2026-09-29

*Outcome: Not known; flow from the export only.*

Open 2026-09-14 to 2026-09-29 (DM 10). The numbers of women who declined or
were excluded before export are not known. The CONSORT flow starts from the
export (FAS) and shows the transition periods and the principal stratum.

#### 51. Updated codebooks — closed 2026-10-02

*Outcome: Generated in dev from the anonymised final export; no DM delivery needed.*

Open 2026-09-11 to 2026-10-02 (DM 9). The codebooks are documentation only
(the code aligns the files by their variable labels). The anonymiser
preserves every variable's marginal distribution, so a codebook built from
`20261001_anon` (name, full label, type, missing, values with counts,
ranges) equals one from the real export, except for shifted timestamps
(format and range only), the synthetic `nokkel` and dropped columns; free-
text fields as counts only. To implement: script writing
`metadata/codebook_20261001.txt`; the two Stata codebooks kept as the
September archive.

#### 54. Remaining implementation deviations — closed 2026-10-02

*Outcome: (f) and (g) accepted; no SAP text.*

Content as logged while open:

52. **Final blinded data review before database lock** (statistician;
    restated 2026-09-29). The export has been updated and is now considered
    final, but no new checks have been run on it. Before database lock and
    SAP signing, run on the final export in the safe environment:
    `Rscript R/blinded_review/cleaning_check.R`, `Rscript
    R/blinded_review/blinded_checks.R` (53) and the pipeline in sham mode;
    confirm the primary-endpoint missing-data statement (31) and the
    blinded counts quoted in the SAP (4 cm exams, CS, missing-data
    columns). The dev anonymised copy (`20260911_anon`) predates the update:
    re-run `Rscript R/make_anon/run_anon.R` on the final export (safe side)
    if the mock-up should use it. *2026-10-14*: add a check for women without a live fetus at admission
    (FASFL is "Y" for all rows; SAP v1.0 population, item 69). *2026-10-14*: `sap_numbers.R` run on the final export in the
    safe environment (`outputs/sap_numbers.csv`, aggregate). All SAP v1.0
    figures confirmed except two, updated in the SAP: OASIS missing in the VDS
    362 (1.2%) (was 391 over all vaginal deliveries; the no-status / no-grade
    split is not in the output and was dropped), and from the 4 cm examination
    to delivery > 24 h 1.5% (was 1.8%), mean of min(T, 36 h) 7.5 h (was about
    8 h; the 0.3 h per percentage point of CS is unchanged). Not covered by
    `sap_numbers.R` and kept from the anonymised copy (single permutation
    block, so exact): fetal monitoring 107 "none" / 2 nothing ticked, Apgar
    missing for 3 second-born twins. Pooled CS 2,727 (7.5%; not quoted in the
    SAP). Still to run on the safe side: `cleaning_check.R`,
    `blinded_checks.R` (item 53) and the live-fetus check. *2026-10-02*: new copy `20261001_anon`
    in use (item 59). `Rscript R/blinded_review/sap_numbers.R` prints all
    pooled numbers quoted in the SAP — send `outputs/sap_numbers.csv`
    (aggregate) to dev to update the SAP. Already updated from the anon copy
    (exact single-variable counts): N 36,322, period sizes, epidural 16,
    arterial pH 27.6% / venous only 5,328 / no gas 4,697. Known mismatch: the
    SAP's perineal support "4,014 (11.9%) in the vaginal delivery set" and
    tears "391" are counts over all vaginal deliveries incl. the transition
    period; within the VDS the anon copy gives 3,678 (12.0%) and 361 —
    replace with the safe-side VDS figures. On the anon copy the birthweight
    percentile is meaningless (birth weight and gestational age are in
    different permutation blocks; 15.6% SGA / 13.9% LGA); the computation
    is validated by `test-make_adsl.R`. Earlier content of this item:
    **Run the cleaning check and query the flagged records** (from 12, 13,
    14, 37, 41(1), 41(15), 42(c)–(d), 43). `Rscript
    R/blinded_review/cleaning_check.R` → `outputs/cleaning_flags.csv`
    (record keys — for the data managers, stays in the safe environment) and
    `outputs/cleaning_summary.csv` (aggregate). *Fixed 2026-09-14*: the
    runner called `make_raw_norwel(cfg)`, which in `sham` mode reads the
    anonymised copy even on the safe side (synthetic keys, useless to the
    DMs); it now always reads the real export (`--anon` for dev). Pending
    the answers:
    - provisional thresholds of rules 3–4 (examination and cm-to-cm times),
      13 (cord pH 6.5–7.8) and 16 (blood loss); the limits in
      `make_adlp.R`, `make_adeff.R` and `CLEANING_LIMITS` must then agree;
    - cord pH cleaning rule after DM 14 (now: out of range → missing, then
      imputed);
    - DM 15, twin-2 mode for 4 women (rule decided: twin 1's mode if not
      completed at source);
    - DM 8, confirmation that CS dilation was corrected at source;
    - DM 2 / DM 7 remainders (implausible timestamps; perineal values
      recorded after a CS). *Closed 2026-10-14*: database locked (no further updates possible). SAP numbers confirmed on the final export (`sap_numbers.R`). No woman was included with a dead fetus at admission (checked by the statistician). The cleaning check is no longer needed: queries can no longer change the locked database.

53. **Blinded aggregate checks — scripted 2026-09-14, to run on the safe
    side** (from 22, 31, 41(1), 41(6), 41(11), 41(15)). `Rscript
    R/blinded_review/blinded_checks.R` → `outputs/blinded_checks/*.csv`
    (aggregate counts, no record keys; tests in
    `tests/testthat/test-blinded_checks.R`; `--anon` runs it on the anon copy
    in dev). All tables pooled over periods; only the two period tables
    carry the form period, and they contain no outcome:
    - spinal and pudendal × mode of delivery (and × perineal tear) — 41(6),
      DM 13;
    - episiotomy recorded for CS; episiotomy rate in the VDS — 41(11);
    - arterial cord pH measurement rate by hospital — 41(15), 47;
    - twin 1 × twin 2 mode of delivery — 41(1);
    - documentation-form period vs scheduled period by hospital × step
      (the form period is now the treatment, item 62: the table shows how
      closely the forms followed the schedule), and the first / last birth per
      hospital and form period against the scheduled dates — the observed
      crossover dates, a cross-check for PI 1 — 22, 44;
    - cord gas status also by mode of delivery (selective sampling, PI 12);
    - repeat of the primary-endpoint missing-data check on the locked
      database — 31. *Closed 2026-10-14*: not run; no longer needed after database lock (statistician). The form-period vs schedule and missing-data checks are covered by the final analyses.

54. **Remaining implementation deviations** (from 42(f), 42(g)) — accept
    (and state) or fix. *Explained 2026-09-29; the labour-progression part
    of (f) is moot (removed, item 62):*
    - (f) *Imputation of the 4 cm time is not fully "proper".* For each of
      the m imputed datasets the code draws a new set of fixed effects of
      the labour-curve model from their sampling distribution, and each
      woman's own curve (her random-effect prediction) enters with its
      conditional variance. It does **not** redraw the variance components
      (residual SD, random-effect covariance) or refit the woman-level
      predictions for each draw. Fully proper MI would also propagate that
      uncertainty. With ~30,600 women and ~100,000 examinations the
      variance components are estimated with negligible error, so the
      between-imputation variance is understated by a negligible amount.
      Proposal: accept, no SAP text needed.
    - (g) *Inverted brackets.* The imputed 4 cm time is truncated to lie
      between the last examination below 4 cm and the first at ≥ 4 cm. If an
      examination below 4 cm is recorded *after* one at ≥ 4 cm (dilatation
      going backwards: entry error or examiner difference, item 13), the
      interval is empty; the code then keeps only the lower bound (4 cm
      reached no later than the first examination at ≥ 4 cm). Anon data: 11
      vaginal deliveries with an inverted bracket at 4 cm, 8 of them with an
      examination at exactly 4 cm (observed, no imputation) — 3 women
      affected. Proposal: accept; the blinded cleaning (52) may correct them.
    - ***Decided (statistician, 2026-10-02)***: both accepted, no SAP text.
      (g) is consistent with the retraction seen at the 3 cm CS (65(a)).
      Close at the next update.

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 55. Verify references cited from memory — closed 2026-10-02

*Outcome: All verified (PubMed, full texts); Zhang, Andersen & Keiding, Kenny reworded; Ware Branch D.*

Content as logged while open:

55. **Verify references cited from memory** (from 39(a)): Zhang et al. 2002
    (Am J Obstet Gynecol 187:824–828), Zhang et al. 2010 (Obstet Gynecol
    116:1281–1287), Oladapo et al. 2018 (PLoS Med 15:e1002492); and whether
    Zhang's curves were traced back from delivery or from full dilation (SAP
    wording kept neutral: "the end of labour"). Added 2026-09-29 (item 60,
    from the Cowork proposal): Andersen 2013 (Stat Med 32:5278–5285),
    Andersen & Keiding 2012 (Stat Med 31:1074–1088), Young et al. 2020 (Stat
    Med 39:1199–1236). ***Checked 2026-10-02 against PubMed and the full
    texts (`docs/sap/refs/`)***: all bibliographic details correct; Zhang
    2010 author to be written "Ware Branch D" (PubMed). Content: Andersen
    2013 and Young 2020 support the SAP as written. **Zhang 2002/2010
    anchor the curves at full dilatation (10 cm), not delivery**, because
    "patients were admitted at various points of cervical dilation but all
    ended at 10 cm"; their model is dilatation on time. *Decided
    (statistician)*: reword the imputation sentence ("following the reverse
    approach of Zhang et al. …, who constructed average labour curves with
    time measured backwards from full dilatation, because women are
    admitted at different dilatations but all reach the same end point,
    time is measured backwards from delivery, which is recorded for every
    woman"); move the Andersen & Keiding citation to "an assumption that
    cannot be checked from the data (Andersen and Keiding 2012) and is
    implausible when …"; supplementary 3 "(a two-category version of the
    exposure-time indicator model of Kenny et al. 2022)". To implement with
    65; then close. Larson & Dinse 1985 no longer cited (item 60);
    Oladapo et al. 2018 no longer cited (labour progression removed, item
    62); Zhang et al. now cited in the time-to-vaginal-delivery section.

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 56. SAP ready for circulation — closed 2026-10-02

*Outcome: Comments resolved; §7, §10, §12, version history, abbreviations, legends, AI statement written (v0.84).*

Content as logged while open:

56. **SAP ready for circulation** (from 26). The Word reviewer comments are
    kept as `<!-- COMMENT -->` lines and **do not appear in the rendered
    docx**; 20 of 22 carry no resolution note: fetal-monitoring endpoints
    (qmd lines ~202–206; lactate → 46), missing data overall (~802–803),
    duration as an effect endpoint (~973), need for sensitivity analyses
    (~1263–1264), safety analyses (~1292), exposure / fidelity parameters
    (~1330–1332), adverse events (~1362–1363), template placeholders
    (~1392, ~1408, ~1441, ~1488). Also: the research group to confirm the
    §1.1 endpoint list. *2026-09-29*: the 21 comments of v0.82 added as
    COMMENT lines with resolution notes (item 62); line numbers above have
    shifted.
    ***Decided (statistician, 2026-10-02) — to implement with 65:***
    - A: resolve with a note, no text change — fetal-monitoring comments;
      "missing data overall"; "duration as effect endpoint"; "sensitivity
      analyses — are we sure?"; §8.1 "Anything?".
    - §7 heading "Safety Analyses" (no "[Other]"); text: "There are no
      separate safety analyses. The maternal and neonatal safety outcomes —
      postpartum haemorrhage > 1000 ml, Apgar score < 7 at 5 minutes,
      arterial umbilical cord pH < 7.00 and admission to the neonatal
      intensive care unit — are secondary endpoints and are analysed in
      Section 5."
    - §7.2: "Adverse events are not collected systematically and are not
      analysed. Serious and unexpected adverse events are reported by the
      principal investigator to the ethics committee (protocol section
      9.1). Serious maternal and neonatal outcomes are covered by the
      secondary endpoints (Section 5)." (REK 2024/603063; no regulatory
      reporting requirements — not stated.)
    - §7.3: kept, "Not applicable."
    - §7.1: "Extent of exposure is not applicable: the intervention is a
      labour-monitoring tool used at the unit level, and treatment is
      defined by the documentation form (Section 3). The use of the LCG in
      practice is described descriptively through the LCG-specific items
      (shared decision making, labour companionship, Section 5.1.1.3);
      health care providers' experience with the LCG is reported in a
      separate publication (Section 12.1)."
    - §10: eight changes against protocol v1.06, each "decided before
      database lock without access to unblinded data" (no dates, also for
      the existing non-inferiority entry): (1) non-inferiority; (2) absolute
      RD primary summary measure (protocol: RR), RR supplementary, both
      marginal; (3) no hypothesis tests for secondaries (protocol: cluster-
      adjusted significance test); (4) covariate adjustment; (5) estimand
      framework — treatment policy, treatment by documentation form,
      transition periods excluded from the PAS, principal stratum for the
      primary, composite / principal-stratum strategies for secondaries;
      (6) protocol "subgroup analyses" of LCG elements not done (post-
      randomisation, LCG period only), reflected in the 5 cm stratum / 4 cm
      windows and the SDM description; Robson subgroup added; (7) no as-
      treated / per-protocol (IPW, g-estimation) analyses — no individual
      adherence measure, negligible missing data; (8) labour duration as
      time from 4 cm to VD (restricted mean); other endpoints deferred to
      later SAPs (scope, §12.1).
    - §12: one sentence that table and figure layouts are given by the
      mock-up statistical report on anonymised data (no path).
    - Version history: "This statistical analysis plan (SAP) for NORWELCG
      is based on protocol version 1.06, dated 9 May 2024" (1.06 is the
      final protocol version); one row "1.0 | [date of signature] | Not
      applicable | Original version"; drafts keep `sap-version` 0.84 …
      until signature.
    - List of abbreviations: BD/BE, BMI, CC, CEQ2, CTG, FAS, HC3, ICC, ICH,
      IM/IV, LCG, MAR, NORBIRTH (Norwegian Network for Obstetric Research),
      PAS, SAP, STAN, TTE, VDS, WHO. Endpoint-category legends trimmed to
      the categories used (C\*, D, Cat, Ord, TTE); "MN;" typo removed.
    - D: §1.1 endpoint list confirmed by the investigators' v0.82 edits.
    - **Cord pH: MAR instead of MCAR** (statistician, 2026-10-02): SAP
      §5.1.1.4 "Missing values are assumed to be missing at random: whether
      the arterial pH was recorded may depend on the hospital, the time
      interval, the mode of delivery and the condition of the baby as
      reflected in the auxiliary variables (venous pH, base excess, Apgar
      scores, admission to the neonatal intensive care unit), but not on
      the unrecorded value itself given these. All these variables are in
      the imputation model. The investigators consider the sampling
      unrelated to the condition of the baby, which is consistent with this
      assumption." `make_rdmi.R` comment to match; supersedes item 47's
      "MCAR".
    - **Use of AI tools** (statistician, 2026-10-02): new subsection at the
      end of §2 General Considerations: "The statistician used Claude Code
      (Anthropic), an AI coding assistant based on large language models,
      in the development of this SAP and of the analysis code. It was used
      to draft and revise SAP text, to check consistency between the SAP,
      the analysis code and the mock-up report, to write and test the
      analysis code, and to verify cited references against their full
      texts. All analytical decisions were made by the statistician and the
      investigators; every AI-generated text and code change was reviewed
      by the statistician, who takes full responsibility for the content.
      Claude Code worked only in a development environment with an
      anonymised copy of the data (study period, hospital, timings and
      outcomes permuted or shifted, record keys replaced); it had no access
      to identifiable data or to the true allocation, and the analyses of
      the real data are run in a secure environment without access to AI
      tools. Decisions and their rationale are documented in a
      version-controlled review log kept with the analysis code." No model
      version; the review log is to be published (item 66).
    - **52 decisions**: export final, no more cleaning at source; the
      "in the analysis" column of `data_cleaning_rules.md` is the final
      handling. Kept as recorded: anthropometric extremes, head
      circumference 19 cm, blood loss > 5000 ml, arterial > venous pH.
      Set to missing: cord pH outside 6.5–7.8 (no decimal-slip
      correction); base excess / deficit outside −30 to 10 / −10 to 30.
      Exam window: one rule, time to delivery ≤ 0 or ≥ 72 h → examination
      not used (all dilatations; as coded); rule 4 limits "from 4 cm";
      `CLEANING_LIMITS$exam_h_lo` dropped. Items 13, 14, 15 to close. New
      aggregate-only helper `R/blinded_review/sap_numbers.R` printing the
      blinded numbers quoted in the SAP. Codebooks (51) by the statistician
      on the safe side. Implement first, dev rebuild, then commit/push
      (check `.gitignore`: `docs/sap/refs/`, `~$*`, working docx,
      `outputs/`), then the safe-side run.

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 58. Country of origin → continent lookup — closed 2026-10-02

*Outcome: `metadata/country_continent.csv` (UN M49); CONTINENT in ADSL; Norway row kept.*

Content as logged while open:

57. **Rebuild** (from 42(j), 43, 61, 63; again from 2026-10-02 for the
    implemented items 13–15, 54–56, 58, 64(a), 65 and the new copy
    `20261001_anon`). Every target from `adsl`
    downstream is outdated: the general missing-indicator rule (2026-09-14)
    and the SAP v0.83 code (2026-09-29). Not run — waiting for the
    statistician's go-ahead (`tar_make()` in sham mode, dev; ~45 min). The
    code has been run end to end outside `targets` on the anon copy (item
    63).
    `cfg$analysis$eq_margin` removed 2026-09-29. *Closed 2026-10-14*: full `tar_make()` run by the statistician on the SAP v1.0 code.

58. **Country of origin → continent lookup** (from 7, 43):
    `metadata/country_continent.csv` (148 values) for the baseline table;
    not built. ***Decided (statistician, 2026-10-02)***: one row per export
    value (Norwegian name, English name, continent); continents Europe
    (including Norway), Asia, Africa, Americas (one group), Oceania (own
    category); transcontinental countries by UN M49 (Turkey, Cyprus,
    Georgia, Armenia, Azerbaijan, Kazakhstan → Asia; Russia → Europe; Egypt
    → Africa), not named in the SAP. The "Norway yes/no" baseline row is
    kept; add it to SAP §12.2 ("Country of origin Norway | landbakgrunn |
    Norway vs other").

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

#### 59. Anonymisation follow-ups — closed 2026-10-02

*Outcome: New copy `20261001_anon` verified; `anon.yml` mirrored; no trial-specific DPO assessment; linking list held by the PIs. Open follow-up: item 66.*

Content as logged while open (from 24, 38). *2026-10-01/02*: final
    export anonymised on the safe side → `data/raw/20261001_anon`
    (code `2026-09-11.3`, 36,322 rows — 2 fewer in control). The final
    export has no `ny*` typed timestamps, so `nyfodselstidspunkt` was
    removed from `anchor:` on the safe side; mirrored in dev (config hash
    `0509fe1f…` reproduced exactly; `ny*` entries left under `timing:` /
    `timing_gates:` are absent and ignored). Dev checks: synthetic keys
    (prefix = permuted period, 1..n within prefix), births inside the
    window, within-row intervals as before, no `anon_keys`. `cfg$export`
    → `20261001`. *Commit `anon.yml` before the next safe-side pull.*
    - DPO assessment of deviations D-1 and D-2 and of the relative-
      anonymisation basis (`docs/data_anonymisation_specification.md` §14);
    - `swap` is dropped in `anon.yml` but still present in the current copy
      (`20260911`) — gone at the next safe-side run; no new run is needed
      for that alone;
    - DM 3 remainder: who holds any list linking `nokkel` to hospital
      records, and is `nokkel` stable across exports (specification).

*Closed 2026-10-02 (statistician)*: the DPO is not involved for this
trial specifically; the general handling of relative anonymisation is
being clarified in an external process. DM 3: the list linking `nokkel`
to hospital records is held by the principal investigators (one sentence
added to the anonymisation specification). `swap` is not in the final
export copy.

#### 60. Time to vaginal delivery: estimator and horizon — closed 2026-09-29

*Outcome: Difference in mean Y = min(T, 36 h), CS = 36 h, by linear mixed model; replaces the Weibull mixture and the 24 h horizon; 5 cm imputation kept. Open follow-up: items 55, 61.*

**Proposal (Claude Cowork, brought by the statistician, 2026-09-29).**
Written without access to the SAP: time origin 4 cm; Y = min(T, τ) after
VD and τ after CS, τ = 36 h; θ = difference in mean Y = −∫₀^τ (F₁ − F₀) dt
(F = cumulative incidence of VD; Andersen 2013); ANHECOVA with the Ye et
al. robust variance (GEE independence + Mancl–DeRouen if clustered);
pseudo-observations if censored; sensitivity τ = 24/48 h, unadjusted,
subset with an observed time origin; supportive Aalen–Johansen CIFs of VD
and CS.

**Assessment (2026-09-29).**
- The estimand is the one of item 39 (restricted mean time without VD, CS
  contributing the full horizon). What changes is the horizon (24 → 36 h)
  and the estimator: once time zero is imputed, Y is known for everyone
  (no censoring — every woman is followed to delivery, and the birth time
  defines the step), so the mean is estimated directly; no Weibull
  latency model and no parameter simulation.
- Time origin **kept at 5 cm** (protocol endpoint, principal stratum,
  item 39); the proposal's 4 cm reflects Cowork not having the SAP. The
  statistician asked to keep "the current multiple imputation of the time
  at 4 cm" — read as the 5 cm imputation; *to confirm*.
- Not adopted: ANHECOVA / Ye et al. variance and GEE independence with
  Mancl–DeRouen (with 10 clusters in a stepped wedge the within-cluster
  contrasts need the random cluster effect and fixed steps, as for the
  other endpoints); pseudo-observations (no censoring); the
  observed-origin subset (it would drop ~61% of the VDs and no CS, since
  CS need no time zero, inflating the CS share; item 39(b) decided no
  sensitivity analysis for the imputation); the CIF of CS (time zero is
  imputed only for VDs); the median ratio (needed the parametric model);
  TR/HR among VD, replaced by the difference in mean min(T, 36 h) in the
  VDS.
- Blinded numbers (anon copy, `imp5` from the 2026-09-14 build, 30
  imputations; delivery mode is permuted against the timings, so "VD"
  times are a random subset of all times): PAS within the stratum 32,938,
  CS 2,268 (6.9%); time from 5 cm to delivery median 4.0 h, 99th pct
  20.9 h; > 24 h 0.52%, > 36 h 0.09%, > 48 h 0.03%. Mean min(T, τ) among
  VD 5.4–5.5 h. SD(Y) 6.5 / 9.0 / 11.7 h and CS share of Var(Y)
  52 / 74 / 84% at τ = 24 / 36 / 48 h; a 1 pp CS difference moves θ by
  0.19 / 0.31 / 0.43 h. At 36 h the summary measure is mostly the CS
  difference expressed in hours. Script `tau_check.R` (session
  scratchpad).
- ***Decided (statistician, 2026-09-29)***: competing-risk restricted
  mean with CS as unfavourable outcome, τ = 36 h; time-zero imputation
  kept. *My specification (to confirm)*: 5 cm origin; linear mixed model
  as the estimator; the sensitivity, supplementary and supportive
  analyses below. SAP: §1.3 VDS bullet (composite strategy stated,
  censoring rejected) and summary-measure bullet (36 h); §5.1.1.1 row;
  §5.1.1.7 rewritten (Y, estimand, horizon rationale, no censoring,
  linear mixed model, Rubin's rules, components, supportive VD within
  6 h / 12 h and descriptive CIF); §5.1.1.8 sensitivity analyses for this
  endpoint (unadjusted; hospital fixed + HC3); §5.1.1.9 supplementary
  horizons 24 and 48 h; references: Larson & Dinse removed, Andersen
  2013, Andersen & Keiding 2012, Young et al. 2020 added (to verify, 55).
- *Code*: item 61.
- ***Revised 2026-09-29 (item 62)***: time origin **4 cm** (the
  statistician's "4 cm" on 2026-09-29 was intended — it follows the
  investigators' move of the secondary endpoints to 4 cm), 4 cm time
  multiply imputed the same way, and **CS at 4 cm included** (Y = 36 h).
  τ = 36 h kept. Blinded numbers at 4 cm (anon `adlp`, 15,598 women with a
  4 cm exam): time from the 4 cm exam to birth median 6.6 h, > 24 h 1.8%,
  > 36 h 0.2%, mean min(T, 36 h) 8.0 h; 57% of the PAS∩stratum without an
  exam at exactly 4 cm, ~49% without any exam < 4 cm (no lower bracket).

#### 61. Time to vaginal delivery: code — closed 2026-09-29

*Outcome: `make_rdtte` rewritten (LMM on Y, MI of the 4 cm time, Rubin); tested. Open follow-up: item 57.*

Opened 2026-09-29 (item 60), implemented the same day with item 63.
- `impute_t5()` → `impute_t0(lcfit, adlp, cfg, k = cfg$analysis$tte$origin_cm)`
  (4 cm; output `T0`, `T0IMPFL`); target `imp5` → `imp0`, m =
  `cfg$analysis$mi$m_t0` (30).
- `make_rdtte(imp0, adeff, cfg)` returns `$results` and `$cif`. PAS
  including the CS at 4 cm. Per imputation: `lmer` (REML) on Y = min(T,
  36 h) / 36 h for CS — SECONDARY; SENS1 unadjusted; SENS2 `lm` with
  hospital fixed and HC3 (own `hc3_vcov()` in `rd_helpers.R`: `sandwich`
  is not installed, and the formula is five lines); SUPPLEMENTARY horizons
  24 and 48 h; COMPONENT mean min(T, 36 h) in the VDS; SUPPORTIVE VD
  within 6 / 12 h (binomial GLMM + G-computation). Rubin's rules on the
  model-based (SENS2: HC3) variances. COMPONENT P(VD) once, without
  imputation (`analyse_bin`; equals minus primary SUPP1 by the logit
  symmetry). `$cif`: empirical cumulative incidence of VD by arm on a
  0.25 h grid, averaged over imputations.
- `cfg$analysis$tte`: `origin_cm: 4`, `horizon: 36`, `supp_horizons`,
  `supportive_hours`, `cif_step`; `nsim` and `lp` removed.
  `weib_int_surv()` removed.
- Tests: `test-make_rdtte.R` (simulated data, known restricted-mean
  difference inside the CI, all analysis rows, CIF properties; HC3 against
  the textbook formula), `test-make_lc.R` (imputation at 4 cm keeps the
  observed times and the brackets).

#### 62. Investigators' feedback and SAP v0.82 → v0.83 — closed 2026-09-29

*Outcome: Treatment by source dataset; secondaries from 4 cm incl. CS at 4 cm; labour progression removed; pH MI kept (MCAR); Robson subgroup; v0.82 edits ported. Open follow-up: items 61, 63, 64.*

**Input (2026-09-29).** Investigators' answers to PI 1, PI 2, PI 11, PI 12,
DM 12 and DM 13 (items 44–47, 49), and SAP v0.82 (Word; tracked changes
and 21 comments by Therese Buerengen and Maria Cecilie Stivang on v0.81,
some edits untracked — found by a full text diff), with five changes listed
by the statistician: (1) treatment from the source dataset (key prefix
INT / CTR / TRAN), because the new form is directly linked to the change of
tool; (2) labour progression out of this SAP; (3) oxytocin, epidural and
medical pain relief assessed from 4 cm; (4) the same presented
descriptively by cm; (5) time to vaginal delivery from 4 cm — only the CS
endpoint from 5 cm, because of registration problems (CS at 4 cm in the
LCG period were registered retrospectively). v0.81 = the qmd render of
2026-09-14 apart from trivia (checked by diff), so the port is v0.82 → qmd.

**Answers from the investigators.**
- DM 12: `amniotomi` / `oxytocin_infusjon` may include induction use.
- DM 13: spinal / pudendal may include anaesthesia for CS, instrumental
  delivery or episiotomy (recorded against instructions).
- CS before 4 cm were not collected (Stivang); 4 cm CS in the LCG period
  were registered retrospectively.

**Decided (statistician, 2026-09-29, after questions).**
- CS at 4 cm **included** in all secondary analyses; the primary principal
  stratum applies to the primary endpoint and its sensitivity analyses
  only. The retrospective registration is stated (missed cases favour the
  LCG).
- Medical pain relief **unchanged** (any method incl. spinal / pudendal,
  no window — timing is recorded only for epidural); the DM 13 limitation
  is stated in the endpoint row; by-cm presentation for epidural only.
- Cord pH < 7.00 and Apgar < 7 stay analysed (item 47).
- All v0.82 edits ported; subgroups: **Robson only**.

**My specifications and defaults (to confirm).**
- Amniotomy moved to 4 cm as well (v0.82 tracked change by Buerengen; not
  in the statistician's list).
- Steps start at 08:00 (the investigators' split time); a woman in labour
  at a change of period may belong to a period that differs from the
  scheduled period of her birth step.
- Primary supplementary 1 (treatment policy for CS ≤ 4 cm) and 2 (4 cm
  threshold) were identical on these data (no CS < 4 cm) → **merged**;
  transition → 2, exposure time → 3.
- Robson subgroup: treatment × Robson interaction in the primary GLMM, RD
  per group by G-computation, likelihood-ratio test; groups with < 50 CS
  (pooled, known before unblinding) combined; hospital-level subgroup
  variables of v0.82 (hospital, annual deliveries, intrapartum CS rate) not
  used — 10 clusters.
- By-cm tables (exploratory, §6): dilatation at amniotomy, oxytocin start,
  epidural start and induction, by treatment; reason for admission.
- Baseline table: annual deliveries (1000–1999 / 2000–3999 / ≥ 4000),
  contractions at admission, first vaginal delivery (as `FVDFL`),
  induction, birthweight percentile (reference: PI 14 / item 64).
- Kept "Sex of the baby" (v0.82: "Gender") — the variable is biological
  sex. Corrected source variables in §12.2 (`antall_rier_10min_innkomst`;
  onset from `induksjon`).
- Fixed wrong cross-references: estimand table "Section 4.1.4" → 4.1.5
  (twice; the transition and 4 cm analyses are supplementary), §2.3 and
  §3 FAS pointed at the sensitivity instead of the supplementary analyses.

**SAP (v0.83, 29 September 2026).** §1.1 table; §1.2 treatment and
principal-stratum cells; §1.3 (treatment by form, principal stratum not
for secondaries, 4 cm windows, labour progression and its summary measure
removed, time to VD from 4 cm); §2.3; §3 (period by form / key prefix,
step calendar from 08:00, VDS, stratum for the primary only); §4.1.3;
§4.1.5 (merged); §5.1.1.1 rows; §5.1.1.2 text (MCAR); §5.1.1.3 (v0.82
wording, new rows); §5.1.1.4 (mode-of-delivery sentence); **labour
progression section removed — later §5.1.1 subsections renumber**
(ordinal .5, time to event .6, sensitivity .7, supplementary .8); time to
VD rewritten for 4 cm; §6 by-cm presentation; §8.2 Robson; §12.1 heading
and table (v0.82); §12.2 rows; references (Oladapo removed); v0.82 comments
as COMMENT lines with resolution notes. Rendered cleanly (html, scratch
copy); tracked outputs not re-rendered.

#### 63. SAP v0.83 in the pipeline — closed 2026-09-29

*Outcome: Implemented and tested; SUBJID = `nokkel`; full rebuild pending. Open follow-up: item 57.*

Statistician's request 2026-09-29: update the code to SAP v0.83; the
subject id must match `nokkel`.
- **ADSL** (`make_adsl.R`): `SUBJID` = `nokkel`, `USUBJID` =
  STUDYID-`nokkel`; stops if `nokkel` is missing, duplicated or has a
  prefix other than CTR / TRAN / INT, warns if the prefix differs from the
  source file. `FORMPER` from the prefix; `TRT01P`/`TRT01A` from `FORMPER`
  (NA for transition); `TRNSFL` from `FORMPER`; `PASFL` also requires the
  birth inside the inclusion window (all 36,324 in the anon copy).
  `PERIODC` (schedule) and `PERDISFL` kept for the blinded check (53).
  `STEPN` with steps from 08:00 (`cfg$sw$step_start_time`); births before
  08:00 on 1 April 2025 → step 1. `EXPOSN` from the scheduled LCG step for
  `FORMPER` = intervention (at least 1). `PSTR4FL` removed.
  `AMNIOB4FL`/`OXYB4FL`/`EDAB4FL` (≤ 3 cm; `cfg$analysis$from_cm`). New:
  `INDUCFL`, `CONTRADM`, `HOSPBIRC` (from `hospitals.csv` BIRTHS).
- **ADEFF**: 4 cm exclusion flags; descriptive rows carry `ANL01FL` = the
  women the endpoint applies to (CS for the CS characteristics — the
  report no longer counts non-CS women as "missing"); new descriptive
  params `CXAMNIO`, `CXOXY`, `CXEDA`, `CXIND` (dilatation at the
  intervention by cm, "≤ 1 cm" … "10 cm", "Not recorded"; PARCAT2
  "DILATATION AT INTERVENTION"); prolonged-labour and fetal
  presentation/position labels.
- **Analyses**: `make_rdeff` — SUPP1 CS AT 4 CM INCLUDED (= old SUPP1;
  old SUPP2 dropped), SUPP2 TRANSITION AS CONTROL, SUPP3 EXPOSURE TIME;
  secondaries in the PAS without `PSTRFL`. `make_rdmi`, `make_rdtear`
  (TEARC): PAS without `PSTRFL`. New `make_rdsub` (Robson subgroup, target
  `rdsub`). `make_rdlp` and its target removed. `make_rddsc`: new baseline
  rows, 4 cm flags, descriptive endpoints filtered on `ANL01FL`, `t5obs`
  → `t0obs` (4 cm).
- **Report** (`reports/statistical_analysis.qmd`): periods by form,
  merged supplementaries, time to VD from 4 cm (table + CIF figure),
  Robson subgroup section, labour progression removed.
- **Not done**: birthweight percentile (reference standard, item 64);
  country-to-continent lookup (58).
- **Tests**: all 10 files pass (227 expectations): new `test-make_rdsub.R`,
  `test-make_lc.R` (replaces `test-make_rdlp.R`), rewritten
  `test-make_rdtte.R`, updated ADSL / rdeff / rddsc tests. The blinded
  checks run on the new ADSL (anon copy).
- **Integration run** (anon copy, outside `targets`, outputs in the
  session scratchpad; reduced m: 5 for the 4 cm time, 3 for perineal
  support and cord pH): every step ran; adsl 1 s, adeff 14 s, rdeff 93 s,
  rdmi 254 s, rdtear 203 s, rdsub 9 s, lcfit 6 s, imp0 34 s, rdtte 96 s,
  rddsc 4 s. The report renders from these outputs. Checks: P(VD)
  component = minus primary SUPP1 (+0.13 pp vs −0.13 pp); PAS 33,286
  (principal stratum 32,970); 17,560 of 30,714 vaginal deliveries have an
  imputed 4 cm time; Robson groups 6, 7, 8 combined (< 50 CS each).
  Expected full rebuild with m = 30 / 20 / 30: ~45 min (rdtte ~10 min).
- Category order in the descriptive tables is numeric where every
  category carries a number (cm, Robson group, blood-loss bands).

#### 65. SAP ↔ code ↔ report check of the v0.83 build — closed 2026-10-02

*Outcome: (a)–(i) implemented: SAP wording, twin-2 CS, denominators, SDM/companionship LCG-only with `sdm_items.csv`, report fixes.*

Content as logged while open:

64. **Birthweight percentile reference and §12.1 completeness** (PI 14; from
    62). ***(a) Decided (statistician, 2026-10-02, after advice from
    Annetine Staff: not INTERGROWTH-21st; Norwegian population-based MBRN
    reference; Johnsen 2006 for preterm only if many; or birthweight in
    grams)***: both (A) percentile by Skjærven, Gjessing, Bakketeig, Acta
    Obstet Gynecol Scand 2000;79:440–449 (verified, full text in
    `docs/sap/refs/`), Tables IV–V (smoothed mean and SD by sex and
    completed week 20–44, singletons 1987–98) → `metadata/
    bw_reference_skjaerven2000.csv`, percentile = Φ((BW − mean)/SD),
    first baby **including the first twin**, baseline row SGA < 10th /
    AGA 10th–90th / LGA > 90th (bands to be confirmed by the PIs); and (B)
    birthweight categories < 3000, 3000–3499, 3500–3999, 4000–4499,
    ≥ 4500 g. SAP §12.2 rows replace "INTERGROWTH-21st proposed";
    Skjærven added to the references. Caveats (log only): LMP-based,
    1987–98 reference vs ultrasound dating now; 4.2% preterm (1,539; 76 <
    28 weeks) where born-weight percentiles understate growth restriction.
    Johnsen et al. 2006 (Acta Obstet Gynecol Scand 85:286–297) verified,
    not used. Remaining for the investigators: (b), (c) below. Birthweight percentile is back in the baseline table; reference
    standard (INTERGROWTH-21st proposed, or a Norwegian reference) to be
    decided. The investigators to confirm the §12.1 table against the
    protocol (their v0.82 comments). Neonatal mortality vs morbidity (§12.1,
    Stivang comment) is theirs to settle for the neonatal SAP. *Closed 2026-10-14*: birthweight percentile removed from the SAP (v0.9/v1.0); §12.1 completed by the investigators in the returned v0.85.

65. **SAP ↔ code ↔ report check of the v0.83 build** (2026-09-30; full
    `tar_make` of 2026-09-29, 45 min, no errors or warnings, nothing
    outdated). Anon copy: effects are noise; counts below are real marginals
    unless stated.
    *Substantive (decision needed):*
    - (a) **5 CS at 3 cm** in the export (also in DM 8's counts; the
      dilatation at CS travels with the mode of delivery in the anon
      permutation, so they are real). The SAP says CS before 4 cm were not
      recorded (§1.2 cell, §1.3, §4.1.5 SUPP1). Code: excluded from the
      primary (≤ 4 cm), **included** in SUPP1 and all secondary analyses
      (whole PAS). Proposal: ask the DMs whether the dilatation is wrong or
      the women were included in error (DM 8, extended 2026-09-30); keep them
      until answered; SAP wording "were not to be recorded; 5 recorded at
      3 cm are analysed with those at 4 cm".
    - (b) **Twin-2-only CS** (CS of the second twin after a vaginal first
      twin): the descriptive CS characteristics read the first twin's
      columns, so these women show as "missing" (73 in the PAS on the anon
      copy — inflated by the permutation of the twin-2 block; few expected
      on real data), while ADSL sets their dilatation to 10 cm (`CXCSN`,
      SAP 4.1.1). Proposal: `CXCS` from `CXCSN`; presentation, position and
      main reason from the `tv2_` columns; level of the presenting part is
      not recorded for twin 2 (missing).
    - (c) **Type of continuous fetal monitoring / type of perineal
      support**: the SAP (§5.1.1.3) describes them among the women with
      continuous monitoring / with perineal support; the code counts all
      other women as "(missing)" (2,955 / 3,909 in the WHO arm). Proposal:
      `ANL01FL` restriction as for the CS characteristics.
    - (d) **Shared decision making and companionship** are recorded on the
      LCG form only (`samvalg_*`, `stotteperson.*`); the SAP does not say so
      and the report tabulates them by treatment (the WHO column will be
      empty on real data; filled here only because the period is permuted).
      Proposal: SAP §5.1.1.3 "recorded on the LCG form only; presented for
      the LCG period"; report the LCG column only.
    *Presentation (report):*
    - (e) continuous baseline table lists the LCG before the WHO arm (order
      of appearance) — sort by `TRT01P`;
    - (f) analysis-set table rows in the order intervention / control /
      transition — control, transition, intervention;
    - (g) SDM rows labelled with the raw Norwegian variable names — use the
      English question texts of SAP §5.1.1.3;
    - (h) cumulative-incidence figure shows the 0.25 h grid as visible
      steps — `geom_line` (or a finer grid);
    - (i) the number not recorded for perineal support (SAP quotes 4,014,
      11.9%) and cord pH is not shown — add `n_miss` to the MI rows.
    *Known, tracked elsewhere:* country of origin still Norway yes/no (58);
    birthweight percentile not in the baseline table (64); implausible base
    excess values (venous BE SD 71; cleaning, 52).
    *Implementation notes (no SAP change needed):* the labour-curve model
    uses examinations at ≥ 3 cm with 0–72 h to delivery — 3 examinations
    at 4 cm (≥ 72 h) and 1 (≤ 0 h) are dropped and those women's 4 cm time
    is imputed; `EXPOSN` counts from the scheduled LCG step.
    ***Decided (statistician, 2026-10-02) — to implement in one batch,
    then rebuild (57):***
    - (a) The 5 CS at 3 cm are **correct**: admitted at ≥ 4 cm, the cervix
      had retracted at the CS. Counted with those at 4 cm (excluded from the
      primary by the ≤ 4 cm stratum; included in SUPP1 and the
      secondaries — as coded). **SAP wording** (§1.2 cell, §1.3 bullet,
      §4.1.5 SUPP1): "women were included from 4 cm; a caesarean section
      recorded at 3 cm, after the cervix had retracted (5 women), is counted
      with those at 4 cm"; SUPP1 heading "caesarean sections at ≤ 4 cm
      included"; CLAUDE.md line corrected. DM 8 closed.
    - (b) Twin-2-only CS: `CXCS` from `CXCSN` (10 cm); presentation,
      position, main reason from `tv2_fotal_fodselspresentasjon`,
      `tv2_fotal_fodselsposisjon`, `tv2_hovedarsak_operativ_forlosning`;
      level missing. No SAP footnote.
    - (c) Type of continuous monitoring among women with CFM = 1; type of
      perineal support among women with support = yes. Both boxes ticked →
      "STAN or continuous internal CTG" (as now).
    - (d) SDM and companionship: SAP §5.1.1.3 rows "Recorded on the LCG form
      only; presented for the LCG period"; report LCG column only.
      Conditional items (informed / agreed; the three plan follow-ups)
      among the women whose gate question is yes (descriptive only). New
      single source `metadata/sdm_items.csv` (variable, domain, English
      item, response set, gate, **Norwegian question text**) read by the
      code and rendered as a second table in SAP §12.2 by an R chunk; one
      sentence in §12.2 that the English labels of coded values are in
      `metadata/codelists.csv` (validated by the investigators). The
      Norwegian texts are not in the repo (codebook labels repeat the
      variable names) — *pending: the LCG form from the statistician, or
      via PI 14*. Prolonged-labour indicators: no change.
    - (e) continuous baseline table WHO before LCG; (f) analysis-set rows
      control, transition, intervention; (g) English SDM labels (via d);
      (i) "N not recorded" for the MI endpoints.
    - (h) Cumulative incidence: evaluated on a **1-minute grid**, drawn as
      a step function (`geom_step`); it is the MI-averaged empirical
      cumulative incidence (Aalen–Johansen without censoring); no
      confidence bands, no observed-only curve.
    *Verified consistent with the SAP* (numbers from the report): analysis
    sets (FAS 36,324; PAS 33,286; principal stratum 32,970; VDS 30,714);
    primary GLMM + G-computation, NI/superiority in fixed sequence,
    SENS1–2, SUPP1–3 (SUPP2 N = 35,981 = PAS stratum + 3,011 transition
    women in the stratum); secondary N per endpoint (amniotomy 29,944,
    oxytocin 31,263, epidural 28,106 = PAS minus intervention at ≤ 3 cm;
    PPH 33,127 and tears 30,353 / 32,925 complete case; episiotomy = VDS);
    MI m = 20 / 30 with the SAP auxiliaries; tears proportional-odds +
    OASIS; time to VD (m = 30, 17,560 imputed = 57%; P(VD) component =
    −SUPP1; all SENS / SUPP / SUPPORTIVE rows); Robson subgroup (groups 6–8
    combined); covariate set, splines, missing-indicator rule; baseline
    rows of §12.2; by-cm tables of §6.

*Implemented 2026-10-02* (code, SAP v0.84, tests); see item 57 for the rebuild.

67. **Statistician's edits of SAP v0.84** (2026-10-06). The language pass in
    `SAP_NORWELCG v0.84 ICO.docx` (tracked and untracked changes) was ported to
    `sap_norwelcg.qmd` after a full-text diff against the rendered v0.84 docx.
    It includes captions for the objectives and estimand tables, an "or spurious"
    column header and filled missing-data cells in the descriptive table, and
    removed rationale text (form-based treatment wording in the estimand table,
    KM-censoring argument, 5 cm validation, hospital list in the FAS). Obvious
    typos were corrected while porting. The comment "Need to discuss" on the
    time-to-vaginal-delivery analysis was resolved: without censoring, the mean of
    Y = min(T*, 36 h) is exactly 36 h minus the area under the empirical
    cumulative incidence curve of vaginal delivery. The linear model on Y is the
    pseudo-observation regression of the restricted mean (pseudo-observations
    = Y; Andersen, Hansen & Klein 2004, §2). A sentence and the reference were
    added. Skewness affects only the variance; HC3 (sensitivity 2) covers the
    heteroscedasticity. Also fixed: a line starting with `@sec-…) ` inside a
    list item made Pandoc read it as an example-list marker, so every reference
    to §1.2 rendered as "1" (pre-existing since v0.83). Follow-up decisions
    (statistician, 2026-10-06): Andersen & Keiding (2012), no longer cited,
    dropped from the references; §2.3 principal-stratum assumption reworded;
    §1.4 randomisation in past tense; treatment defined by the eCRF in the
    estimand table, §1.3, §7.1 and §10 (consistent with §3). Bumped to v0.85
    (6 October 2026) and rendered for the clinicians' final validation; cover
    note `cover_note_v0.85.md` (questions: SGA/AGA/LGA bands, §12.1
    completeness, † wordings in the SDM table). Blinded counts still to be
    replaced from the safe side before signature (item 52).

*Closed 2026-10-06.*

68. **Statistician's comments on the mock-up report** (2026-10-07;
    `reports/statistical_analysis commICO.docx`). Treatments are named
    consistently "WHO partograph" and "LCG": `cfg$arms` labels (hence
    `TRT01P` levels, contrasts "LCG vs WHO partograph", figure legend), the
    study-period tables (control / transition / intervention → WHO partograph
    / Transition / LCG), SUPP2 "TRANSITION AS WHO PARTOGRAPH", SUPP3 levels from
    the arm labels ("LCG step 1", "LCG step 2+" vs "WHO partograph"), and the
    report column headers ("Events (WHO partograph / LCG)", "Risk, LCG", …;
    "Arm" → "Treatment"). The `make_rddsc` baseline flags (Y/N) and the
    dichotomous descriptive endpoints (0/1, e.g. prolonged labour, companion
    items) are shown as Yes/No. The Parity label was shortened, the "Open
    items" section was removed, and the sentence "All analyses follow the final
    signed version of the SAP v1.0 YYYY-MM-DD" was added. "Documentation form"
    was changed to eCRF in the report text. The fixtures in 8 test files were
    updated (158 expectations pass, new check on the No/Yes recode). The
    report chunks were run against the existing store. Targets from `adsl`
    downstream are outdated (item 57).

*Closed 2026-10-07.*

69. **Investigators' feedback on v0.85 → SAP v0.9** (2026-10-13; from
    `2026.10.08 SAP_NORWELCG v0.85 innspill M, T, R og S.docx`, the
    statistician's versions `… ICO.docx` and `… ICO 2.docx`, and Therese's
    e-mail of 2026-10-07, `docs/sap/Email from Therese 7OCT2026`). Ported
    to the qmd and rendered as `SAP_NORWELCG v0.9.docx` (the sent source
    kept as `sap_norwelcg_v0.85.qmd`; an intermediate v0.86 was not
    circulated). Decisions:
    (1) **primary endpoint counts all CS from 4 cm** in both periods; no
    principal stratum and **no 5 cm supplementary analysis** (statistician:
    no longer needed) — supplementary analyses are now transition periods
    (SUPP1) and exposure time (SUPP2);
    (2) **episiotomy and OASIS stay in the VDS** (principal stratum;
    composite supplementary analysis in the PAS, CS = no event) after a
    second round with the investigators;
    (3) amniotomy / oxytocin / epidural **counted whatever the cervical
    dilatation** (explicit request from the investigators, confirmed by the
    statistician 2026-10-13; no 4 cm window, no exclusion; the any-dilatation
    supplementary analyses dropped as identical);
    (4) degree of perineal tears → **occurrence of OASIS** (grade 3a–3c or
    4, dichotomous, complete case; ordinal section removed, §5.1.1
    renumbered);
    (5) medical pain relief, perineal support (and its MI), reason for
    admission, cervix at induction, labour companionship and type of
    perineal support → §12.1; cervix dilatation at amniotomy / oxytocin /
    epidural removed; shared decision making only for operative delivery
    (Table 3 filtered from `sdm_items.csv`);
    (6) baseline table without contractions at admission, birthweight
    percentile (Skjærven reference removed) and the pre-4 cm interventions;
    height kept in §12.2 as an adjustment covariate, not in the baseline
    table;
    (7) cord gas: arterial and venous pH outside 6.5–7.55 and BE/BD outside
    −25 to 25 mmol/l set to missing (on the anon copy this removes nothing);
    (8) "live fetus at admission" added to the population; LCG = "Labour
    Care Guide"; OASIS abbreviation; time to vaginal delivery kept; Robson
    sentence and descriptive PPH row (> 500, > 1000, > 1500 ml) unchanged.
    Therese's e-mail of 2026-10-07 is **disregarded** (statistician's
    instruction); pH < 7.00 and Apgar < 7 stay analysed secondary endpoints.
    2026-10-13: signature page added (statistician, PI, Co-PI/TM, two
    investigators); tables drawn with all grid lines and a bold header row
    (`Table` style in `templates/sap_reference.docx`, Quarto's layout
    wrapper removed by `templates/unwrap_tables.lua`; html
    `templates/sap_tables.css`).
    Set to version 1.0 for signature (2026-10-13); bullets removed from Tables 1 and 12.1.
    **Open**: sign v1.0 (`SAP_NORWELCG v1.0.docx`). Code: item 70. *Closed 2026-10-14*: SAP v1.0 ready for signature (`SAP_NORWELCG v1.0.docx`).

70. **SAP v0.9 in the pipeline** (from 69; implemented and tested
    2026-10-13; full rebuild pending, item 57).
    - `make_rdeff`: PRIMARY / SENS1 / SENS2 on the whole PAS (no `PSTRFL`);
      SUPP1 transition as WHO partograph (FAS), SUPP2 exposure time; the old
      SUPP1 (CS at 4 cm included) is now the primary. `make_rdsub` likewise.
    - `make_adsl`: `PSTRFL`, `AMNIOB4FL` / `OXYB4FL` / `EDAB4FL` and
      `cfg$analysis$from_cm` removed; CONTRADM and BWPCT/BWPCTC still derived
      but not in the baseline table.
    - `make_adeff`: AMNIO / OXY / EDA at any dilatation (no ANL01FL rule);
      TEAR (ordinal) → OASIS (binary, VDS, complete case) and TEARC → OASISC;
      PERSUP, PERSUPC, MEDPR, AMNIOANY / OXYANY / EDAANY, CXAMNIO / CXOXY /
      CXEDA / CXIND, PERSUPTY, companionship removed; SDM only
      `samvalg_operativ_forlosning_*`; cord pH 6.5–7.55, BE/BD −25..25 (also
      `CLEANING_LIMITS` and data-cleaning rules 13 and 15).
    - `make_rdmi`: cord pH only (`m_persup` removed from cfg); `rdtear`
      target removed (file kept); `make_rddsc`: baseline without ADMREAS,
      BWPCTC, pre-4 cm flags, CONTRADM, HEIGHT; `ordinal` element removed.
    - Report: introduction, analysis sets, primary, secondary, supplementary
      and descriptive text; tear section removed. `sap_numbers.R` and
      `blinded_checks.R` updated; SAP section references renumbered
      (§5.1.1.5–5.1.1.7).
    - Tests updated (all files pass); ADSL → ADEFF → RDDSC and
      `sap_numbers.R` run on `20261001_anon`.
    - Still open: data check (safe side, item 52) for women without a live
      fetus at admission (FASFL is "Y" for all rows). *Closed 2026-10-14*: rebuilt (57); the live-fetus data check moves to item 52.

71. **Repository clean-up and file-target fix** (2026-10-14). Removed the
    template's Viedoc/SDTM files (`R/make_sdtm/*`, `make_adae|adex|adlb|advs.R`,
    `make_rdvs.R`, `make_raw.R`, `make_shamrand.R`, `config/visits.yml` and its
    targets, `metadata/items.csv`), `docs/handover_2026-07-10.md`, old report
    renders, the anonymised copies `_20260708_anon` and `20260911_anon`, and the
    pre-fix cleaning outputs. `README.md` and `metadata/README.md` rewritten;
    `make_rdtear.R` kept (later SAP). SAP draft versions left to the
    statistician. Found while checking `tar_outdated()` after the deletions: the
    `raw_file` target read `cfg.yml` inside its command, so it never re-ran when
    `cfg$export` changed and still tracked `data/raw/20260911_anon/…rds`.
    `make_raw_norwel()` reads `cfg$export` directly, so every build since
    2026-10-02 used the `20261001` copy; only the file tracking was wrong.
    `raw_file` and the four lookup-file targets now take their paths from the
    `cfg` target. Next `tar_make()`: these file targets and `raw` re-run; the
    rest should be skipped if `raw` is unchanged.

## Data-pipeline notes (reference)

- ~~Broken date window in the first export~~ **resolved 2026-07-09**.
- **Final export `_20260909`** (2026-09-09): 36,324 women — control 17,193,
  LCG 16,093, transition 3,038. Anonymised copy in dev:
  `data/raw/20260911_anon` (re-run 2026-09-11 with the item-24 fix).
- In the anonymised copy `treatment` is randomised and cross-variable links are
  broken by design — endpoint rates are real (marginals preserved), any
  treatment effect and STEPN×treatment structure are not. Timing columns are
  shifted as a block per row, so **within-woman intervals are real** (labour
  progression can be explored on the anon copy).
- **`run_anon.R` ran on every `tar_make()` (found and fixed 2026-09-11).**
  `tar_source()` sources every file under `R/`, and the runner had top-level
  code, so each pipeline run re-executed the anonymiser — in dev it failed on
  the missing `.dta` files (which is how it was found); on the safe side it
  would silently have rewritten the anon copy and `offset_map.csv`. Body now
  wrapped in `if (sys.nframe() == 0L)` (as `covariate_check.R`); `Rscript
  R/make_anon/run_anon.R` unchanged. **Safe side: pull this before any
  `tar_make()`.** Rule: scripts under `R/` must not run code at top level.
- **SAP source moved to Quarto (2026-09-11)**: `docs/sap/sap_norwelcg.qmd`,
  converted from `SAP NORWELCG v0.8 ICO.docx` with all tracked changes
  accepted and the 22 Word comments kept as `<!-- COMMENT … -->` lines;
  Figure 1 regenerated in R from the design; rendered docx checked against the
  original text (word-level diff: only intended changes). Renders to docx via
  `templates/sap_reference.docx` (v0.8 styles, heading auto-numbering removed,
  version dropped from the page header).
