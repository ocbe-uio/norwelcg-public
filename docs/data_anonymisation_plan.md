# Data anonymisation pipeline — literature review & plan

Status: **implemented.** Goal: anonymise a Viedoc
raw export inside the safe environment so a practically de-identified copy can be
moved to an LLM-accessible environment for code development; finished code is
returned to the safe environment and run on the real data. The sham
randomisation procedure is retained.

## 1. Literature review

The relevant field is **Statistical Disclosure Control (SDC)** / data
de-identification. Four method families are relevant here:

1. **Perturbative masking — data shuffling.** Muralidhar & Sarathy's *data
   shuffling* (Management Science, 2006) reorders values of a variable across
   records. Its defining property is that the **univariate marginal distribution
   is preserved exactly** (the masked column is a permutation of the real
   values), while linkage to the original record is broken. The full method also
   preserves rank correlations via a copula step; a plain per-column permutation
   keeps only the marginals — which is what you asked for.

2. **SDC toolkits — `sdcMicro` (R).** Templ, Kowarik & Meindl (JSS 2015).
   Implements recoding/generalisation, local suppression, PRAM
   (post-randomisation for categoricals), microaggregation, noise addition, and
   — importantly — **risk measurement** (individual/global re-identification
   risk, k-anonymity). Useful as an optional risk readout even if we hand-roll
   the anonymisation.

3. **Synthetic data — `synthpop` (R).** Nowok, Raab & Dibben (JSS 2016).
   CART-based sequential synthesis preserving joint distributions; rows are not
   real people. You explicitly **do not** want this (no need for correct joint
   structure, and you prefer masked real records), so it's out of scope — but
   it's the tool to reach for if a future trial needs shareable, relationship-
   preserving synthetic data.

4. **Clinical-trial de-identification standards.** The **PHUSE De-Identification
   Standard for CDISC SDTM** (2015, endorsed under EMA Policy 0070) and El Emam's
   **risk-based methodology** (k-anonymity, OLA) define the practical playbook:
   classify variables into **direct identifiers** (names, IDs, free text → remove
   / pseudonymise) and **quasi-identifiers** (dates, age, location, rare
   categories → generalise / offset), then reduce re-identification risk on the
   quasi-identifiers. **Date shifting** (a per-subject offset that preserves
   within-subject intervals) is the standard treatment for dates.

### Insight on your marginal-vs-joint question

A pure, independent per-column permutation preserves every variable's marginal
exactly and is maximally protective, but it has two consequences worth designing
around:

- It **destroys all cross-variable and within-subject structure.** Change-from-
  baseline logic, validity/consistency checks, and any analysis that depends on
  relationships will run but produce meaningless numbers. You said you accept
  this and will handle specific cases separately — agreed, that's the right call.
- Independent permutation across *all rows* of a long-format dataset also mixes
  values across visits and parameters, which can push values out of plausible
  range (a Day-1 value landing at Day-239, a creatinine value in a haemoglobin
  row) and can break code that pivots/filters by parameter. 

**Recommended refinement (still "marginal", just smarter scope):** permute each
value column **within homogeneous groups** — e.g. within `paramcd` (and
optionally within visit) — rather than globally. This keeps units/ranges valid
and the relational shape intact (so code runs), preserves the conditional
marginal by parameter, and still breaks the link to the individual. The
permutation scope is a config knob (`global` | `by_param` | `by_param_visit` |
`by_subject`), defaulting to `by_param`.

Also note: independent permutation already weakens the "1:1 masked records"
idea — after shuffling, a row is a composite of different real people's values,
not one person's record. That is good for privacy. Where you genuinely need a
real person's intact trajectory (e.g. to develop longitudinal code), use the
`by_subject` scope for that variable, which shuffles whole per-subject series
between pseudo-subjects.

## 2. Proposed approach

A **tiered, metadata-driven anonymiser** that leans on the Viedoc `Items` file
(datatype, categorical, formatname) we already parse, so every variable gets a
default tier automatically, with manual overrides in a config file.

### Variable tiers and treatment

| Tier | Examples | Treatment |
|------|----------|-----------|
| **Structural / keys** | `subjectid`, `eventid`, visit/seq keys | **Not value-permuted.** Subject IDs **pseudonymised** via a consistent random remap across *all* forms (preserves joins). Keeps referential integrity so code runs. |
| **Direct identifiers** | names, initials, addresses, exact DOB, free-text/verbatim (AE terms, comments, medical history) | **Dropped or replaced.** Free text replaced by its coded term only (e.g. MedDRA PT) or a placeholder — free text cannot be reliably anonymised. |
| **Dates** | visit/event/assessment dates | **Per-subject date offset** (PHUSE-style): preserve within-subject intervals, hide absolute dates. Not permuted (preserves ordering → code runs). |
| **Quasi-identifiers** | age, sex, site, country, race, rare diagnosis, height/weight | **Permuted across subjects** (marginals preserved) + light **generalisation/top-coding** for rare/outlier values (the main residual-risk lever). |
| **Measurements / outcomes** | labs, MRI biomarkers, scores, AE attributes | **Per-column permutation** within the configured scope (default `by_param`). Coupled `x`/`xcd`/label triplets permuted **together** to keep code↔label consistency. |

### Cardinal rules (privacy)

- The **ID mapping table is the re-identification key** — it is generated and
  stored **only in the safe environment** and never exported.
- The anonymised export carries **sham** randomisation, never the true allocation
  — so the unsafe environment never holds true treatment codes either.
- Only **code** travels unsafe→safe; only **anonymised data** travels safe→unsafe.

### Workflow

```
SAFE env:    raw (Viedoc)  ──make_anon()──►  anonymised export (+ sham rand)
                                                        │  (leaves safe env)
UNSAFE env:                          develop pipeline & report on anonymised data
                                                        │  (code only, no data)
SAFE env:    upload code  ──►  run on real raw data  ──►  final outputs
```

### Reproducibility & verification (pragmatic)

- Driven by `config/anon.yml` (tier per variable + permutation scope + seed),
  auto-proposed from `Items` metadata, manually overridable.
- Post-anonymisation checks: (a) schema identical (columns, types, codelists);
  (b) marginals preserved (distribution comparison per permuted column);
  (c) ID map is bijective and absent from the export; (d) a light re-id readout —
  worst-case **k** for the quasi-identifier combination, optionally via
  `sdcMicro` — reported but not gated on a formal threshold.

## 3. Honest limitations

- **Utility:** cross-variable and (outside `by_subject`) within-subject
  relationships are gone; consistency/validity and edge-case logic must be
  developed in the safe environment or against small hand-made synthetic
  fixtures.
- **Residual risk:** with masked *real* records, risk concentrates in rare
  quasi-identifier combinations and outliers; generalisation/top-coding and
  dropping free text mitigate but do not eliminate it.
- **Legal:** "practically anonymous" is a technical risk-reduction measure, not a
  legal anonymity guarantee. Under GDPR (Recital 26) this is realistically
  **strong pseudonymisation/de-identification for restricted internal use**, not
  irreversible anonymisation. **This needs your DPO / data controller sign-off**
  — I'm flagging the standard, not giving legal advice.

## 4. R tooling

- Anonymiser implemented in base R + tidyverse (`sample()` for permutation,
  grouped permutation via `dplyr`, `withr::with_seed` for reproducibility) — light
  dependencies, easy to audit.
- `sdcMicro` optional, only for the risk readout (and available later if you want
  PRAM/microaggregation/generalisation helpers).
- Lives in the template as `R/make_anon/` + `config/anon.yml`, wired as an
  optional pre-stage target; documented in `CLAUDE.md` and `README.md`.

## 5. Points to confirm before I implement

1. **Default permutation scope** = `by_param` (my recommendation), with
   `by_subject` available per-variable for longitudinal needs. OK?
2. **Free text:** replace with coded term where one exists, else drop. OK, or
   keep a tighter "drop all free text" default?
3. **Dates:** per-subject offset (recommended) rather than permutation. OK?
4. **Risk readout:** include the optional `sdcMicro` k-anonymity readout, or keep
   it fully dependency-free for now?
5. **Scope of identifiers:** since "most sensitive data types may be present",
   should I ship a conservative default classification (treat anything not
   recognised from `Items` as a quasi-identifier → permuted, never passed
   through untouched)? Recommended.
