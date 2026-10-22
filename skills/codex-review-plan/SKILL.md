---
name: codex-review-plan
description: Use after drafting an implementation or research plan (in plan mode, or a ~/.claude/plans/ file) to get a second-opinion review from Codex against the actual codebase, then critically incorporate the feedback. Makes the Claude Code plan better via cross-model review. Trigger phrases include "send the plan to Codex", "have Codex review this plan", "get a second opinion on the plan".
---

# codex-review-plan (Claude → Codex)

Send a Claude-authored plan to Codex for an adversarial review against the real
codebase, then critically fold in the good points. Use it right after drafting a
plan and before committing to it.

Mechanics (wrapper, prompt template, timeout, output rules) live in the
**`codex-bridge`** skill — read it first.

## Workflow

1. **Resolve the plan.** In priority order:
   - The active plan-mode plan file in `~/.claude/plans/` (the one for this
     session; if ambiguous, the most recently modified `*.md`).
   - Else a file path the user provided.
   - Else pasted plan text → write to a temp file.

2. **Resolve the target project dir** (the codebase the plan is about). Infer
   from the plan's content (a referenced project path); else use cwd.
   `--skip-git-repo-check` handles non-repo research dirs.

3. **Compose the prompt.** Use the *review template* from `codex-bridge`, with
   the plan text inside the `<PLAN>…</PLAN>` block. Write it to a temp prompt file.

4. **Call Codex** via the wrapper, with a long Bash timeout (~600000 ms):
   ```bash
   OUT=/tmp/codex-plan-review-$$.md
   bash ~/.claude/skills/codex-bridge/codex-exec.sh "$PROJECT_DIR" "$OUT" < "$PROMPT_FILE"
   ```
   For a quick pass, append `-c model_reasoning_effort=high`.

5. **Summarize.** Read `$OUT` (kept in the temp file). Summarize the key points
   in **≤10 lines** in chat. Don't paste the whole review.

6. **Incorporate critically.** Invoke **`superpowers:receiving-code-review`** and
   follow it: evaluate each point on its merits, accept the valid ones, and push
   back — with reasons — on anything wrong or inapplicable. No performative
   agreement; verify against the code before changing the plan.

7. **Revise + report.** Update the plan file with the accepted changes. Report,
   briefly: what changed, and what you rejected and why. Note the path to the
   full review (`$OUT`).

## Notes

- **Plan mode:** this is meant to run during plan mode. The `codex exec` Bash
  call will prompt for permission once; editing the plan file is already allowed.
- Codex runs **read-only** — it cannot modify your files.
- If Codex returns nothing useful or errors, say so plainly; don't fabricate a
  review.
