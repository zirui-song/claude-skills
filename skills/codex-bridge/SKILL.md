---
name: codex-bridge
description: Shared mechanics for calling the Codex CLI to review plans. Reference for the codex-review-plan, review-codex-plan, and plan-debate skills — not invoked directly. Holds the wrapper invocation, reviewer prompt template, and gotchas.
---

# Codex Bridge (shared mechanics)

This is a **reference skill**. Don't trigger it on its own — the three workflow
skills (`codex-review-plan`, `review-codex-plan`, `plan-debate`) read it so the
Codex-calling mechanics live in exactly one place.

## The wrapper

All Codex calls go through one saved script (never inline the `codex exec`
invocation):

```
~/.claude/skills/codex-bridge/codex-exec.sh <project_dir> <out_file> [extra codex args...]
```

- The **full prompt** (instructions + the plan/text) is piped to **stdin**.
- The agent's final message (the review) is written to `<out_file>` and echoed to stdout.
- Codex runs `--sandbox read-only`: it reads the codebase but cannot modify anything.
- `--skip-git-repo-check` is on (research dirs often aren't git repos).

### Standard call (from a Bash tool call)

```bash
PROMPT_FILE=/tmp/codex-prompt-$$.md      # compose instructions + <PLAN> into this
OUT=/tmp/codex-plan-review-$$.md
bash ~/.claude/skills/codex-bridge/codex-exec.sh "$PROJECT_DIR" "$OUT" < "$PROMPT_FILE"
```

**Always set a long Bash timeout (~600000 ms).** Effort defaults to the config's
`model_reasoning_effort` (see `~/.codex/config.toml`), which can take several minutes at
high settings.

### Model (important — ChatGPT-account auth)

The wrapper does **not** force a model: `~/.codex/config.toml` decides. This matters if you
authenticate Codex with a **ChatGPT account** rather than an API key, because `exec` rejects
some models under that auth.

- Override with env `CODEX_REVIEW_MODEL=<model>` or by passing `-m <model>` to
  the wrapper (your `-m` wins).
- Available slugs are listed in `~/.codex/models_cache.json`.

If you ever see "not supported when using Codex with a ChatGPT account", that
model isn't allowed under this auth — pick another slug from the cache file.

### Speed overrides (optional extra args)

- Faster turnaround: append `-c model_reasoning_effort=high` (or `=low` for smoke tests).
- Or pass a lighter model with `-m <model>`.

## Binary location

Codex ships inside the ChatGPT desktop app and is usually **not on PATH**. The
wrapper resolves it as `command -v codex` → fallback
`/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex`
→ fallback `/Applications/Codex.app/Contents/Resources/codex` (old standalone app).
If it can't find any, it exits 127 with an install hint.

## Reviewer prompt template

Compose this (filling `<PLAN>`) and pipe it to the wrapper. For
`review-codex-plan`'s "generate a plan first" path, swap in the drafting variant
below.

**Review template:**

> You are a senior engineer doing an adversarial review of another AI's
> implementation plan for THIS repository. Read whatever files you need to
> validate it against the actual code. Identify, concretely and with `file:line`
> references:
> 1. Incorrect assumptions about the codebase or existing APIs.
> 2. Missing steps, edge cases, or dependencies the plan overlooks.
> 3. Risky or breaking changes, and how to de-risk them.
> 4. Simpler / more idiomatic approaches that reuse existing code.
> 5. What the plan gets right (brief).
>
> End with (a) a prioritized, actionable fix list and (b) a one-line verdict:
> ship / revise / rethink. Be terse and specific. Critique — do not rewrite the
> whole plan.
>
> ```
> <PLAN>
> ...plan text here...
> </PLAN>
> ```

**Drafting template (for the reverse direction):**

> You are a senior engineer. Produce a concrete, step-by-step implementation
> plan for the task below, grounded in THIS repository (read files as needed).
> Name the specific files/functions to change, call out risks and edge cases,
> and prefer reusing existing code. Keep it tight and actionable.
>
> Task: ...

## Output conventions (per the user's CLAUDE.md)

- Keep the full Codex review in the temp `<out_file>` (e.g.
  `/tmp/codex-plan-review-*.md`). **Do not paste the whole thing into chat.**
- Summarize the key points in **≤10 lines** in chat, then act on them.

## Resolving `<project_dir>`

The directory whose code the plan is about — so Codex can validate against real
files. Infer from the plan content (a referenced project path); otherwise use
the current working directory. `--skip-git-repo-check` makes non-repo dirs fine.
