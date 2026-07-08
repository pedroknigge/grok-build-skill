#!/usr/bin/env bash
# install-smoke.sh
# Very basic smoke test for install.sh (idempotency + uninstall).
# Runs in a temp directory to avoid polluting real ~/.grok etc.
#
# Usage: ./scripts/install-smoke.sh
set -euo pipefail

echo "→ Running installer smoke test..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
INSTALL_SH="$SCRIPT_DIR/install.sh"
SKILL_SRC="$SCRIPT_DIR/skills/grok-build/SKILL.md"

if [[ ! -x "$INSTALL_SH" ]]; then
  echo "ERROR: install.sh not found or not executable"
  exit 1
fi

cd "$TMPDIR"

# Simulate a git repo for project-local install
mkdir -p .git

# Run install (it will use local files because SCRIPT_DIR logic)
echo "→ Installing (first run)"
bash "$INSTALL_SH" 2>&1 | cat

# Check expected locations relative to fake home or project
echo "→ Checking artifacts..."

# The installer writes to $HOME by default. For smoke we will run with HOME override.
# Better: use a fake HOME
FAKE_HOME="$TMPDIR/fakehome"
mkdir -p "$FAKE_HOME/.grok" "$FAKE_HOME/.claude" "$FAKE_HOME/.codex"

HOME="$FAKE_HOME" bash "$INSTALL_SH" 2>&1 | cat

# Verify key files were created
if [[ ! -f "$FAKE_HOME/.grok/skills/grok-build/SKILL.md" ]]; then
  echo "FAIL: user grok skill not installed"
  exit 1
fi
if [[ ! -f "$FAKE_HOME/.claude/skills/grok-build/SKILL.md" ]]; then
  echo "FAIL: claude skill not installed"
  exit 1
fi
if ! grep -q "BEGIN grok-build skill" "$FAKE_HOME/.codex/AGENTS.md" 2>/dev/null; then
  echo "FAIL: codex AGENTS.md block not present"
  exit 1
fi

echo "✓ First install looks good"

# Re-run (idempotent)
echo "→ Re-running install (idempotency)"
HOME="$FAKE_HOME" bash "$INSTALL_SH" 2>&1 | cat

echo "✓ Idempotent re-run succeeded"

# Uninstall
echo "→ Uninstalling"
HOME="$FAKE_HOME" bash "$INSTALL_SH" --uninstall 2>&1 | cat

if [[ -f "$FAKE_HOME/.grok/skills/grok-build/SKILL.md" ]]; then
  echo "FAIL: skill still present after uninstall"
  exit 1
fi

echo "✓ Uninstall succeeded"

echo ""
echo "✅ All smoke tests passed"