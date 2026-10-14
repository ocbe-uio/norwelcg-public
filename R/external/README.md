# R/external/

Shared, non-trial-specific helper functions, copied faithfully from the ImPRESS
repo. `_targets.R` sources all `*.R` under `R/` recursively, so `functions.R` is
picked up automatically (markdown files are ignored).

`functions.R` provides:

- **Viedoc import helpers** — `pick()`, `get_raw()`, `labeliser()`,
  `factoriser()`, `remove_fct()`, `remove_cd()` (from the template; not used
  by NORWELCG, which reads flat Stata files).
- **Path helpers** — `cfg_path()` and the shortcuts `path_raw()`, `path_adam()`,
  `path_reports()`, `path_outputs()`, `path_meta()`, `path_export()`,
  `path_rawfile()`. These read the `paths:` and `export:` keys from
  `config/cfg.yml` (used by the ADaM and RD functions and `R/make_anon/make_anon.R`).
- **Table helpers** — `mean_sd()`, `median_iqr()`, `n_pct()`, `missing_f()`,
  `ae_n_pct()`, `ae_N_n_pct()`, `empty()`, `stats_exec()`.
- **Plot helper** — `plot_cont_margins()` (requires `ggformula`).

Requires the `paths:` section in `config/cfg.yml` (present in the template).
