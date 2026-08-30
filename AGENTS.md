# AGENTS.md — grok-build skill

> Hub for this repository. Read this file and the linked docs before significant work. Update them when install destinations, the skill contract, or CLI targeting change.  
> **Code is the source of truth** for how the installer, validators, and skill files behave. These documents capture *what* and *why*. On conflict, **code wins** — fix or flag the doc.

**Status:** Shipped (skill **3.2** / Grok Build CLI **1.0.13+**, default model **`grok-4.6`**)
**Last updated:** 2026-08-30

## Project Overview

Drop-in Agent Skill that teaches host agents (Claude Code, Grok Build, Antigravity/AGY, Codex, and any `SKILL.md` host) how to drive the **xAI Grok Build CLI** in **headless** mode (`grok -p`), including `/imagine`, sessions, streaming JSON, and when to prefer **native host tools** instead of shelling out.

This repo is **not** an application. Runtime is POSIX bash + Markdown. There is no `package.json` / `pyproject.toml` / `go.mod`.

## Key Links

- Product vision: [docs/product-vision.md](./docs/product-vision.md)
- Requirements: [docs/requirements.md](./docs/requirements.md)
- Architecture: [docs/architecture.md](./docs/architecture.md)
- Decisions: [docs/decisions/](./docs/decisions/)
- Roadmap: [docs/roadmap.md](./docs/roadmap.md)
- Claims matrix (living claims v0): [docs/audit/claims-matrix.md](./docs/audit/claims-matrix.md)
- Consumer README: [README.md](./README.md)
- Publish recipe: [PUBLISH.md](./PUBLISH.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

Canonical **product** surface (what hosts load): [`skills/grok-build/SKILL.md`](./skills/grok-build/SKILL.md) + [`skills/grok-build/references/`](./skills/grok-build/references/).

## Features

| Feature | Doc | Status |
|---------|-----|--------|
| grok-build skill | [docs/features/grok-build-skill/README.md](./docs/features/grok-build-skill/README.md) | Real |
| Installer | [docs/features/installer/README.md](./docs/features/installer/README.md) | Real |
| Validation & CI | [docs/features/validation-ci/README.md](./docs/features/validation-ci/README.md) | Real |

## Surface coverage

| Surface / ModuleId | Canonical doc | Feature pack | Status | Gap |
|--------------------|---------------|--------------|--------|-----|
| `skills/grok-build/SKILL.md` | [SKILL.md](./skills/grok-build/SKILL.md) | [grok-build-skill](./docs/features/grok-build-skill/README.md) | Real | |
| `skills/grok-build/references/*` | [flags-1.0.md](./skills/grok-build/references/flags-1.0.md) (tables) | [grok-build-skill](./docs/features/grok-build-skill/README.md) | Real | |
| `install.sh` | [README.md](./README.md) · [PUBLISH.md](./PUBLISH.md) | [installer](./docs/features/installer/README.md) | Real | |
| `scripts/validate-skill.sh` | [validation-ci](./docs/features/validation-ci/README.md) | [validation-ci](./docs/features/validation-ci/README.md) | Real | |
| `scripts/install-smoke.sh` | [validation-ci](./docs/features/validation-ci/README.md) | [validation-ci](./docs/features/validation-ci/README.md) | Real | |
| `scripts/sync-check-cli.sh` | [validation-ci](./docs/features/validation-ci/README.md) | [validation-ci](./docs/features/validation-ci/README.md) | Real | |
| `.github/workflows/ci.yml` | [validation-ci](./docs/features/validation-ci/README.md) | [validation-ci](./docs/features/validation-ci/README.md) | Real | |
| `SHA256SUMS` | [PUBLISH.md](./PUBLISH.md) | [installer](./docs/features/installer/README.md) | Real | |
| `~/.gemini/config/skills/grok-build` | [README.md](./README.md) · [PUBLISH.md](./PUBLISH.md) | [installer](./docs/features/installer/README.md) | Real | |
| `~/.gemini/antigravity-cli/skills/grok-build` | [README.md](./README.md) · [PUBLISH.md](./PUBLISH.md) | [installer](./docs/features/installer/README.md) | Real | |
| `~/.codex/skills/grok-build` | [PUBLISH.md](./PUBLISH.md) | [installer](./docs/features/installer/README.md) | Deprecated | **not an installer dest** |

## Instructions for AI Agents & Contributors

- Consult this hub and `docs/` at the start of significant work.
- **Do not invent CLI flags, models, or installer destinations.** Evidence: live `grok --help` / completions, `install.sh`, and the six reference files.
- Keep `SKILL.md` slim (≤220 lines). Flag tables live in `references/flags-1.0.md`.
- Do **not** teach `--best-of-n`, `--check`, or `--self-verify` as live `-p` flags (`--check` is only `grok update --check`).
- Model fallback string is **`grok-4.6`**. Keep a **`grok-4.5`** mention. Never `echo grok-build`.
- After changing hashed files (`install.sh`, `SKILL.md`, `references/*`), regenerate `SHA256SUMS`.
- After work that changes architecture, destinations, or the skill contract, update this hub, coverage rows, and the claims matrix.
- Prefer ADRs for locked trade-offs. Do not delete durable decisions; mark Superseded.
- Do not auto-commit or `git add .` (`.orderfield/` and `.grok/` are gitignored).

## Current Status Summary

Skill **3.2** is aligned with live **Grok Build CLI 1.0.13** and adds native AGY discovery through both global Gemini skill roots. Headless quality flags from skill 2.5 remain dead. Installer has **six** destinations.

_Last updated: 2026-08-30 for native AGY packaging_
