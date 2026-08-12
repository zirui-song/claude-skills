#!/usr/bin/env bash
# codex-exec.sh — thin reusable wrapper around the Codex CLI for cross-model review.
#
# Usage:
#   codex-exec.sh <project_dir> <out_file> [extra codex args...]
#
# The FULL prompt (review instructions + the plan text) is read from stdin.
# The agent's final message (the review) is written to <out_file> AND echoed
# to stdout. Codex runs read-only: it can read the codebase but cannot modify it.
#
# Examples:
#   printf '%s' "$PROMPT" | codex-exec.sh "$PWD" /tmp/review.md
#   # faster smoke test:
#   printf '%s' "$PROMPT" | codex-exec.sh "$PWD" /tmp/review.md -c model_reasoning_effort=low
#   # explicit model:
#   printf '%s' "$PROMPT" | codex-exec.sh "$PWD" /tmp/review.md -m gpt-5.4
#
# Notes:
# - Codex CLI is installed via the desktop app and is usually NOT on PATH, so we
#   fall back to the app bundle binary.
# - This account uses ChatGPT-account auth, under which CLI `exec` rejects
#   gpt-5.4 / gpt-5-codex ("not supported when using Codex with a ChatGPT
#   account"). So we force a working model. Default: gpt-5.5 (most capable that
#   works here). Override with env CODEX_REVIEW_MODEL or by passing -m yourself.
#   gpt-5.4-mini is a faster alternative. Effort defaults to config (xhigh) and
#   can be lowered with `-c model_reasoning_effort=high|low`. xhigh can take
#   several minutes — call this script with a long timeout (~600000 ms).
set -euo pipefail

CODEX_REVIEW_MODEL="${CODEX_REVIEW_MODEL:-gpt-5.5}"

CODEX_BIN="$(command -v codex 2>/dev/null || true)"
if [[ -z "${CODEX_BIN}" ]]; then
  CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
fi
if [[ ! -x "${CODEX_BIN}" ]]; then
  echo "ERROR: codex binary not found (looked on PATH and at ${CODEX_BIN})." >&2
  echo "Install the Codex desktop app or put 'codex' on PATH." >&2
  exit 127
fi

if [[ $# -lt 2 ]]; then
  echo "Usage: codex-exec.sh <project_dir> <out_file> [extra codex args...]" >&2
  exit 64
fi

DIR="$1"; OUT="$2"; shift 2
[[ -d "${DIR}" ]] || { echo "ERROR: project_dir not a directory: ${DIR}" >&2; exit 66; }

# Inject the default model only if the caller didn't pass their own -m/--model.
MODEL_ARGS=(-m "${CODEX_REVIEW_MODEL}")
for a in "$@"; do
  if [[ "$a" == "-m" || "$a" == "--model" ]]; then MODEL_ARGS=(); break; fi
done

# Prompt is read from stdin via the trailing '-'.
"${CODEX_BIN}" exec \
  --sandbox read-only \
  --skip-git-repo-check \
  -C "${DIR}" \
  -o "${OUT}" \
  "${MODEL_ARGS[@]}" \
  "$@" \
  -
