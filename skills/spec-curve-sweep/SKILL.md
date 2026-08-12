---
name: spec-curve-sweep
description: Use to map where a headline result lives and dies across the full space of defensible specifications — enumerates researcher degrees of freedom, runs a 200-500 spec grid in the background with checkpointing and resume, then produces a specification curve, a variance-decomposition table, a note on where the result flips, and a compiled online appendix. Trigger phrases include "specification curve", "overnight robustness sweep", "run every defensible spec", "how fragile is this result".
---

# Spec Curve Sweep

The heavy sibling of `robustness-battery`. Use when the user wants the whole space mapped,
not five variants.

## 1. Enumerate researcher degrees of freedom

Read the primary estimation do-file and list every knob actually available:

- Clustering level (firm, industry, industry × year, two-way)
- Fixed-effect sets
- Control vectors (none / baseline / extended)
- Sample filters (rating bands, domestic-only, pre-COVID, balanced panel)
- Winsorization thresholds (none / 1% / 5%)
- Alternative outcome and treatment measures (fixed-pre vs. contemporaneous, levels vs. excess)
- Event-window lengths

## 2. Propose the grid before running it

Target 200–500 specifications. Present the cross-product **and the exclusions**: name every
combination ruled out as indefensible and say why (e.g., FE set that mechanically absorbs the
treatment, sample cut that leaves < 30 clusters). The user approves the grid before it runs.

## 3. Build the runner

- A **parameterized driver do-file** taking the knobs as arguments.
- A **Python runner** that executes the grid with parallelism, checkpoints each completed spec
  to disk immediately, and is **resumable** — a killed run restarts from the checkpoint, not
  from spec 1.
- One row per spec: all knob settings, `coef`, `se`, `t`, `p`, `n`, `n_clusters`, `status`.
- Failed specs are recorded with their Stata error code, never dropped.

## 4. Launch in the background and monitor

Run detached; report the job ID. Check progress periodically rather than blocking.

## 5. Deliverables

1. **Specification curve figure** — specs sorted by coefficient, significance shading, the
   headline spec marked.
2. **Variance-decomposition table** — which knob explains the most variation in the estimate.
3. **A short note** naming the specifications where the result flips sign or loses significance.
4. **Compiled online-appendix `.tex`** containing the full grid.
5. **A PR** with everything, plus a summary of what a hostile referee would seize on.

## Honesty rule

Report fragility straight. Do not bury, footnote, or aggregate away the variants that hurt the
result — those are the ones the user needs before a referee finds them. If the result only
survives in a minority of defensible specs, that is the headline of the report.
