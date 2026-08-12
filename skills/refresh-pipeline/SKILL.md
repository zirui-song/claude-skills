---
name: refresh-pipeline
description: Use when running a multi-stage empirical pipeline (Stata + Python) to refresh tables/figures end-to-end. Performs pre-flight checks (Dropbox sync, column schemas, username path branches), executes scripts in order, verifies log files were produced, then summarizes key outputs and flags anomalies.
---

# Refresh Pipeline

A standard recipe to run a multi-stage empirical pipeline without losing time to recurring failures (Dropbox placeholders, missing columns, silent Stata crashes).

## Pre-flight checklist (run BEFORE any script)

1. **Dropbox sync check** — for every input file the next script needs, verify it is not an online-only placeholder. Placeholders show as 0 bytes or have a `.icloud`/`.dropbox` companion. Use:
   ```bash
   for f in <input_files>; do
     test -s "$f" && echo "OK $f" || echo "STUB $f"
   done
   ```
   If any STUB results, stop and ask the user to sync them locally before continuing.

2. **Column schema check** — for each script that consumes a CSV/Parquet produced by an upstream stage, grep the script for the column names it reads and confirm they exist in the upstream output. Especially check for: `seniority_c`, topic columns, any `*_quintile` / `*_decile` bins.

3. **Stata path branch check** — `grep -L "<your-stata-username>" *.do` in the pipeline directory. Any do-file missing a `<your-stata-username>` username branch in its path-setting block will fail silently. Add the branch before running.

4. **No `cap` around esttab** — `grep -n "cap.*esttab\|capture.*esttab" *.do`. Any hit must be unwrapped or it will silently drop in-memory estimates.

## Execution

Run scripts in declared DAG order. After each Stata `.do`:
- Confirm a log file was actually produced (`ls -la *.log` and check mtime).
- If no log appeared, stop — the script failed silently. Diagnose before continuing.

After each Python stage:
- Check that the declared output file exists and has > 0 rows.
- Report row counts and any NaN warnings.

## Post-run summary (≤10 lines)

Report:
- Which stages ran green vs. failed.
- Headline coefficients (point estimate, SE, N) for any regression run.
- KP F-stat for any IV.
- Any binning sanity issues (e.g., a quintile that contains < 10% or > 30% of obs — flags share-weighted binning bugs).
- Path to updated tables/figures.

Do NOT paste full regression tables into chat. Write them to `results/` and link the path.

## Common failure modes (check these first when something breaks)

- `panel_seniority_quintile.csv` missing `seniority_c` → re-run upstream stage that builds it.
- Quintiles forced to uniform 20% shares → binning by worker-share instead of rank position; fix to use `pd.qcut` on rank.
- Empty Stata log → missing `<your-stata-username>` path branch, or `cap` swallowing the error.
- Zero-observation merge → check key types (string vs int) and trim/upper case on join keys.
