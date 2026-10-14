# metadata/

Study-level metadata used by the pipeline (paths in `config/cfg.yml`).

- The codebooks of the export (`raw_codebook*.txt`, `codebook_<export>.txt`) are
  not part of the public snapshot: they contain example values or small counts
  from the trial data. Variable names and coded values are in `codelists.csv`
  and the code.
- `codelists.csv` — English labels for the coded category values.
- `hospitals.csv` — clusters: randomised number, strata, annual births and the
  planned crossover schedule.
- `country_continent.csv` — country of origin to continent (UN M49).
- `sdm_items.csv` — shared decision-making and labour companionship items of the
  LCG form (English labels, gates, Norwegian wording).
- `bw_reference_skjaerven2000.csv` — Norwegian birthweight-for-gestational-age
  standard; used to derive the birthweight percentile in ADSL (not in the SAP
  v1.0 baseline table).
