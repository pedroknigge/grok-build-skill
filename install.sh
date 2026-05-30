#!/usr/bin/env bash
# grok-build skill installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/main/install.sh | bash
# Or, from a local clone:
#   ./install.sh

set -euo pipefail

REPO_RAW="${GROK_BUILD_SKILL_RAW:-https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main}"
SKILL_PATH="skills/grok-build/SKILL.md"

cyan()  { printf "\033[36m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }

fetch_skill() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$(dirname "$0")/$SKILL_PATH" ]]; then
    cp "$(dirname "$0")/$SKILL_PATH" "$dest"
  else
    curl -fsSL "$REPO_RAW/$SKILL_PATH" -o "$dest"
  fi
}

installed_any=0

cyan "→ grok-build skill installer"

# Claude Code
if command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]; then
  target="$HOME/.claude/skills/grok-build/SKILL.md"
  fetch_skill "$target"
  green "✓ Installed for Claude Code  → $target"
  installed_any=1
fi

# Grok Build
if command -v grok >/dev/null 2>&1 || [[ -d "$HOME/.grok" ]]; then
  target="$HOME/.grok/skills/grok-build/SKILL.md"
  fetch_skill "$target"
  green "✓ Installed for Grok Build   → $target"
  installed_any=1
fi

# Codex CLI
if command -v codex >/dev/null 2>&1 || [[ -d "$HOME/.codex" ]]; then
  target="$HOME/.codex/AGENTS.md"
  mkdir -p "$(dirname "$target")"
  if [[ -f "$target" ]] && grep -q "^# Grok Build CLI" "$target" 2>/dev/null; then
    yellow "• Skipped Codex (skill already present in $target)"
  else
    {
      echo ""
      echo "<!-- BEGIN grok-build skill -->"
      if [[ -f "$(dirname "$0")/$SKILL_PATH" ]]; then
        cat "$(dirname "$0")/$SKILL_PATH"
      else
        curl -fsSL "$REPO_RAW/$SKILL_PATH"
      fi
      echo ""
      echo "<!-- END grok-build skill -->"
    } >> "$target"
    green "✓ Appended to Codex AGENTS.md → $target"
  fi
  installed_any=1
fi

if [[ "$installed_any" -eq 0 ]]; then
  yellow "No supported agent detected (claude / grok / codex)."
  yellow "Install the skill manually by copying $SKILL_PATH to your agent's skill directory."
  exit 1
fi

cyan "→ Done. Invoke with /grok-build (Claude Code, Grok) or auto-loaded in Codex."
