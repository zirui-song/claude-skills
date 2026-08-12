---
name: verify-numbers-pipeline
description: Use to make every number in a paper machine-checkable — inventories scripts to the tables they produce, builds a YAML manifest of every numeric claim in the manuscript prose, writes verify_numbers.py to re-parse estimation logs and diff them against the text, adds make all / make verify targets and a pre-commit hook that blocks stale numbers. Trigger phrases include "self-verifying pipeline", "check every number in the paper", "which sentences went stale", "make verify".
---

# Verify Numbers Pipeline

Builds the infrastructure that makes stale numbers impossible to commit. One-time setup per
paper repository; `verify-claims` is the per-draft pass that runs on top of it.

## 1. Inventory

Map every Stata do-file and Python script to the `.tex` tables and figures it produces. Write
it to `pipeline_map.yaml`: script → outputs → the log file it writes.

## 2. Claim manifest

`claims.yaml` — every numeric claim appearing in the **manuscript prose** (not just the
tables): coefficients, standard errors, sample sizes, F-stats, percentages. Each entry:

```yaml
- id: main_effect_bps
  text: "spreads fall by 42.5 basis points"
  tex_file: sections/results.tex
  value: -42.5
  tolerance: 0.05
  source_log: logs/main_spec.log
  line_pattern: 'post_treat\s+-?\d+\.\d+'
```

## 3. `verify_numbers.py`

Re-parses each `source_log`, extracts the value via `line_pattern`, asserts it matches
`value` within `tolerance`. Prints a diff table of every mismatch: claim id, manuscript value,
log value, delta, and the `file:line` on both sides. Non-zero exit on any mismatch.

A claim whose log is missing is a **failure**, not a skip — it means the number was never
reproduced.

## 4. Make targets

- `make all` — full pipeline, raw data → compiled PDF.
- `make verify` — assertion layer only, no re-estimation. Fast enough to run constantly.

## 5. Pre-commit hook

Blocks the commit when `make verify` fails. Prints the diff table so the user sees which
sentence went stale.

## 6. First run

Run it against the current repo and give a **ranked report of every stale number found** —
ranked by how central the claim is to the paper's argument.

**Do not fix the prose in this pass.** Show the diff first; the user decides which side is
right (the text may be current and the log stale, or vice versa).
