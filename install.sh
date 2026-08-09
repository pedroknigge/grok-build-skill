#!/usr/bin/env bash
# grok-build skill installer — v3.0 (idempotent)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash
# Or, from a local clone (recommended for development):
#   ./install.sh
#
# Local tree override (optional):
#   GROK_BUILD_SKILL_ROOT=/path/to/clone ./install.sh
#   GROK_BUILD_SKILL_RAW=https://raw.githubusercontent.com/.../main ./install.sh  # remote base
#
# Re-running this script is safe: Claude Code & Grok skill directories are overwritten,
# and the Codex AGENTS.md block is replaced in place (no duplication).
#
# Installs the full skills/grok-build/ directory (SKILL.md + references/).
# Install fails hard if any shipped reference file is missing.
#
# This installer assumes `grok` is already installed and the user has run `grok login`
# (or device-auth). It only installs the skill definition.
#
# Flags:
#   --uninstall   Remove the skill from every detected agent.

set -euo pipefail

REPO_RAW="${GROK_BUILD_SKILL_RAW:-https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main}"
SKILL_REL="skills/grok-build"
SKILL_MD="${SKILL_REL}/SKILL.md"
BEGIN_MARKER="<!-- BEGIN grok-build skill -->"
END_MARKER="<!-- END grok-build skill -->"

# Reference files shipped with the skill (keep in sync with repo tree).
REFERENCE_FILES=(
  "flags-1.0.md"
  "output-formats.md"
  "sessions-and-resume.md"
  "failure-modes.md"
  "quality-without-best-of-n.md"
  "prompt-templates.md"
)

UNINSTALL=0
if [[ "${1:-}" == "--uninstall" ]]; then
  UNINSTALL=1
fi

cyan()  { printf "\033[36m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }

# Resolve a trusted local skill root only when the invoking script is a real on-disk
# path that contains SKILL.md (or GROK_BUILD_SKILL_ROOT is set).
# curl|bash often sets $0 to "bash", so dirname would become CWD — do NOT treat that
# as a local tree (would pick up a random CWD skills/ tree over REPO_RAW).
resolve_skill_root() {
  if [[ -n "${GROK_BUILD_SKILL_ROOT:-}" ]]; then
    local root
    root="$(cd -P "$GROK_BUILD_SKILL_ROOT" 2>/dev/null && pwd || true)"
    if [[ -n "$root" && -f "$root/$SKILL_MD" ]]; then
      echo "$root"
      return 0
    fi
    red "ERROR: GROK_BUILD_SKILL_ROOT=$GROK_BUILD_SKILL_ROOT does not contain $SKILL_MD" >&2
    exit 1
  fi

  local src="${BASH_SOURCE[0]:-}"
  # Piped/stdin or non-file invocation → remote only
  if [[ -z "$src" || "$src" == "bash" || "$src" == "-bash" || "$src" == "sh" || "$src" == "-"* ]]; then
    return 1
  fi
  if [[ ! -f "$src" ]]; then
    return 1
  fi

  local dir
  dir="$(cd -P "$(dirname "$src")" 2>/dev/null && pwd || true)"
  if [[ -n "$dir" && -f "$dir/$SKILL_MD" ]]; then
    echo "$dir"
    return 0
  fi
  return 1
}

SKILL_ROOT=""
if SKILL_ROOT="$(resolve_skill_root)"; then
  :
else
  SKILL_ROOT=""
fi

require_references() {
  local dest_dir="$1"
  local ref missing=0
  for ref in "${REFERENCE_FILES[@]}"; do
    if [[ ! -s "$dest_dir/references/$ref" ]]; then
      red "ERROR: missing or empty reference after install: $dest_dir/references/$ref" >&2
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    red "ERROR: full references/ set is required (SKILL.md + all shipped references)." >&2
    exit 1
  fi
  if [[ ! -s "$dest_dir/SKILL.md" ]]; then
    red "ERROR: missing or empty $dest_dir/SKILL.md" >&2
    exit 1
  fi
}

# Install full skill directory (SKILL.md + references/) into $1
install_skill_dir() {
  local dest_dir="$1"
  mkdir -p "$dest_dir/references"

  if [[ -n "$SKILL_ROOT" && -f "$SKILL_ROOT/$SKILL_MD" ]]; then
    cp "$SKILL_ROOT/$SKILL_MD" "$dest_dir/SKILL.md"
    local ref
    for ref in "${REFERENCE_FILES[@]}"; do
      if [[ ! -f "$SKILL_ROOT/$SKILL_REL/references/$ref" ]]; then
        red "ERROR: local tree missing $SKILL_ROOT/$SKILL_REL/references/$ref" >&2
        exit 1
      fi
      cp "$SKILL_ROOT/$SKILL_REL/references/$ref" "$dest_dir/references/$ref"
    done
  else
    curl -fsSL "$REPO_RAW/$SKILL_MD" -o "$dest_dir/SKILL.md"
    local ref
    for ref in "${REFERENCE_FILES[@]}"; do
      # Hard-fail if any reference download fails (no || true)
      curl -fsSL "$REPO_RAW/$SKILL_REL/references/$ref" -o "$dest_dir/references/$ref"
    done
  fi

  require_references "$dest_dir"
}

remove_skill_dir() {
  local dest_dir="$1"
  if [[ -d "$dest_dir" ]]; then
    rm -rf "$dest_dir"
    return 0
  fi
  return 1
}

fetch_skill_stdout() {
  if [[ -n "$SKILL_ROOT" && -f "$SKILL_ROOT/$SKILL_MD" ]]; then
    cat "$SKILL_ROOT/$SKILL_MD"
    echo ""
    echo "<!-- references: install full skills/grok-build/ (including references/) for offline detail tables -->"
    echo "<!-- Available next to SKILL.md after directory install: references/*.md -->"
  else
    curl -fsSL "$REPO_RAW/$SKILL_MD"
    echo ""
    echo "<!-- references: see repo skills/grok-build/references/ for flags, sessions, formats, quality patterns -->"
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
  cyan "→ grok-build skill installer (v3.0 / Grok Build CLI 1.0 — idempotent)"
  if [[ -n "$SKILL_ROOT" ]]; then
    cyan "  source: local tree $SKILL_ROOT"
  else
    cyan "  source: remote $REPO_RAW"
  fi
fi

# ─── Claude Code ──────────────────────────────────────────────────────────────
if command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]; then
  target_dir="$HOME/.claude/skills/grok-build"
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if remove_skill_dir "$target_dir"; then
      green "✓ Removed from Claude Code  → $target_dir"
      removed_any=1
    fi
  else
    install_skill_dir "$target_dir"
    green "✓ Installed for Claude Code  → $target_dir/SKILL.md (+ references/)"
    installed_any=1
  fi
fi

# ─── Grok Build (user) ────────────────────────────────────────────────────────
if command -v grok >/dev/null 2>&1 || [[ -d "$HOME/.grok" ]]; then
  target_dir="$HOME/.grok/skills/grok-build"
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if remove_skill_dir "$target_dir"; then
      green "✓ Removed from Grok Build (user) → $target_dir"
      removed_any=1
    fi
  else
    install_skill_dir "$target_dir"
    green "✓ Installed for Grok Build (user) → $target_dir/SKILL.md (+ references/)"
    installed_any=1
  fi
fi

# ─── Grok Build (project-local, if inside a git repo with .grok) ──────────────
if [[ -d ".git" || -f ".grok/config.toml" ]]; then
  proj_dir=".grok/skills/grok-build"
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if remove_skill_dir "$proj_dir"; then
      green "✓ Removed from project .grok/skills → $proj_dir"
      removed_any=1
    fi
  else
    install_skill_dir "$proj_dir"
    green "✓ Installed for this project (local) → $proj_dir/SKILL.md (+ references/)"
    installed_any=1
  fi
fi

# ─── Codex CLI ────────────────────────────────────────────────────────────────
if command -v codex >/dev/null 2>&1 || [[ -d "$HOME/.codex" ]]; then
  target="$HOME/.codex/AGENTS.md"
  mkdir -p "$(dirname "$target")"
  touch "$target"

  had_codex_block=0
  if grep -F -qx "$BEGIN_MARKER" "$target" 2>/dev/null; then
    had_codex_block=1
  fi

  # Always strip any existing block first → makes the operation idempotent.
  strip_block "$target"

  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ "$had_codex_block" -eq 1 ]]; then
      green "✓ Removed from Codex AGENTS.md → $target"
      removed_any=1
    fi
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
  yellow "Install the skill manually by copying $SKILL_REL/ to your agent's skill directory."
  exit 1
fi

cyan "→ Done. Invoke with /grok-build (Claude Code, Grok) or auto-loaded in Codex."
cyan "  Skill 3.0 targets Grok Build CLI 1.0.0+ (dead flags removed; default model grok-4.5)."
cyan "  Tip: re-run this script (or ./install.sh from a clone) anytime to update."
cyan "  For project-local skills: the installer also writes to .grok/skills/ when run inside a git repo."
cyan "  To remove: ./install.sh --uninstall"
