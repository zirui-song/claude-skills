---
name: review-codex-plan
description: Use to have Claude critically review a Codex-authored implementation plan against the real codebase — or to have Codex draft a plan for a task first and then review it. The reverse of codex-review-plan. Trigger phrases include "review this Codex plan", "have Codex draft a plan then check it", "what's wrong with Codex's plan".
---

# review-codex-plan (Codex → Claude)

The "vice versa" direction: Claude rigorously reviews a plan that Codex wrote.
Either you supply the Codex plan, or this skill asks Codex to draft one first,
then Claude critiques it against the actual code.

Mechanics (wrapper, drafting template, timeout, output rules) live in the
**`codex-bridge`** skill — read it first.

## Workflow

1. **Get the Codex plan.** Two paths:
   - **(a) Supplied** — the user gives a plan file or pasted text. Use it directly.
   - **(b) Generate** — the user gives only a task. Use the *drafting template*
     from `codex-bridge` and run the wrapper to have Codex produce the plan:
     ```bash
     OUT=/tmp/codex-drafted-plan-$$.md
     bash ~/.claude/skills/codex-bridge/codex-exec.sh "$PROJECT_DIR" "$OUT" < "$PROMPT_FILE"
     ```
     (Long Bash timeout ~600000 ms.) The drafted plan lands in `$OUT`.

2. **Review it rigorously** as Claude. Read the relevant files, trace the code,
   and verify each of Codex's claims/assumptions against reality. Apply the same
   reviewer rubric used in `codex-bridge`: wrong assumptions, missing steps/edge
   cases, risky changes, simpler reuse-existing-code approaches, and what's right.

3. **Output.** Write the full critique to a temp file (or the plan file if you're
   producing a Claude-improved version), and summarize in **≤10 lines** in chat:
   - Strengths (brief).
   - Concrete issues, each with a `file:line` reference.
   - Missing steps / risks.
   - A Claude-improved version of the plan (or a pointer to where you wrote it).

## Notes

- Codex runs **read-only** when drafting; it cannot modify your files.
- Verify before you agree or disagree — ground every point in the actual code,
  not in plausibility. If Codex's plan is mostly sound, say so; don't manufacture
  objections.
- To run a full back-and-forth between the two models, use the **`plan-debate`**
  skill instead.
