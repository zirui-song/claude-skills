---
name: robustness-battery
description: Use when preparing a paper for submission or responding to referees and you need a full battery of robustness checks for a headline result, or when the user asks "what happens if…" about a single spec change. Enumerates reviewer-anticipated variants across estimator, sample, controls, weights, and clustering, runs them in Stata, and produces a comparison table + sign/significance stability summary; a what-if mode runs one change in a scratch copy and shows the result in chat.
---

# Robustness Battery

Standardized referee-anticipating robustness sweep for any headline coefficient. All estimation
runs in Stata (`reghdfe`/`ivreghdfe`/`ppmlhdfe`/`robreg`, from SSC) — never Python.

## Before anything: read the project's rules

The project's CLAUDE.md and memory override the defaults below. Check them for:
- the FE ladder (e.g. cumulative: (1) industry×year, (2) +rating, (3) +borrower, (4) +bank),
  and any FE the project rules out (e.g. no firm FE);
- the full control set — use it in every variant unless the variant is about controls;
- the default clustering (e.g. two-way firm + officer instead of firm);
- heterogeneity: pooled interactions, not sample splits, unless the user asks for splits.

Then state the exact main spec back to the user — LHS, RHS, FE set, sample filter,
clustering — **before** running anything.

## What-if mode (one change at a time)

When the user asks "what happens if we add bank FE / cluster by X / drop 2020 / …":

1. Copy the main do-file to a scratch variant. Never edit the main do-file in this mode.
2. Apply only the one change the user named. Don't add or drop anything else.
3. Run it (batch Stata via a space-free wrapper; see `stata-preflight`) and check the log.
4. Show the result **in chat**: a small table with baseline vs variant — coef, SE, stars, N,
   clusters — plus the exact estimation command. One or two sentences on what moved.
5. Adopt the change into the main spec only when the user says so.

## Full battery: variants to run (5 families × ≥1 each)

1. **Estimator** — OLS (`reghdfe`), Huber/M and MM (`robreg`), Poisson (`ppmlhdfe`, if the
   outcome is non-negative), stacked DiD (if event-time).
2. **Sample** — drop top/bottom 1% of outcome, drop largest 1% by size, balanced panel only,
   alt time window (e.g., excluding COVID years), drop singleton FE groups.
3. **Controls / FE** — each rung of the project's FE ladder; the full control set throughout.
4. **Weights** — unweighted, WLS by inverse propensity, WLS by firm size.
5. **Clustering** — the project default, plus the obvious alternatives (one-way vs two-way,
   wild-cluster bootstrap via `boottest` when clusters are few).

Aim for ≥ 5 variants per headline coefficient.

## Fast-grid mode (when the user names the columns)

When the user asks for a named set of columns "in one pass," run the main spec plus those
columns **together, in a single pass**, and return one comparison table with `coef`, `SE`,
and `N` per column. A paper's standing grid lives in that project's memory, not here.

- **Never silently drop a failing spec.** If a column errors (r(504), collinearity,
  time-invariant regressor, empty sample), keep the column in the table and write the
  failure reason in its cell. Report the Stata error code verbatim.
- One pass means one batch: don't hand back column 1 and wait for a follow-up asking for
  column 2.

## Execution

For each variant, write a small Stata do-file that:
- Loads the same data the main spec uses.
- Applies only the variant's modification.
- Estimates the model.
- Appends one row to a results CSV with columns: `family, variant, coef, se, t, p, n, n_clusters, pass_sign, pass_sig`.

Run independent variants in parallel (e.g. `xargs -P 4` over batch Stata wrappers). Python
may read the CSV to draw the forest plot; it never estimates anything.

## Output

1. The full raw results CSV, in the project's results folder.
2. An appendix `.tex` table grouped by family, following the project's table style.
3. A coefficient stability forest plot, headline overlaid as a vertical line.
4. Short summary (≤ 8 lines): how many variants pass sign, how many pass significance, and any flagged spec where the headline breaks (name the variant).

## Stopping rule

Stop only when every tracked coefficient has ≥ 5 variants AND every variant either:
- Passes both sign and significance, OR
- Has been explicitly noted in the summary with a sentence on why it differs.

## Notes

- Link the full grid by path rather than pasting it; show the comparison table in chat when the user asks.
- If a variant runs > 30 minutes, run it in the background and wait with a monitor loop rather than bare `sleep` polling.
