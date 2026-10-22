---
name: refresh-pipeline
description: Use when running a multi-stage empirical pipeline (Stata + Python) to refresh tables/figures end-to-end. Uses the project's own runner when it has one, snapshots outputs and byte-compares after the run, performs pre-flight checks (Dropbox sync, column schemas, username path branches), verifies log files were produced, then summarizes key outputs and flags anomalies.
---

# Refresh Pipeline

A standard recipe to run a multi-stage empirical pipeline without losing time to recurring failures (Dropbox placeholders, missing columns, silent Stata crashes).

## 0. Use the project's runner if it has one

Look before improvising a run order: `run_pipeline.sh <stage>`, a rebuild-from-raw script (e.g. `RUN_from_raw_*.sh`, resumable, md5-compares against a frozen snapshot under `snapshots/`), or `Replication/run_all.py --only <step>`. Read `EXHIBIT_MAP.md` / the README for stage order and for stages marked manual or never-rerun (e.g. one-off WRDS pulls) — never rerun those. Before any WRDS pull, check whether the raw file already exists.

## Pre-flight checklist (run BEFORE any script)

1. **Dropbox sync check** — for every input file the next script needs, verify it is not an online-only placeholder. Placeholders show as 0 bytes or have a `.icloud`/`.dropbox` companion. Use:
   ```bash
   for f in <input_files>; do
     test -s "$f" && echo "OK $f" || echo "STUB $f"
   done
   ```
   If any STUB results, stop and ask the user to sync them locally before continuing.

2. **Column schema check** — for each script that consumes a CSV/Parquet produced by an upstream stage, grep the script for the column names it reads and confirm they exist in the upstream output. Especially check derived columns and any `*_quintile` / `*_decile` bins.

3. **Stata path branch check** — `grep -L '"<your-stata-username>"' *.do` in the pipeline directory (repeat for each machine's username if you run Stata on more than one). Any do-file missing a branch in its path-setting block will fail silently on that machine. Add the branch before running (see the `stata-preflight` skill).

4. **No `cap` around esttab** — `grep -n "cap.*esttab\|capture.*esttab" *.do`. Any hit must be unwrapped or it will silently drop in-memory estimates.

5. **Snapshot outputs** — record an md5 of every output the run will touch (tables, figures, intermediate `.dta`/`.parquet`) so you can byte-compare afterwards:
   ```bash
   find tables figures -type f -exec md5 -r {} + | sort -k2 > "$SCRATCH/pre_run.md5"
   ```

## Execution

Run stages in declared order. After each Stata `.do`:
- Confirm a log file was actually produced (`ls -la *.log` and check mtime).
- If no log appeared, stop — the script failed silently. Diagnose before continuing.

After each Python stage:
- Check that the declared output file exists and has > 0 rows.
- Report row counts and any NaN warnings.

Long stages: run them in the background and wait with Monitor (an until-loop on the log or output file). Prefer that over bare `sleep` polling, which some harnesses block; macOS has no `timeout`.

## After the run

- **Byte-compare** against the snapshot and list CHANGED vs UNCHANGED outputs. A change in an exhibit the request didn't target is a finding: report it, don't adopt it silently. Adopting a new snapshot (e.g. an `ADOPT=1` switch) is the user's call.
- **Orphans** — list outputs that no script produces any more. Ask before deleting them.

## Post-run summary (≤10 lines)

Report:
- Which stages ran green vs. failed.
- Headline coefficients (point estimate, SE, N) for any regression run.
- KP F-stat for any IV.
- Any binning sanity issues (e.g., a quintile that contains < 10% or > 30% of obs — flags share-weighted binning bugs).
- Changed vs unchanged exhibits from the byte-compare.
- Path to updated tables/figures.

Link table paths rather than pasting whole tables, but show a table in chat when the user asks for it.

## Common failure modes (check these first when something breaks)

- A script reads a column the upstream stage no longer writes → re-run (or fix) the upstream stage that builds it.
- Quintiles forced to uniform 20% shares → binning by worker-share instead of rank position; fix to use `pd.qcut` on rank.
- Empty Stata log → missing username path branch, or `cap` swallowing the error.
- Zero-observation or short merge → check key types (string vs int), trim/upper case on join keys, and `encoding("utf-8")` on `import delimited` (accented names fail to match otherwise).
- Shell on macOS: zsh aborts a whole command on an unmatched glob ("no matches found") — quote the pattern or use `find`; BSD `sed -i` needs `''`; there is no `timeout`.
