#!/usr/bin/env bash
# sync-check-cli.sh (optional)
# When `grok` is on PATH, compare skill contract strings against live CLI help.
#
# Usage: ./scripts/sync-check-cli.sh
# Exit 0 if grok missing (skip) or checks pass; non-zero on mismatch.
set -euo pipefail

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
SKILL="$ROOT/skills/grok-build/SKILL.md"
REF_DIR="$ROOT/skills/grok-build/references"

if ! command -v grok >/dev/null 2>&1; then
  echo "→ sync-check-cli: grok not on PATH — skipping"
  exit 0
fi

echo "→ sync-check-cli: comparing skill contract to live grok"

VERSION_OUT="$(grok --version 2>&1 || true)"
echo "  grok --version: $VERSION_OUT"
if ! echo "$VERSION_OUT" | grep -Fq '1.0.48'; then
  echo "FAIL: skill contract targets grok 1.0.48; live binary is: $VERSION_OUT"
  exit 1
fi

HELP="$(grok --help 2>&1 || true)"

# Dead flags must NOT appear as live options in help
DEAD_FLAGS=(--best-of-n --self-verify)
for flag in "${DEAD_FLAGS[@]}"; do
  if echo "$HELP" | grep -F -q -- "$flag"; then
    echo "FAIL: live grok --help still lists dead/unexpected flag: $flag"
    echo "  Skill assumes these error; update skill or this checker."
    exit 1
  fi
done
# --check is too generic for substring; look for option-style listing
if echo "$HELP" | grep -Eiq -- '(^|[[:space:]])--check([[:space:],]|$)'; then
  # Confirm it's not part of another word; if present as option, fail
  if echo "$HELP" | grep -E -- '(^|[[:space:]])--check([[:space:]]|$)' | grep -viq restore; then
    echo "WARN: --check appears in help; confirm if reintroduced"
  fi
fi

# Required live concepts in help
for flag in --always-approve --restore-code --include-partial-messages --worktree; do
  if ! echo "$HELP" | grep -F -q -- "$flag"; then
    echo "FAIL: expected live flag missing from grok --help: $flag"
    exit 1
  fi
done

if ! echo "$HELP" | grep -F -q -- "streaming-messages-json"; then
  echo "FAIL: streaming-messages-json missing from grok --help"
  exit 1
fi

# --worktree creates a git worktree on this binary (including headless)
if ! echo "$HELP" | grep -Fq 'new git worktree'; then
  echo "FAIL: grok --help no longer says --worktree starts a new git worktree"
  exit 1
fi
retired_worktree="does not create a ""worktree"
if echo "$HELP" | grep -Fq "$retired_worktree"; then
  echo "FAIL: grok --help still uses the retired worktree sentence; re-audit the skill"
  exit 1
fi
GUIDE="${HOME}/.grok/docs/user-guide/14-headless-mode.md"
if [[ -f "$GUIDE" ]]; then
  if ! grep -Fq 'Not combinable with `--fork-session`' "$GUIDE"; then
    echo "FAIL: headless guide no longer says --worktree is not combinable with --fork-session"
    exit 1
  fi
  if ! grep -Fq 'Create a git worktree' "$GUIDE"; then
    echo "FAIL: headless guide no longer describes --worktree as creating a worktree"
    exit 1
  fi
fi

# Skill must not teach dead flags operationally (delegate to validate-skill)
if [[ -x "$ROOT/scripts/validate-skill.sh" ]]; then
  "$ROOT/scripts/validate-skill.sh" "$SKILL"
fi

# Documented forbidden strings should be explained as dead in skill corpus
for flag in --best-of-n --self-verify; do
  if ! grep -R -F -q -- "$flag" "$SKILL" "$REF_DIR" 2>/dev/null; then
    echo "WARN: skill corpus never mentions $flag (document as dead for migrants)"
  fi
done

# Required skill strings
for s in streaming-messages-json include-partial-messages grok-4.7 grok-4.7-build-fast grok-4.6 grok-4.5 restore-code "grok doctor" "1.0.48" "creates a git worktree"; do
  if ! grep -R -F -q -- "$s" "$SKILL" "$REF_DIR" 2>/dev/null; then
    echo "FAIL: skill corpus missing required string: $s"
    exit 1
  fi
done
retired_worktree="does not create a ""worktree"
retired_fallback='${MODEL:-grok-4.'"6}"
if grep -R -F -q -- "$retired_worktree" "$SKILL" "$REF_DIR" 2>/dev/null; then
  echo "FAIL: skill still teaches the retired headless worktree sentence"
  exit 1
fi
if grep -R -F -q -- "$retired_fallback" "$SKILL" "$REF_DIR" 2>/dev/null; then
  echo "FAIL: skill still uses the previous model fallback"
  exit 1
fi

# Models: when `grok models` succeeds, the printed default and the still-available set are required
if MODELS_OUT="$(grok models 2>&1)"; then
  if ! echo "$MODELS_OUT" | grep -Fq 'Default model: grok-4.7'; then
    echo "FAIL: grok models default is not grok-4.7"
    echo "$MODELS_OUT"
    exit 1
  fi
  echo "  models: default grok-4.7"
  for model in grok-4.7-build-fast grok-4.6 grok-4.5; do
    if ! echo "$MODELS_OUT" | grep -Fq "$model"; then
      echo "FAIL: grok models did not list $model"
      exit 1
    fi
    echo "  models: $model present"
  done
else
  echo "WARN: grok models failed (auth?); skipped model presence check"
fi

echo "✓ sync-check-cli passed against live CLI"
