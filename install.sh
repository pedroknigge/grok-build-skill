#!/usr/bin/env bash
# grok-build skill installer — v2.4 (idempotent)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash
# Or, from a local clone (recommended for development):
#   ./install.sh
#
# Re-running this script is safe: Claude Code & Grok files are overwritten,
# and the Codex AGENTS.md block is replaced in place (no duplication).
#
# This installer assumes `grok` is already installed and the user has run `grok login`.
# It only installs the skill definition.
#
# Flags:
#   --uninstall   Remove the skill from every detected agent.

set -euo pipefail

REPO_RAW="${GROK_BUILD_SKILL_RAW:-https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main}"
SKILL_PATH="skills/grok-build/SKILL.md"
BEGIN_MARKER="<!-- BEGIN grok-build skill -->"
END_MARKER="<!-- END grok-build skill -->"

UNINSTALL=0
if [[ "${1:-}" == "--uninstall" ]]; then
  UNINSTALL=1
fi

cyan()  { printf "\033[36m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

fetch_skill_to() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$SKILL_PATH" ]]; then
    cp "$SCRIPT_DIR/$SKILL_PATH" "$dest"
  else
    curl -fsSL "$REPO_RAW/$SKILL_PATH" -o "$dest"
  fi
}

fetch_skill_stdout() {
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$SKILL_PATH" ]]; then
    cat "$SCRIPT_DIR/$SKILL_PATH"
  else
    curl -fsSL "$REPO_RAW/$SKILL_PATH"
  fi
}

# Remove the marked block from $1 if present (idempotent, portable awk).
strip_block() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  awk -v b="$BEGIN_MARKER" -v e="$END_MARKER" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
  ' "$file" > "$tmp"
  # Trim trailing blank lines.
  awk 'NF {p=1} p {print}' "$tmp" | awk '
    { lines[NR] = $0 }
    END {
      n = NR
      while (n > 0 && lines[n] ~ /^[[:space:]]*$/) { n-- }
      for (i = 1; i <= n; i++) print lines[i]
    }
  ' > "$file"
  rm -f "$tmp"
}

installed_any=0
removed_any=0

if [[ "$UNINSTALL" -eq 1 ]]; then
  cyan "→ grok-build skill uninstaller"
else
  cyan "→ grok-build skill installer (v2.4 — idempotent)"
fi

# ─── Claude Code ──────────────────────────────────────────────────────────────
if command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]; then
  target="$HOME/.claude/skills/grok-build/SKILL.md"
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -f "$target" ]]; then
      rm -f "$target"
      rmdir "$(dirname "$target")" 2>/dev/null || true
      green "✓ Removed from Claude Code  → $target"
      removed_any=1
    fi
  else
    fetch_skill_to "$target"
    green "✓ Installed for Claude Code  → $target"
    installed_any=1
  fi
fi

# ─── Grok Build (user) ────────────────────────────────────────────────────────
if command -v grok >/dev/null 2>&1 || [[ -d "$HOME/.grok" ]]; then
  target="$HOME/.grok/skills/grok-build/SKILL.md"
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -f "$target" ]]; then
      rm -f "$target"
      rmdir "$(dirname "$target")" 2>/dev/null || true
      green "✓ Removed from Grok Build (user) → $target"
      removed_any=1
    fi
  else
    fetch_skill_to "$target"
    green "✓ Installed for Grok Build (user) → $target"
    installed_any=1
  fi
fi

# ─── Grok Build (project-local, if inside a git repo with .grok) ──────────────
if [[ -d ".git" || -f ".grok/config.toml" ]]; then
  proj_target=".grok/skills/grok-build/SKILL.md"
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -f "$proj_target" ]]; then
      rm -f "$proj_target"
      rmdir "$(dirname "$proj_target")" 2>/dev/null || true
      green "✓ Removed from project .grok/skills → $proj_target"
      removed_any=1
    fi
  else
    mkdir -p "$(dirname "$proj_target")"
    if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$SKILL_PATH" ]]; then
      cp "$SCRIPT_DIR/$SKILL_PATH" "$proj_target"
    else
      curl -fsSL "$REPO_RAW/$SKILL_PATH" -o "$proj_target"
    fi
    green "✓ Installed for this project (local) → $proj_target"
    installed_any=1
  fi
fi

# ─── Codex CLI ────────────────────────────────────────────────────────────────
if command -v codex >/dev/null 2>&1 || [[ -d "$HOME/.codex" ]]; then
  target="$HOME/.codex/AGENTS.md"
  mkdir -p "$(dirname "$target")"
  touch "$target"

  # Always strip any existing block first → makes the operation idempotent.
  strip_block "$target"

  if [[ "$UNINSTALL" -eq 1 ]]; then
    green "✓ Removed from Codex AGENTS.md → $target"
    removed_any=1
  else
    {
      [[ -s "$target" ]] && echo ""
      echo "$BEGIN_MARKER"
      fetch_skill_stdout
      echo ""
      echo "$END_MARKER"
    } >> "$target"
    green "✓ Updated Codex AGENTS.md   → $target"
    installed_any=1
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
if [[ "$UNINSTALL" -eq 1 ]]; then
  if [[ "$removed_any" -eq 0 ]]; then
    yellow "Nothing to remove — no install found."
    exit 0
  fi
  cyan "→ Done. The grok-build skill has been removed."
  exit 0
fi

if [[ "$installed_any" -eq 0 ]]; then
  yellow "No supported agent detected (claude / grok / codex)."
  yellow "Install the skill manually by copying $SKILL_PATH to your agent's skill directory."
  exit 1
fi

cyan "→ Done. Invoke with /grok-build (Claude Code, Grok) or auto-loaded in Codex."
cyan "  Tip: re-run this script (or ./install.sh from a clone) anytime to update."
cyan "  For project-local skills: the installer also writes to .grok/skills/ when run inside a git repo."
cyan "  To remove: ./install.sh --uninstall"
