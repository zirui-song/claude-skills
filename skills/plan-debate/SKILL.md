---
name: plan-debate
description: Use to run a multi-round cross-model debate on an implementation plan — Claude drafts, Codex (gpt-5.4) critiques against the real codebase, Claude rebuts and synthesizes, optional second Codex pass — converging on a stronger plan. Combines codex-review-plan and review-codex-plan. Trigger phrases include "debate this plan with Codex", "go back and forth with Codex on the plan", "have Claude and Codex argue out the plan".
---

# plan-debate (Claude ⇄ Codex, round-trip)

Run a short, converging debate between Claude and Codex on a plan. The goal is a
single stronger plan plus an honest record of where the two models still
disagree.

Mechanics (wrapper, templates, timeout, output rules) live in the
**`codex-bridge`** skill. This skill orchestrates `codex-review-plan` (Claude →
Codex) and `review-codex-plan` (Codex → Claude) — read all three first.

## Workflow

1. **Ensure a plan exists.** If there's an active `~/.claude/plans/` file or a
   plan the user supplied, use it. If not, draft one first via
   **`superpowers:writing-plans`**.

2. **Round 1 — Codex critiques.** Run the `codex-review-plan` flow: send the plan
   to Codex (read-only, in the project dir), get its critique. Then **synthesize
   a revised plan** as Claude, incorporating accepted points via
   **`superpowers:receiving-code-review`** (verify each point; push back with
   reasons on wrong ones).

3. **Round 2 (optional) — focused re-review.** Send the *revised* plan back to
   Codex with a focused prompt: "Were the following issues addressed? What gaps
   remain?" (list the round-1 issues). Synthesize again.

4. **Stop condition.** End when Codex raises no new substantive issue, or after
   **N rounds (default 2)** — whichever comes first. Don't loop indefinitely.

5. **Output.**
   - Write the final converged plan to the plan file.
   - Give a short **per-round changelog** (≤10 lines): what each round changed.
   - **Surface unresolved disagreements** between Claude and Codex explicitly —
     state each side's position and your recommendation. Do not bury them.
   - Note the temp paths holding each round's full Codex output.

## Notes

- Each Codex call uses a long Bash timeout (~600000 ms); `xhigh` is slow. For a
  faster debate, append `-c model_reasoning_effort=high` to the wrapper calls.
- Codex runs **read-only** throughout — it cannot modify your files.
- Keep chat output terse; full reviews stay in their temp files.
