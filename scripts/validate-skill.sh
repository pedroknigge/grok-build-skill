#!/usr/bin/env bash
# validate-skill.sh
# Basic validator for the grok-build skill.
# Checks structure, frontmatter presence, and basic sanity.
#
# Usage: ./scripts/validate-skill.sh [path-to-SKILL.md]
set -euo pipefail

SKILL_FILE="${1:-skills/grok-build/SKILL.md}"

if [[ ! -f "$SKILL_FILE" ]]; then
  echo "ERROR: Skill file not found: $SKILL_FILE" >&2
  exit 1
fi

echo "→ Validating $SKILL_FILE"

# 1. Frontmatter exists
if ! head -1 "$SKILL_FILE" | grep -q '^---'; then
  echo "FAIL: Missing YAML frontmatter start (---)"
  exit 1
fi

# 2. Required frontmatter keys (simple grep check)
for key in name: description: when-to-use: allowed-tools: user-invocable: metadata:; do
  if ! grep -q "^${key}" "$SKILL_FILE"; then
    echo "FAIL: Missing required frontmatter key: $key"
    exit 1
  fi
done

# 3. Version present and looks recent
if ! grep -q 'version: "2\.' "$SKILL_FILE"; then
  echo "WARN: version key not found or not 2.x"
fi
if ! grep -q 'version: "2\.5"' "$SKILL_FILE"; then
  echo "WARN: expected metadata version 2.5 (current skill series)"
fi

# 4. Core sections exist
for section in "When to use this skill" "Native Grok capabilities" "Prerequisites" "Headless usage" "Quick reference card" "JSON output, session IDs, usage, and cost"; do
  if ! grep -q "$section" "$SKILL_FILE"; then
    echo "FAIL: Missing section: $section"
    exit 1
  fi
done

# 5. Sanity: mentions current important concepts (use fixed strings)
# Use -- so concepts starting with - are not treated as grep flags.
for concept in json-schema allow deny "grok inspect" "grok login" "best-of-n" worktree sessionId total_cost_usd uuidgen "--always-approve"; do
  if ! grep -F -q -- "$concept" "$SKILL_FILE"; then
    echo "FAIL: Required concept not mentioned: $concept"
    exit 1
  fi
done

# 6. Guard against invalid non-UUID session nickname examples
if grep -E -- '-s[[:space:]]+(img-session|feat-123|feat-xyz)\b' "$SKILL_FILE"; then
  echo "FAIL: Found non-UUID -s session nickname example (must use UUID)"
  exit 1
fi

echo "✓ Basic validation passed for $SKILL_FILE"
echo "  (For full YAML parsing consider adding yq or a Node/Python frontmatter parser in CI.)"
