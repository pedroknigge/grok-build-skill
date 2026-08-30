# ADR-0003: Native AGY global skill destinations

**Status:** Accepted
**Date:** 2026-08-30
**Tags:** architecture, distribution, agy

## Context / Problem

Antigravity (`agy`) discovers global Agent Skills from the Gemini configuration tree. Several AGY CLI builds also require a compatibility copy in their product-specific tree. The former four-destination installer did not install grok-build into either location.

## Decision

When `agy` is on PATH or the corresponding Gemini config root exists, `install.sh` copies the complete `skills/grok-build/` directory into these direct children:

1. `$HOME/.gemini/config/skills/grok-build/` — canonical global discovery
2. `$HOME/.gemini/antigravity-cli/skills/grok-build/` — AGY CLI compatibility mirror

Reinstall overwrites both idempotently. `--uninstall` removes both exact skill directories. The installer never creates `$HOME/.agy/skills`.

The existing four destinations remain unchanged, so the installer now has six destinations in total. AGY exposes the skill through `/grok-build` and semantic discovery.

## Consequences

**Positive:** AGY receives the same `SKILL.md` and six references as other directory-based hosts.
**Negative / Risks:** Two copies must remain byte-identical; the smoke test validates both.
**Neutral:** Workspace-local AGY discovery through `.agents/skills/` is outside this global installer change.

## Links

- Superseded decision: [ADR-0002](./0002-four-installer-destinations.md)
- Architecture: [../architecture.md](../architecture.md)
- Feature: [../features/installer/README.md](../features/installer/README.md)
- Publish: [../../PUBLISH.md](../../PUBLISH.md)
