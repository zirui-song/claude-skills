---
name: power-first
description: Use before interpreting any coefficient, writing up any result, or calling any null a finding — reports first-stage F, effective N, minimum detectable effect at 80% power, and the two most likely violations of the identifying assumption, so an underpowered design or weak first stage is stated up front rather than discovered by a referee. Trigger phrases include "is this null real", "am I underpowered", "MDE", "first stage", "before you interpret this".
---

# Power First

Diagnostics come **before** interpretation. Never write up a second stage as a finding until
this pass has run and passed.

## Report these four things first, in this order

1. **First-stage F** (IV/2SLS only) — Kleibergen-Paap rk Wald F for the actual clustering
   used, not the homoskedastic default. Report the exact value and the number of instruments.
   Below ~10, say the first stage is weak and stop there.
2. **Effective N** — not the raw row count. Report observations actually used after FE
   absorption and singleton dropping, plus the number of clusters in the clustering dimension.
   Few clusters is a power problem even with many rows.
3. **Minimum detectable effect at 80% power** — in the paper's own units (e.g., basis points
   of spread), given the estimated SE:
   `MDE ≈ 2.80 × SE` (two-sided, α = 0.05, 80% power).
   State it as "this design cannot rule out effects smaller than X bps."
4. **Two most likely violations of the identifying assumption** — named concretely for this
   setting, not generic. For each, say what evidence in the data would reveal it and what
   test would falsify it.

## Verdict, stated before any coefficient discussion

- **Weak first stage** (F < 10) → say so first. Do not report or interpret the second-stage
  coefficient as a finding.
- **Underpowered** (MDE larger than the effect size the theory predicts, or larger than
  comparable published estimates) → the null is uninformative. Say "underpowered," not
  "no effect."
- **Informative null** (MDE comfortably below the economically interesting effect) → this is
  a real finding. Write it up as one.

## Conventions

- An honest null beats a reframed one. Do not go hunting for a subsample where it works and
  lead with that.
- Report coverage limits up front: sample window, which firms are in the panel, what fraction
  of the population that is.
- When the user asks "is this result real," this skill runs before any other answer.
