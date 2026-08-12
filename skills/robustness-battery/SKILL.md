---
name: robustness-battery
description: Use when preparing a paper for submission or responding to referees and you need a full battery of robustness checks for a headline result. Enumerates reviewer-anticipated variants across estimator, sample, controls, weights, and clustering, runs them as parallel jobs, and produces a comparison table + sign/significance stability summary.
---

# Robustness Battery

Standardized referee-anticipating robustness sweep for any headline coefficient.

## Inputs (ask the user)

- Main spec do-file or script (path).
- Dependent variable and key regressor(s) to track.
- Headline coefficient sign + p-value to test stability against.

## Variants to run (5 families × ≥1 each)

1. **Estimator** — OLS, Gassen-Veenman M-est, MM-est, Poisson (if outcome non-negative), LP-DiD or stacked DiD (if event-time).
2. **Sample** — drop top/bottom 1% of outcome, drop largest 1% by size, balanced panel only, alt time window (e.g., pre-COVID), drop singleton FE groups.
3. **Controls** — none, firm FE only, firm + year FE, firm + industry-year FE, plus bank- or lender-level controls.
4. **Weights** — unweighted, WLS by inverse propensity, WLS by firm size.
5. **Clustering** — primary (firm), two-way (firm + year), two-way (firm + bank/lender), bootstrap SEs.

Aim for ≥ 5 variants per headline coefficient.

## Fast-grid mode (default when the user names the variants)

When the user asks for "the grid in one pass," run the main spec plus these six columns
**together, in a single pass**, and return one comparison table with `coef`, `SE`, and `N`
per column:

1. Baseline, firm-clustered
2. Industry × year FE
3. Rating × year FE
4. 90% CI (report the interval, not just stars)
5. Contemporaneous treatment measure
6. Domestic-only subsample

Rules for this mode:

- **Never silently drop a failing spec.** If a column errors (r(504), collinearity,
  time-invariant regressor, empty sample), keep the column in the table and write the
  failure reason in its cell. Report the Stata error code verbatim.
- State the exact main spec back to the user — LHS, RHS, FE set, sample filter, clustering —
  **before** running anything.
- One pass means one batch: don't hand back column 1 and wait for a follow-up asking for
  column 2.

## Execution

For each variant, write a small Stata or Python wrapper that:
- Loads the same data the main spec uses.
- Applies only the variant's modification.
- Estimates the model.
- Appends one row to `results/robustness_results.csv` with columns: `family, variant, coef, se, t, p, n, pass_sign, pass_sig`.

Run variants in parallel where independent (e.g., `xargs -P 4` over Stata batch mode, or asyncio over Python).

## Output

1. `results/robustness_results.csv` — full raw results.
2. `results/appendix_robustness.tex` — esttab/booktabs table grouped by family.
3. `results/robustness_forest.png` — coefficient stability forest plot, headline overlaid as vertical line.
4. Short summary (≤ 8 lines): how many variants pass sign, how many pass significance, and any flagged spec where the headline breaks (name the variant).

## Stopping rule

Stop only when every tracked coefficient has ≥ 5 variants AND every variant either:
- Passes both sign and significance, OR
- Has been explicitly noted in the summary with a sentence on why it differs.

## Notes

- Do NOT paste full tables into chat. Write to `results/` and link the path.
- If a variant runs > 30 minutes, send it to background and report job ID.
