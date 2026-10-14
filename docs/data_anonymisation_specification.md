# Data anonymisation & safe-development specification

> **Status 2026-10-02.** No trial-specific DPO assessment is made for
> NORWELCG; the general handling of relative anonymisation is being clarified
> in an external process. The list linking the record key `nokkel` to
> hospital records is held by the principal investigators; `nokkel` is
> replaced by a synthetic key in the anonymised copy.

Version: 0.2 (draft). Owner: trial statistician. Applies to: all trials using
this template. Companion documents: `docs/data_anonymisation_plan.md` (method
rationale & literature), `R/make_anon/` (implementation), `config/anon.yml`
(configuration).

This specification defines the procedure for producing an **anonymised** copy of
clinical trial data — anonymised *relative to the development environment* (§3) —
so that statistical code can be developed with LLM tooling, while the keys that
could reverse the process remain in a controlled ("safe") environment with the
data controller. It is a process specification, not legal advice; the approach
and its relative-anonymisation basis (§4) must be approved by the data
controller / DPO before use on real data.

## 1. Purpose and scope

- **Purpose:** enable code development with LLM tooling without exposing personal
  or special-category (health) data, and ensure final analyses run on real data
  only inside the safe environment.
- **In scope:** raw Viedoc exports, the anonymisation procedure, key management,
  inter-environment transfers, verification, and the sham randomisation used
  during development.
- **Use of the output:** the anonymised export is used **only for code
  development**; it is **not** made publicly available. Onward sharing with other
  researchers (e.g. on reasonable request) is possible but must be governed by a
  data transfer / data sharing agreement, as usual in medical research, and is
  out of scope of this document.
- **Out of scope:** publication of open synthetic data (would require a stronger,
  joint-distribution-preserving method such as `synthpop` and a separate risk
  assessment).

## 2. Definitions

- **Safe environment:** controlled system holding real data and the
  re-identification keys; no LLM/cloud code assistants; access restricted to
  authorised study personnel.
- **Development environment:** the system on which code is developed with LLM
  tooling. For the current owner this is a hospital-provided Mac under the
  owner's sole administration (§5). It must never hold real personal data, the
  true randomisation, or the re-identification keys.
- **Anonymised copy / anonymised export:** the dataset produced by the procedure
  in §6, anonymised relative to the development environment (§4).
- **Re-identification keys:** the subject-ID map and per-subject date-offset
  table that could reverse the procedure.
- **Direct identifier / quasi-identifier:** per the PHUSE CDISC SDTM
  de-identification standard and El Emam's risk-based methodology.

## 3. Status of the data: pseudonymised for the controller, anonymised for the development environment

- The raw Viedoc database contains **no directly identifying information**: data
  managers configure forms to exclude it, and investigators are trained not to
  enter identifiers in free-text/verbatim fields. It is nonetheless
  **pseudonymised personal data**, not anonymous, for the controller — a subject
  identification log linking the subject code to the patient exists at site (an
  ICH-GCP requirement), and the EDPB Guidelines 01/2025 on Pseudonymisation
  confirm that data attributable to an individual via additional information
  remain personal data.
- After the procedure in §6, and with the keys retained only in the safe
  environment, the export is treated as **anonymised relative to the development
  environment**: that environment holds no key and has no reasonably likely means
  of re-identification. For the controller the data remain pseudonymised personal
  data.

## 4. Legal basis for relative anonymisation

The relative (contextual) approach is supported by **CJEU, Case C-413/23 P, EDPS
v SRB, judgment of 4 September 2025**. The Court held that pseudonymised data are
not automatically personal data for every party: data may be personal for the
original controller (who can re-identify) yet **anonymous for a recipient** who
cannot reverse the pseudonymisation and cannot identify individuals by other
reasonably likely means, assessed on the recipient's technical, organisational
and legal situation. The assessment of "reasonably likely means" follows the
EDPB Guidelines 01/2025 on Pseudonymisation and accounts for information both
within and outside the recipient's control.

Applied here: the development environment is the recipient; it has no access to
the re-identification keys or the source data, and the procedure in §6 removes
direct identifiers and breaks individual linkage. The conditions in §4.1 are the
basis on which the export is treated as anonymous in that environment.

### 4.1 Conditions that must hold (DPO to confirm)

1. The development environment is genuinely separate and has **no access to the
   keys** or the source data (technical + organisational + legal separation).
2. A documented re-identification **risk assessment** shows singling-out,
   linkability and inference are not reasonably likely there, including via
   external data (supported by the §10 readout).
3. The keys are demonstrably retained **only** in the safe environment.
4. LLM use does not re-expose the data (see §5).

## 5. Development environment and LLM use

- The development environment is a **hospital-provided Mac administered solely by
  the owner** (the trial statistician), who is the system administrator; it is
  not centrally managed by hospital IT. The owner controls installed software,
  accounts and access.
- LLM tooling (e.g. Claude) is used for code development. The configuration used
  **does not contribute the data to model training** (no training/improvement on
  submitted content), which provides an enhanced level of protection against
  onward exposure. This setting must be maintained; if it cannot be guaranteed,
  the anonymisation basis must be re-assessed.
- These factors (sole administration, controlled access, no model-training reuse)
  are part of the "technical, organisational and legal" situation supporting the
  relative-anonymisation assessment in §4.

## 6. Anonymisation procedure

Implemented in `R/make_anon/make_anon.R`, seeded for reproducibility
(`anon.yml: seed`). Variables are assigned tiers (auto-proposed from the Viedoc
`Items` metadata, overridable in `anon.yml`); the conservative default is that
any unrecognised variable is permuted (never passed through untouched).

| Tier | Definition | Treatment |
|------|------------|-----------|
| **key** | structural / join key | preserved; subject id pseudonymised (§6.1) |
| **direct** | direct identifier or free text | blanked with placeholder; coded sibling kept |
| **date** | date / datetime | per-subject offset (§6.3) |
| **permute** | quasi-identifiers, measurements, outcomes | value-permuted within group; numeric top-coded (§6.4) |

### 6.1 Subject-ID pseudonymisation
Replace every subject identifier with a new random ID via a bijective map applied
consistently across all forms (preserves joins). The map is a re-identification
key (§7).

*Flat-file variant (NORWELCG).* The export is one row per participant with a
record key (`nokkel`, format `TRAN-NNNNN`) whose prefix encodes the study period.
The key is removed before permutation and rebuilt afterwards as a **synthetic**
key in the same format (`anon.yml: synthetic_ids`): prefix from the permuted
period label, numbers a random permutation of 1..n within each prefix. Nothing
is derived from the real key and no map is kept — there are no joins to
preserve. Code that uses the key therefore runs unchanged in both environments,
and the schema check (§10) holds.

### 6.2 Direct identifiers & free text
Blank with a placeholder, preserving the column so code still runs. Free text is
not exported; where a coded sibling exists (e.g. MedDRA preferred term) the coded
value is retained.

### 6.3 Dates
Apply a single random per-subject day offset (within `date_offset_range`).
Within-subject intervals and event ordering are preserved; absolute dates are
obscured. The offset table is a re-identification key (§7).

### 6.4 Quasi-identifiers, measurements & outcomes
Permute each value column within the configured scope (`by_param` default:
per-column within `group_vars`, i.e. within visit/parameter). Coupled
`<x>`/`<x>cd` pairs are permuted together to keep code↔label consistency. Numeric
columns are top/bottom-coded at the configured quantile before permutation.
Permutation preserves each variable's marginal distribution exactly while
breaking the link to the individual. Variables needing a realistic per-subject
trajectory may be permuted at subject level (`by_subject_vars`).

## 7. Key management

- The subject-ID map and date-offset table are written **only** to
  `data/raw/anon_keys/` in the safe environment.
- `data/raw/` is git-ignored; keys are **never** committed, copied to the
  development environment, or shared.
- Keys are retained in the safe environment for the study record and destroyed
  per the trial's data-retention policy.

## 8. Transfer rules

- **Safe → development:** only `data/raw/<export>_anon/`. No keys, no real
  data, no true randomisation.
- **Development → safe:** only code (scripts, `_targets.R`, reports). No data.
- Each transfer is the owner's explicit decision and is logged (date, contents,
  direction).

## 9. Sham randomisation

During development the anonymised copy carries **sham** randomisation only
(`cfg.yml: mode: sham`; for NORWELCG the permuted period label, see below). The true
allocation is never present in the development environment. Final analyses switch
to `mode: true` in the safe environment after database lock.

*Stepped-wedge trials (NORWELCG).* The participant-level allocation — which
period a woman's record belongs to — is never present in development: the
anonymised copy carries the permuted period label (`treatment`) and a synthetic
key consistent with it (§6.1), so no separate sham-randomisation step is run.
The randomised **crossover schedule** (cluster → sequence) is a different
matter: it is not concealed in a stepped-wedge trial (clusters know their
crossover dates; the schedule is in the protocol documents), and it may be held
in the development environment (e.g. `metadata/hospitals.csv`) to derive the
calendar-assigned period. This reveals nothing about treatment effects, because
in the anonymised copy site, dates and outcomes are each randomised
independently; a period derived from site × date there is itself a sham
allocation.

## 10. Verification

After anonymisation, the owner reviews (`R/make_anon/anon_checks.R`):

- **Schema:** anonymised forms keep the same columns, types and codelists
  (`anon_verify`).
- **Marginals:** preserved by construction for permuted columns; spot-check key
  variables.
- **Re-identification risk readout:** worst-case equivalence-class size (k) over
  the quasi-identifier combination per form (`anon_risk_readout`; uses
  `sdcMicro` if installed). Reviewed before any transfer; forms with small k are
  re-examined (additional generalisation/suppression via `anon.yml`).
- **Negative check:** confirm no key files are present in the export directory.
- **Timestamp coverage:** every date-time column (typed datetime/date, or an
  ISO-like date string) must be listed for shifting or dropping; `make_anon`
  stops before writing anything if one is not (added after deviation D-1,
  §14). When an export gains new columns, review them against `anon.yml`
  before the run.

## 11. Residual risk & limitations

- Residual risk is concentrated in rare quasi-identifier combinations and
  outliers; top-coding, generalisation and free-text removal mitigate but do not
  eliminate it. The §10 risk assessment addresses this for the relative basis.
- Per-column permutation destroys cross-variable and (outside `by_subject`)
  within-subject relationships; consistency/validity and edge-case logic must be
  developed in the safe environment or against small synthetic fixtures.
- The anonymisation is **relative to the development environment** under the
  conditions in §4.1; the data remain personal/pseudonymised for the controller.
  If those conditions change (key exposure, loss of control of the development
  environment, LLM reuse for training), the basis lapses and must be reassessed.

## 12. Governance

- The DPO / data controller approves this procedure, the relative-anonymisation
  basis (§4) and the §4.1 conditions, and accepts the residual risk per trial.
- Onward sharing of the anonymised data with other researchers is by data
  transfer / data sharing agreement only (§1); the anonymised export is not made
  public.
- Use of LLM tooling must comply with the institution's information-security and
  AI-use policies and with §5.
- This specification is version-controlled with the trial code; changes are
  recorded in the version history.

## 13. Operating checklist (per trial)

1. Configure `config/anon.yml` (tiers, `direct_identifiers`, `group_vars`,
   `date_offset_range`, top-coding) for the trial's variables.
2. Run the anonymiser in the safe environment in a **fresh R process**
   (NORWELCG: `Rscript R/make_anon/run_anon.R`), never by re-calling
   `make_anon()` in an older session (D-2).
3. Review schema check and risk readout; tighten config and re-run if needed.
   In development, confirm that `anon_manifest.csv` shows the expected code
   version before the copy is used.
4. Confirm `anon_keys/` is excluded; transfer only `<export>_anon/` out.
5. Develop and validate code in the development environment on the anonymised copy.
6. Transfer code (no data) back; run on real data with `mode: true`.
7. Log transfers; retain/destroy keys per policy.

## 14. Deviation log

Deviations from this specification found in anonymised copies, with impact and
corrective action. The assessment field is completed by the owner (and the DPO
where §12 requires it).

**D-1 (NORWELCG, detected 2026-09-11).** *Copy affected:* `_20260909_anon`
(final export, anonymised 2026-09-09, in the development environment
2026-09-09 to 2026-09-11).

- *What:* the final export introduced columns not covered by `anon.yml`: seven
  typed date-time columns (`nytidinnleggelse`, `nylatensfasens`,
  `nytidinduksjon`, `nytidvannavgang`, `nytideda`, `nystart_trykketid`,
  `nyfodselstidspunkt`) and a record key `nokkel` (prefix `CTR`/`INT`/`TRAN`
  = true study period). Unlisted columns are permuted by default, so the seven
  date-times were **permuted with their true calendar values instead of
  shifted** (breach of §6.3), and `nokkel` was permuted instead of dropped.
- *Impact:* each column was permuted independently across all 36,324 rows, so
  no true date or key value remained on its own record and the true period
  could not be read from `nokkel`. The marginal distribution of the true dates
  was present in the development environment. No keys were exposed. Summaries
  of these columns (ranges and a few values) were printed in an LLM-assisted
  session on 2026-09-11 before the issue was detected (§5).
- *Corrective action (2026-09-11):* the seven columns were added to `timing`
  (anchor now the delivery time) and `nokkel` to `drop`. `make_anon` now stops
  on any unlisted date-time column (§10) and gives rows without an anchor a
  random offset rather than none. It was re-run in the safe environment and
  the new copy (`20260911_anon`) verified in development: `nokkel` absent,
  every date-time shifted by its row offset, shifted dates inside the window,
  no key files present. `_20260909_anon` was deleted from the development
  environment on 2026-09-11. Details: `docs/sap/sap_data_review.md` item 24.
- *Assessment:* The corrective action has solved the issue. 

**D-2 (NORWELCG, detected 2026-09-11).** *Copy affected:* `20260911_anon` as
re-generated at 10:49 on 2026-09-11 (it overwrote the 09:47 copy, which was
correct).

- *What:* the **real** record key `nokkel` was in the copy, permuted across rows
  as an ordinary column, instead of the synthetic key (§6.1). Evidence from the
  development check: the prefix agrees with the period label only at chance
  level (about one in three), the prefix totals equal the true period sizes, and
  the numbers exceed the per-period counts.
- *Cause (most likely):* the committed code (1bf6908) contained both the new
  `anon.yml` (key moved from `drop` to `synthetic_ids`) and the new
  `make_anon()`. The output is what the *earlier* `make_anon()` produces from the
  *new* `anon.yml`, i.e. the run used function definitions from an earlier R
  session while re-reading the configuration.
- *Impact:* as for `nokkel` in D-1: permuted independently of every other
  column, so no key sat on its own record and the prefix does not give a row's
  true period; the real key values themselves were present in development. Two
  key values were printed in an LLM-assisted session during the check (§5).
- *Corrective action (2026-09-11):* `nokkel` is listed in `drop` as well as
  `synthetic_ids`, so older code drops it; `make_anon` writes
  `anon_manifest.csv` with the code version that actually ran (checked in
  development before a copy is used); `R/make_anon/run_anon.R` runs the
  anonymiser in a fresh R process and stops before transfer if the
  synthetic-key check fails (§13). The affected copy was deleted from
  development by the owner on 2026-09-11 and replaced by a fresh-process run
  (11:08, manifest code version 2026-09-11.3, config hash matching the
  committed `anon.yml`), verified in development: synthetic key in the real
  format, prefix equal to the period label on every row, numbers 1..n in
  random order within each period; all other checks as for D-1.
- *Assessment:* The corrective action has solved the issue. 

## References

- CJEU, Case C-413/23 P, *European Data Protection Supervisor v Single Resolution
  Board*, judgment of 4 September 2025 (relative/contextual approach to whether
  pseudonymised data are personal data for a recipient).
- EDPB, *Guidelines 01/2025 on Pseudonymisation* (adopted for public
  consultation 16 January 2025).
- PHUSE De-Identification Working Group, *De-Identification Standard for CDISC
  SDTM* (2015; endorsed under EMA Policy 0070).
- El Emam K., Arbuckle L., *Anonymizing Health Data* (O'Reilly, 2014);
  risk-based de-identification and k-anonymity.
- Muralidhar K., Sarathy R., *Data Shuffling — A New Masking Approach for
  Numerical Data*, Management Science 52(5):658–670 (2006).
