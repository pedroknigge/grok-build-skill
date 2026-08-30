#!/usr/bin/env bash
# validate-skill.sh
# Contract-aware validator for the grok-build skill (v3.2 / CLI 1.0.13+).
#
# Usage: ./scripts/validate-skill.sh [path-to-SKILL.md]
set -euo pipefail

SKILL_FILE="${1:-skills/grok-build/SKILL.md}"
SKILL_DIR="$(cd -P "$(dirname "$SKILL_FILE")" 2>/dev/null && pwd)"
REF_DIR="$SKILL_DIR/references"

search_corpus() {
  local pattern="$1"
  if grep -F -q -- "$pattern" "$SKILL_FILE" 2>/dev/null; then
    return 0
  fi
  if [[ -d "$REF_DIR" ]] && grep -R -F -q -- "$pattern" "$REF_DIR" 2>/dev/null; then
    return 0
  fi
  return 1
}

if [[ ! -f "$SKILL_FILE" ]]; then
  echo "ERROR: Skill file not found: $SKILL_FILE" >&2
  exit 1
fi

echo "→ Validating $SKILL_FILE"
if [[ -d "$REF_DIR" ]]; then
  echo "  (references/ present — concepts may appear there)"
fi

# 1. Frontmatter exists
if ! head -1 "$SKILL_FILE" | grep -q '^---'; then
  echo "FAIL: Missing YAML frontmatter start (---)"
  exit 1
fi

# 2. Required frontmatter keys
for key in name: description: when-to-use: allowed-tools: user-invocable: metadata:; do
  if ! grep -q "^${key}" "$SKILL_FILE"; then
    echo "FAIL: Missing required frontmatter key: $key"
    exit 1
  fi
done

# 3. Version 3.x required
if ! grep -q 'version: "3\.' "$SKILL_FILE"; then
  echo "FAIL: expected metadata version 3.x (skill 3.x series / CLI 1.0)"
  exit 1
fi

# 4. Core sections in entrypoint
for section in \
  "When to use this skill" \
  "Native Grok capabilities" \
  "Breaking changes" \
  "Preflight" \
  "Headless usage" \
  "Quick reference"
do
  if ! grep -q "$section" "$SKILL_FILE"; then
    echo "FAIL: Missing section/heading concept: $section"
    exit 1
  fi
done

# 5. Required CLI 1.0 concepts
REQUIRED_CONCEPTS=(
  "streaming-messages-json"
  "include-partial-messages"
  "grok doctor"
  "grok-4.6"
  "grok-4.5"
  "restore-code"
  "stopReason"
  "always-approve"
  "uuidgen"
  "sessionId"
  "total_cost_usd"
  "grok login"
  "device-auth"
  "json-schema"
)

for concept in "${REQUIRED_CONCEPTS[@]}"; do
  if ! search_corpus "$concept"; then
    echo "FAIL: Required concept not mentioned: $concept"
    exit 1
  fi
done

# Entrypoint must carry the critical contract (not only references/)
for concept in "streaming-messages-json" "include-partial-messages" "grok doctor" "grok-4.6" "grok-4.5" "restore-code"; do
  if ! grep -F -q -- "$concept" "$SKILL_FILE"; then
    echo "FAIL: SKILL.md entrypoint must mention: $concept"
    exit 1
  fi
done

if ! grep -E -q 'does not create a worktree' "$SKILL_FILE"; then
  echo "FAIL: SKILL.md must document headless worktree caveat"
  exit 1
fi

# Target surface mention (1.0 family; "1.0.13+" matches CLI 1.0 / Grok Build CLI 1)
if ! grep -Eiq '1\.0\.0|CLI 1\.0|Grok Build CLI 1' "$SKILL_FILE"; then
  echo "FAIL: SKILL.md must target Grok Build CLI 1.0 family (1.0.13+)"
  exit 1
fi

# 6. FAIL operational teaching of dead flags (allow documentation of removal)
# Match recipe-style invocations: lines that run grok with dead flags and do not
# mark them as dead/error/removed/invalid.
fail_operational_dead_flags() {
  local file="$1"
  local bad
  bad="$(grep -nE 'grok[[:space:]].*(--best-of-n|--self-verify)([[:space:]|]|$)' "$file" 2>/dev/null \
    | grep -viE 'dead|error|removed|invalid|not valid|do not|don'\''t|never|unexpected|NO --|NOT valid|forbidden|anti-pattern' || true)"
  if [[ -n "$bad" ]]; then
    echo "FAIL: Operational grok invocation uses dead quality flags in $file:"
    echo "$bad"
    exit 1
  fi
  # --check is ambiguous; only flag when used as a grok CLI option in recipes
  bad="$(grep -nE 'grok[^\n]*[[:space:]]--check([[:space:]|]|$)' "$file" 2>/dev/null \
    | grep -viE 'dead|error|removed|invalid|not valid|do not|don'\''t|never|unexpected|NO --|NOT valid|forbidden|anti-pattern' || true)"
  if [[ -n "$bad" ]]; then
    echo "FAIL: Operational grok invocation uses dead --check flag in $file:"
    echo "$bad"
    exit 1
  fi
}

fail_operational_dead_flags "$SKILL_FILE"
if [[ -d "$REF_DIR" ]]; then
  while IFS= read -r -d '' f; do
    fail_operational_dead_flags "$f"
  done < <(find "$REF_DIR" -type f -name '*.md' -print0 2>/dev/null)
fi

# 7. FAIL nickname session examples
if grep -E -- '-s[[:space:]]+(img-session|feat-123|feat-xyz)\b' "$SKILL_FILE"; then
  echo "FAIL: Found non-UUID -s session nickname example (must use UUID)"
  exit 1
fi
if [[ -d "$REF_DIR" ]] && grep -R -nE -- '-s[[:space:]]+(img-session|feat-123|feat-xyz)\b' "$REF_DIR"; then
  echo "FAIL: Found non-UUID -s session nickname example in references/"
  exit 1
fi

# 8. FAIL primary fallback echo grok-build
if grep -nE 'echo[[:space:]]+grok-build\b|\|\|[[:space:]]*echo[[:space:]]+grok-build\b' "$SKILL_FILE"; then
  echo "FAIL: Primary model fallback must not be 'echo grok-build' (use grok-4.6)"
  exit 1
fi
if [[ -d "$REF_DIR" ]] && grep -R -nE 'echo[[:space:]]+grok-build\b' "$REF_DIR"; then
  echo "FAIL: references still use echo grok-build as model fallback"
  exit 1
fi

# 9. Optional references layout sanity
if [[ -d "$REF_DIR" ]]; then
  for ref in flags-1.0.md output-formats.md sessions-and-resume.md failure-modes.md quality-without-best-of-n.md prompt-templates.md; do
    if [[ ! -f "$REF_DIR/$ref" ]]; then
      echo "FAIL: Missing reference file: references/$ref"
      exit 1
    fi
  done
fi

echo "✓ Validation passed for $SKILL_FILE (skill 3.x / CLI 1.0 contract)"
echo "  (Optional: ./scripts/sync-check-cli.sh when grok is on PATH)"
