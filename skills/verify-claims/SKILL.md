---
name: verify-claims
description: Use before the user reads any draft, memo, literature review, or results write-up — runs an adversarial verification pass that hunts factual errors, unsourced claims, and numbers that don't match the underlying code or output files. Every claim is either cited to an exact file:line or marked UNVERIFIED. Trigger phrases include "verify this draft", "check my numbers", "adversarial verification pass", "did you make this up".
---

# Verify Claims

Standing closing step on any written output. Run it **before** the user reads the draft,
not after they catch something.

## Inputs (infer if obvious, otherwise ask)

- Draft file path (`.tex`, `.md`, or a section of one).
- Where the underlying evidence lives: estimation logs, `results/` CSVs, do-files, source PDFs.

## Method

Spawn a subagent whose **only** job is to find errors. Give it the draft and the evidence
directories. It must not fix anything, praise anything, or summarize the argument.

For every checkable claim in the draft, it returns one of:

- **VERIFIED** — with the exact `file:line` of the code, log, or output file the number came
  from, plus the value found there.
- **MISMATCH** — draft says X, source says Y. Report both values and the source location.
- **UNVERIFIED** — no source located. Say so plainly. Do not reason backward to a source
  that "probably" produced it.

Claim types to sweep:

1. **Numbers** — coefficients, standard errors, t-stats, p-values, sample sizes, F-stats,
   percentages, dates, sample-window endpoints. Cross-check against the estimation log, not
   against another sentence in the draft.
2. **Citations** — does the cited paper actually make that claim? Check the real paper, not
   memory. Attribution errors count as factual errors.
3. **Unsourced assertions** — institutional facts, "the literature finds…", magnitude claims,
   anything phrased as established that has no cite and no output file behind it.
4. **Internal consistency** — same quantity quoted in abstract, text, and table; table N vs.
   text N; sign language ("increases") vs. the actual coefficient sign.

## Output

A single ranked list, most damaging first, before any prose commentary:

| # | Claim (quoted) | Draft location | Status | Source `file:line` | Found value |

Rank by: would a referee notice, and does it change the paper's conclusion.

Close with a count: `n VERIFIED / n MISMATCH / n UNVERIFIED`.

## Anti-patterns

- Do not fix the prose in this pass. Show the diff first; the user decides.
- Do not mark something VERIFIED because it looks plausible or matches your memory of an
  earlier run. Open the file.
- Do not soften an UNVERIFIED into "likely correct." The whole point is the honest label.
