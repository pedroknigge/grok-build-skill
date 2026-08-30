# ADR-0001: Slim SKILL.md entrypoint plus six references

**Status:** Accepted — inferred from code  
**Date:** 2026-08-30  
**Tags:** architecture, skill-layout

## Context / Problem

A single giant `SKILL.md` either overflows host context or omits the CLI 1.0 flag tables agents need. Skill 3.0/3.1 split the contract: a short entrypoint plus named overflow files the installer always copies.

## Alternatives Considered

1. **One SKILL.md** — simple install, but fails the ≤220-line / progressive-disclosure bar.
2. **Arbitrary many references** — installer `REFERENCE_FILES` and validators would drift.
3. **Slim entrypoint + exactly six named files** — chosen.

## Decision

Ship `skills/grok-build/SKILL.md` (≤220 lines) and these six references only:

- `flags-1.0.md`
- `output-formats.md`
- `sessions-and-resume.md`
- `failure-modes.md`
- `quality-without-best-of-n.md`
- `prompt-templates.md`

`install.sh` hard-fails if any file is missing or empty after copy/fetch. Do not add a seventh file unless `flags-1.0.md` overflows and `REFERENCE_FILES` is updated in the same change.

## Consequences

**Positive:** Hosts get the critical contract without loading every table; Codex embed is the entrypoint plus a references note.  
**Negative / Risks:** Agents that only receive the Codex `AGENTS.md` block miss the overflow tables unless they clone the repo or a directory install.  
**Neutral:** Line-count is a quality bar, not a product metric.

## Links

- Architecture: [../architecture.md](../architecture.md)
- Feature: [../features/grok-build-skill/README.md](../features/grok-build-skill/README.md)
- Installer list: `install.sh` `REFERENCE_FILES`
