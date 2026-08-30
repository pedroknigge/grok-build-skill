#!/usr/bin/env bash
# install-smoke.sh
# Smoke test for install.sh (idempotency + uninstall).
# ALWAYS uses FAKE_HOME — never installs into the real $HOME.
#
# Usage: ./scripts/install-smoke.sh
set -euo pipefail

echo "→ Running installer smoke test..."

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

REPO_ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
INSTALL_SH="$REPO_ROOT/install.sh"

REFERENCE_FILES=(
  "flags-1.0.md"
  "output-formats.md"
  "sessions-and-resume.md"
  "failure-modes.md"
  "quality-without-best-of-n.md"
  "prompt-templates.md"
)

if [[ ! -f "$INSTALL_SH" ]]; then
  echo "ERROR: install.sh not found"
  exit 1
fi
chmod +x "$INSTALL_SH" 2>/dev/null || true

# Capture real home before override (for safety asserts only)
ORIGINAL_HOME="${HOME:-}"

# Work entirely under temp + FAKE_HOME (never real HOME)
FAKE_HOME="$TMPDIR/fakehome"
mkdir -p \
  "$FAKE_HOME/.grok" \
  "$FAKE_HOME/.claude" \
  "$FAKE_HOME/.codex" \
  "$FAKE_HOME/.gemini/config"

# Project-local install context (git repo) under TMPDIR
PROJECT="$TMPDIR/project"
mkdir -p "$PROJECT/.git"
cd "$PROJECT"

export HOME="$FAKE_HOME"
# Ensure PATH/agents detection uses fake home markers only
unset CLAUDE_CONFIG_DIR 2>/dev/null || true

# Point installer at the repo under test (not CWD, not remote)
export GROK_BUILD_SKILL_ROOT="$REPO_ROOT"

assert_full_skill_dir() {
  local dest_dir="$1"
  local label="$2"
  local ref
  if [[ ! -s "$dest_dir/SKILL.md" ]]; then
    echo "FAIL: $label missing SKILL.md at $dest_dir"
    exit 1
  fi
  if [[ ! -d "$dest_dir/references" ]]; then
    echo "FAIL: $label missing references/ at $dest_dir"
    exit 1
  fi
  for ref in "${REFERENCE_FILES[@]}"; do
    if [[ ! -s "$dest_dir/references/$ref" ]]; then
      echo "FAIL: $label missing or empty references/$ref"
      exit 1
    fi
  done
}

assert_under_tmpdir() {
  local path="$1"
  case "$path" in
    "$TMPDIR"/*) ;;
    *)
      echo "FAIL: path escapes TMPDIR: $path"
      exit 1
      ;;
  esac
}

echo "→ Installing (first run) with HOME=$FAKE_HOME GROK_BUILD_SKILL_ROOT=$REPO_ROOT"
bash "$INSTALL_SH" 2>&1 | tee "$TMPDIR/install1.log"

# Safety: all skill artifacts must live under TMPDIR / FAKE_HOME / PROJECT
assert_under_tmpdir "$FAKE_HOME"
assert_under_tmpdir "$PROJECT"
if [[ -n "$ORIGINAL_HOME" && "$HOME" == "$ORIGINAL_HOME" ]]; then
  echo "FAIL: HOME was not overridden away from original home"
  exit 1
fi
if [[ -n "$ORIGINAL_HOME" && "$FAKE_HOME" == "$ORIGINAL_HOME" ]]; then
  echo "FAIL: FAKE_HOME equals original HOME"
  exit 1
fi
# Must not write skill into original real home
if [[ -n "$ORIGINAL_HOME" ]]; then
  if [[ -f "$ORIGINAL_HOME/.grok/skills/grok-build/.smoke-should-not-exist" ]]; then
    echo "FAIL: unexpected smoke marker in real home"
    exit 1
  fi
fi

# Full reference set for every agent target
assert_full_skill_dir "$FAKE_HOME/.grok/skills/grok-build" "Grok user"
assert_full_skill_dir "$FAKE_HOME/.claude/skills/grok-build" "Claude Code"
assert_full_skill_dir "$FAKE_HOME/.gemini/config/skills/grok-build" "AGY global"
assert_full_skill_dir "$FAKE_HOME/.gemini/antigravity-cli/skills/grok-build" "AGY CLI"
assert_full_skill_dir "$PROJECT/.grok/skills/grok-build" "project-local"
if [[ -e "$FAKE_HOME/.agy" ]]; then
  echo "FAIL: installer invented unsupported $FAKE_HOME/.agy"
  exit 1
fi

if ! grep -q "BEGIN grok-build skill" "$FAKE_HOME/.codex/AGENTS.md" 2>/dev/null; then
  echo "FAIL: codex AGENTS.md block not present"
  exit 1
fi

# Codex embedded contract (mirror entrypoint must-haves)
CODEX_FILE="$FAKE_HOME/.codex/AGENTS.md"
for concept in \
  "streaming-messages-json" \
  "include-partial-messages" \
  "grok doctor" \
  "grok-4.6" \
  "grok-4.5" \
  "restore-code" \
  "does not create a worktree"
do
  if ! grep -F -q -- "$concept" "$CODEX_FILE"; then
    echo "FAIL: Codex AGENTS.md missing contract string: $concept"
    exit 1
  fi
done
if ! grep -E -q 'NOT valid:.*--best-of-n|--best-of-n.*dead|Dead flags' "$CODEX_FILE"; then
  # Also accept explicit ban lines from SKILL.md quick reference
  if ! grep -F -q -- "--best-of-n" "$CODEX_FILE"; then
    echo "FAIL: Codex AGENTS.md should document --best-of-n as forbidden/dead"
    exit 1
  fi
  # Must not look like operational recipe alone — require dead/NOT valid context somewhere
  if ! grep -Eiq 'dead|NOT valid|do not|error if used|removed' "$CODEX_FILE"; then
    echo "FAIL: Codex AGENTS.md mentions --best-of-n without dead/forbidden context"
    exit 1
  fi
fi

echo "✓ First install looks good (full refs + Codex contract)"

# Capture Codex block count
BLOCK_COUNT_1="$(grep -c "BEGIN grok-build skill" "$FAKE_HOME/.codex/AGENTS.md" || true)"
if [[ "$BLOCK_COUNT_1" -ne 1 ]]; then
  echo "FAIL: expected exactly 1 Codex BEGIN marker after first install, got $BLOCK_COUNT_1"
  exit 1
fi

# Re-run (idempotent)
echo "→ Re-running install (idempotency)"
bash "$INSTALL_SH" 2>&1 | tee "$TMPDIR/install2.log"

BLOCK_COUNT_2="$(grep -c "BEGIN grok-build skill" "$FAKE_HOME/.codex/AGENTS.md" || true)"
if [[ "$BLOCK_COUNT_2" -ne 1 ]]; then
  echo "FAIL: Codex block duplicated on reinstall (BEGIN count=$BLOCK_COUNT_2)"
  exit 1
fi
END_COUNT_2="$(grep -c "END grok-build skill" "$FAKE_HOME/.codex/AGENTS.md" || true)"
if [[ "$END_COUNT_2" -ne 1 ]]; then
  echo "FAIL: Codex END marker count=$END_COUNT_2 (expected 1)"
  exit 1
fi

# Refs still complete after reinstall
assert_full_skill_dir "$FAKE_HOME/.grok/skills/grok-build" "Grok user (reinstall)"
assert_full_skill_dir "$FAKE_HOME/.claude/skills/grok-build" "Claude Code (reinstall)"
assert_full_skill_dir "$FAKE_HOME/.gemini/config/skills/grok-build" "AGY global (reinstall)"
assert_full_skill_dir "$FAKE_HOME/.gemini/antigravity-cli/skills/grok-build" "AGY CLI (reinstall)"
assert_full_skill_dir "$PROJECT/.grok/skills/grok-build" "project-local (reinstall)"

echo "✓ Idempotent re-run succeeded (Codex block not duplicated)"

# Uninstall
echo "→ Uninstalling"
bash "$INSTALL_SH" --uninstall 2>&1 | tee "$TMPDIR/uninstall.log"

if [[ -f "$FAKE_HOME/.grok/skills/grok-build/SKILL.md" ]] || [[ -d "$FAKE_HOME/.grok/skills/grok-build" ]]; then
  echo "FAIL: grok skill still present after uninstall"
  exit 1
fi
if [[ -f "$FAKE_HOME/.claude/skills/grok-build/SKILL.md" ]] || [[ -d "$FAKE_HOME/.claude/skills/grok-build" ]]; then
  echo "FAIL: claude skill still present after uninstall"
  exit 1
fi
if [[ -d "$FAKE_HOME/.gemini/config/skills/grok-build" ]]; then
  echo "FAIL: AGY global skill still present after uninstall"
  exit 1
fi
if [[ -d "$FAKE_HOME/.gemini/antigravity-cli/skills/grok-build" ]]; then
  echo "FAIL: AGY CLI skill still present after uninstall"
  exit 1
fi
if [[ -f "$PROJECT/.grok/skills/grok-build/SKILL.md" ]] || [[ -d "$PROJECT/.grok/skills/grok-build" ]]; then
  echo "FAIL: project skill still present after uninstall"
  exit 1
fi
if [[ -e "$FAKE_HOME/.agy" ]]; then
  echo "FAIL: uninstall left unsupported $FAKE_HOME/.agy"
  exit 1
fi
if grep -q "BEGIN grok-build skill" "$FAKE_HOME/.codex/AGENTS.md" 2>/dev/null; then
  echo "FAIL: Codex block still present after uninstall"
  exit 1
fi

# Second uninstall should report nothing to remove (Codex false-positive guard)
echo "→ Second uninstall (should be no-op for Codex)"
out="$(bash "$INSTALL_SH" --uninstall 2>&1 || true)"
if echo "$out" | grep -q "Removed from Codex"; then
  echo "FAIL: second uninstall falsely reported Codex removal"
  echo "$out"
  exit 1
fi
if ! echo "$out" | grep -q "Nothing to remove"; then
  echo "FAIL: expected 'Nothing to remove' on second uninstall"
  echo "$out"
  exit 1
fi

echo "✓ Uninstall cleaned all targets"

echo ""
echo "✅ All smoke tests passed"
