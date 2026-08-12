---
name: referee-panel
description: Use before sending a design or draft to a coauthor or referee — launches five parallel adversarial subagents (identification, power, literature, data provenance, independent replication) against the research design in the repo, each citing file:line evidence, then synthesizes one threat memo ranked by probability-right × damage-if-right. Trigger phrases include "referee panel", "attack this design", "what would a referee say", "adversarial review of my paper".
---

# Referee Panel

Five hostile referees in parallel, then one synthesis. Distinct from the `panel-*` persona
skills: those channel named scholars on framing and contribution; this one attacks
correctness and identification with code evidence.

## Inputs (ask if not obvious)

- Which draft / design, and which headline coefficient is the target.
- Where the estimation code and raw data live.

## The five mandates

Launch all five as parallel subagents. Each must cite `file:line` from the code or data —
evidence, not vibes. Each is instructed to look for problems, not to balance praise.

1. **IDENTIFICATION REFEREE** — bad controls, post-treatment conditioning, mechanical FE
   absorption, parallel-trends violations. Must end with the specific placebo or triple-diff
   that would falsify the claim.
2. **POWER ANALYST** — for every null, run or simulate a power calculation. Is the null
   informative or is the design underpowered? Give an MDE in the paper's own units. (See the
   `power-first` skill for the reporting format.)
3. **LITERATURE REFEREE** — find the three closest published papers and state precisely what
   is left after subtracting them. Be brutal about novelty.
4. **DATA PROVENANCE AUDITOR** — trace every key variable back to raw source. Flag merge-key
   risks (gvkey/cusip zero-padding, fiscal-year alignment, survivorship) and check coverage
   across the sample window.
5. **INDEPENDENT REPLICATOR** — re-derive the headline coefficient from raw data with its own
   code, **without reading the existing estimation scripts**. Report any discrepancy.

## Synthesis

One memo. Threats ranked by `P(referee is right) × damage if right`. For each threat:

- The claim it attacks, and the file:line evidence behind the attack.
- A concrete test runnable this week.
- The code to run it.

**Flag disagreements between agents explicitly** — if the replicator's coefficient differs
from the identification referee's read of the spec, surface that rather than smoothing it
into a consensus sentence.

## Anti-patterns

- Do not let an agent return "the design looks sound." Its mandate is to find the failure.
- Do not drop a threat because it would be expensive to address. Rank it and let the user decide.
- Do not paste all five raw reports into chat — write them to `results/referee/` and give the
  ranked memo.
