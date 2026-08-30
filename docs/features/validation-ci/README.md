# Feature: Validation and CI

> Hub: [AGENTS.md](../../../AGENTS.md)  
> Related: [Architecture](../../architecture.md) · [Requirements](../../requirements.md)

**Status:** Real  
**Slug:** `validation-ci`  
**Last updated:** 2026-08-30

## Purpose

Fail the tree when the skill teaches a dead CLI contract, the installer regresses, or published checksums drift.

## Canonical authority

| Topic | Authority | This pack's role |
|-------|-----------|------------------|
| Contract | [`scripts/validate-skill.sh`](../../../scripts/validate-skill.sh) | Entry |
| Installer smoke | [`scripts/install-smoke.sh`](../../../scripts/install-smoke.sh) | Entry |
| Live CLI | [`scripts/sync-check-cli.sh`](../../../scripts/sync-check-cli.sh) | Entry |
| CI wiring | [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) | Link |

## Users & success

- **Primary users:** Maintainers and GitHub Actions
- **Success metrics:** All three scripts exit 0 on this tree; CI job `validate-and-smoke`
- **Out of scope:** `audit-claims.sh` / docs-audit workflow (not in this repo)

## Acceptance criteria

- [x] Validate requires version 3.x, required concepts, six refs, dead-flag ban, UUID sessions
- [x] Smoke uses `FAKE_HOME` + `GROK_BUILD_SKILL_ROOT`; never original `$HOME`
- [x] Smoke asserts full refs on Claude/Grok/project and Codex contract strings
- [x] `sync-check-cli.sh` skips (exit 0) when `grok` is missing
- [x] CI: validate, `shasum -a 256 -c SHA256SUMS`, smoke, optional sync

## Public surface

| Kind | Surface | Notes |
|------|---------|-------|
| CLI | `./scripts/validate-skill.sh [path-to-SKILL.md]` | Default in-tree SKILL |
| CLI | `./scripts/install-smoke.sh` | Temp dir |
| CLI | `./scripts/sync-check-cli.sh` | Optional |
| CI | `.github/workflows/ci.yml` | push + pull_request |

## How it works

CI is a linear job on `ubuntu-latest`. Live `grok` is not required on Actions; sync-check is a no-op skip there unless the runner has `grok`.

## Edge cases & risks

- `--check` in `grok update --check` is live; the validator only fails `grok … --check` recipe lines without dead/forbidden context.
- Model presence (`grok-4.6` / `grok-4.5`) in `grok models` is WARN-only in sync-check (environment-specific).

## Related docs

- Skill: [../grok-build-skill/README.md](../grok-build-skill/README.md)
- Installer: [../installer/README.md](../installer/README.md)
