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
#   printf '%s' "$PROMPT" | codex-exec.sh "$PWD" /tmp/review.md -m <model>
#
# Notes:
# - The Codex CLI ships inside the ChatGPT desktop app and is usually NOT on
#   PATH, so we fall back to the app-bundle binary (current location first, then
#   the old standalone Codex.app location).
# - Model and reasoning effort come from ~/.codex/config.toml by default. Set env
#   CODEX_REVIEW_MODEL, or pass -m yourself, to override. If exec rejects the
#   config model under ChatGPT-account auth ("not supported when using Codex
#   with a ChatGPT account"), pick another slug from ~/.codex/models_cache.json.
#   High effort can take several minutes — call this script with a long timeout
#   (~600000 ms).
set -euo pipefail

CODEX_BIN="$(command -v codex 2>/dev/null || true)"
if [[ -z "${CODEX_BIN}" ]]; then
  for cand in \
    "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex" \
    "/Applications/Codex.app/Contents/Resources/codex"; do
    if [[ -x "${cand}" ]]; then CODEX_BIN="${cand}"; break; fi
  done
fi
if [[ -z "${CODEX_BIN}" || ! -x "${CODEX_BIN}" ]]; then
  echo "ERROR: codex binary not found (looked on PATH, in ChatGPT.app, and in Codex.app)." >&2
  echo "Install the ChatGPT desktop app or put 'codex' on PATH." >&2
  exit 127
fi

if [[ $# -lt 2 ]]; then
  echo "Usage: codex-exec.sh <project_dir> <out_file> [extra codex args...]" >&2
  exit 64
fi

DIR="$1"; OUT="$2"; shift 2
[[ -d "${DIR}" ]] || { echo "ERROR: project_dir not a directory: ${DIR}" >&2; exit 66; }

# Pass a model only if CODEX_REVIEW_MODEL is set and the caller didn't pass -m/--model;
# otherwise ~/.codex/config.toml decides.
MODEL_ARGS=()
if [[ -n "${CODEX_REVIEW_MODEL:-}" ]]; then
  MODEL_ARGS=(-m "${CODEX_REVIEW_MODEL}")
  for a in "$@"; do
    if [[ "$a" == "-m" || "$a" == "--model" ]]; then MODEL_ARGS=(); break; fi
  done
fi

# Prompt is read from stdin via the trailing '-'.
"${CODEX_BIN}" exec \
  --sandbox read-only \
  --skip-git-repo-check \
  -C "${DIR}" \
  -o "${OUT}" \
  ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} \
  "$@" \
  -
