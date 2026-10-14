# Data cleaning rules and flags — NORWELCG

Blinded data-cleaning check for the final export, to be run **in the safe
environment** on the real data:

```
Rscript R/blinded_review/cleaning_check.R
```

writes

- `outputs/cleaning_flags.csv` — one row per flagged value: record key
  (`nokkel`), rule, variable, value;
- `outputs/cleaning_summary.csv` — counts per rule.

No treatment, period or hospital variable is used or reported, so the check is
blinded; the record key lets the data managers retrieve the record. Rule
thresholds live in `CLEANING_LIMITS` at the top of the script.

**Status: final (2026-10-02).** The export of 1 October 2026 is final and
nothing more is corrected at source. The script documents the flagged values;
the last column below ("In the analysis") is the final handling, decided by
the statistician before database lock without access to unblinded data
(review item 52).

## Rules

| # | Rule | Limits | Why | In the analysis now |
|---|------|--------|-----|---------------------|
| 1 | Timestamp year outside the trial period | 2024–2027 | sentinel / typing errors (e.g. year 0202); `nylatensfasens` had 11 such values | dropped: examinations before 2024 are not used (ADLP) |
| 2 | Admission after delivery | — | ordering error | not used (period and step come from the time of birth) |
| 3 | Time from a cervical examination to delivery ≤ 0 or ≥ 72 h, any dilatation | 0 < h < 72 | ≤ 0 = ordering error; ≥ 72 h is implausible for an examination used in the labour curve | `ANL01FL = "N"`: the examination is not used (labour-curve model, 4 cm imputation) |
| 4 | Time from one centimetre to the next: negative, or > 24 h from 4 cm, or > 72 h below 4 cm | 0–24 h (from 4 cm), 0–72 h (below) | ~86 negative consecutive intervals in the final export | flag only: the intervals are not used; the examinations carry rule 3 |
| 5 | Height outside 130–220 cm | | earlier exports had up to 769 cm | used as recorded (covariate) |
| 6 | Pre-pregnancy weight outside 35–250 kg | | earlier exports had up to 894 kg | used as recorded |
| 7 | Pre-pregnancy BMI outside 13–70 kg/m² | | combination check | used as recorded (covariate) |
| 8 | Maternal age outside 18–55 years | | eligibility is ≥ 18 | used as recorded (covariate) |
| 9 | Gestational age outside 22–45 weeks, plus days outside 0–6 | | typing errors | used as recorded (covariate) |
| 10 | Birth weight outside 300–6500 g | | typing errors | used as recorded (covariate) |
| 11 | Head circumference outside 20–45 cm | | typing errors | baseline table only |
| 12 | Apgar score outside 0–10 | | typing errors | complete case (endpoint) |
| 13 | Cord pH outside 6.5–7.55 (arterial and venous, both babies; 6.5–7.8 before SAP v0.9) | | 28 arterial + 47 venous values, incl. decimal slips (7179) and placeholders (10) | **set to missing**, then multiply imputed (SAP §5.1.1.4); decimal slips are not corrected |
| 14 | Arterial cord pH higher than venous | | swapped or single-vessel samples: 1,074 pairs (4.3%) | used as recorded (only 1 of 117 events affected) |
| 15 | Base excess or deficit outside −25 to 25 (SAP v0.9; before: excess −30 to 10, deficit −10 to 30) | | ~115 values, e.g. −401, −150 | **set to missing**; auxiliary for the cord pH imputation only |
| 16 | Estimated blood loss outside 0–5000 ml | | 6 values > 5000 (plausible for massive haemorrhage) | used as recorded (endpoint > 1000 ml) |
| 17 | Caesarean section without cervical dilatation | | needed for the principal stratum | complete case; none in the final export |
| 18 | Cervical dilatation recorded without a caesarean section | | inconsistency | ignored |
| 19 | Perineal tear or support recorded after a caesarean section | | 7 caesareans carry a tear; 1,279 carry a support value | not used: both endpoints are analysed in the vaginal delivery set |
| 20 | Perineal support or tear status not recorded after a vaginal delivery | | support: 4,014; tear: 376 | support: multiply imputed; tear: complete case |
| 21 | Tear grade ticked without a recorded tear, or a tear without a grade | | 15 tears without a grade | complete case |
| 22 | Second twin without a mode of delivery | | 4 twin pregnancies | the first twin's mode is used (SAP §4.1.1) |
| 23 | Intervention detail recorded while the intervention is marked as not done | | e.g. a dilatation for an amniotomy marked "no" | gate wins (the endpoint follows the gate) |
| 24 | "No fetal monitoring" ticked together with a method, or no item ticked at all | | 107 "none", 2 nothing ticked | counted as no intermittent / no continuous monitoring |

## Decisions (2026-10-02)

- Kept as recorded (implausible but possible): anthropometric extremes (rules
  5–7), head circumference 19 cm (11), blood loss > 5000 ml (16), arterial pH
  above venous (14).
- Set to missing (impossible): cord pH outside 6.5–7.55 (13), base excess /
  deficit out of range (15).
- One examination window for all dilatations (3), as in the analysis code.
- Review items 13–15 and 52 in `docs/sap/sap_data_review.md`.
