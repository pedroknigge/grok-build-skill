# Requirements

> Hub: [AGENTS.md](../AGENTS.md) · Architecture: [architecture.md](./architecture.md)

**Last updated:** 2026-08-30  
Inferred from **code** (installer, scripts, skill files). Evidence column is the authority.

| ID | Requirement | Evidence | Feature pack |
|----|-------------|----------|--------------|
| RF-001 | Skill metadata is 3.x with required frontmatter keys | `scripts/validate-skill.sh` | [grok-build-skill](./features/grok-build-skill/README.md) |
| RF-002 | Entrypoint contains When to use, Native Grok, Breaking changes, Preflight, Headless usage, Quick reference | `scripts/validate-skill.sh` | grok-build-skill |
| RF-003 | Entrypoint documents CLI 1.0.13+ family, `streaming-messages-json`, `--include-partial-messages`, `grok doctor`, `grok-4.6`, `grok-4.5`, `--restore-code`, worktree caveat | `scripts/validate-skill.sh` | grok-build-skill |
| RF-004 | Six references exist: `flags-1.0.md`, `output-formats.md`, `sessions-and-resume.md`, `failure-modes.md`, `quality-without-best-of-n.md`, `prompt-templates.md` | `install.sh` `REFERENCE_FILES`; `validate-skill.sh` | grok-build-skill |
| RF-005 | Operational recipes must not pass `--best-of-n`, `--self-verify`, or `grok … --check` | `validate-skill.sh` `fail_operational_dead_flags` | grok-build-skill |
| RF-006 | No nickname `-s` examples (`img-session`, `feat-123`, `feat-xyz`); create uses UUID | `validate-skill.sh` | grok-build-skill |
| RF-007 | Primary model fallback is not `echo grok-build` | `validate-skill.sh` | grok-build-skill |
| RF-008 | Installer copies full skill dir to Claude, Grok user, project-local, and both AGY global roots; embeds SKILL into Codex `AGENTS.md` | `install.sh` | [installer](./features/installer/README.md) |
| RF-009 | Project-local dest when `.git` **or** `.grok/config.toml` | `install.sh` | installer |
| RF-010 | `curl \| bash` must not treat CWD as skill root; `GROK_BUILD_SKILL_ROOT` / on-disk script only | `install.sh` `resolve_skill_root` | installer |
| RF-011 | Missing or empty shipped reference after install is a hard fail | `install.sh` `require_references` | installer |
| RF-012 | Re-install is idempotent (Codex BEGIN/END count stays 1); uninstall removes all six dest | `scripts/install-smoke.sh` | installer |
| RF-013 | Smoke test never writes the real `$HOME` | `scripts/install-smoke.sh` `FAKE_HOME` | [validation-ci](./features/validation-ci/README.md) |
| RF-014 | `SHA256SUMS` covers `install.sh`, `SKILL.md`, and the six references | `SHA256SUMS`; CI step | installer |
| RF-015 | CI runs validate, checksum verify, smoke, optional live sync | `.github/workflows/ci.yml` | validation-ci |
| RF-016 | Optional live sync exits 0 if `grok` is absent; fails if dead flags reappear in `--help` or required live flags disappear | `scripts/sync-check-cli.sh` | validation-ci |
| RF-017 | AGY installs as direct children of `~/.gemini/config/skills` and `~/.gemini/antigravity-cli/skills`; never `~/.agy/skills` | `install.sh`; `scripts/install-smoke.sh` | installer |

## NFR

| ID | Requirement | Evidence |
|----|-------------|----------|
| NFR-001 | Entrypoint stays slim (≤220 lines) | `SKILL.md` line count; [PUBLISH.md](../PUBLISH.md) |
| NFR-002 | MIT license | `LICENSE` |
| NFR-003 | Publish stages explicit paths (no `git add .`) | [PUBLISH.md](../PUBLISH.md) |

## Doc debt

None for the rows above after the 2026-08-30 audit patch. Low-priority grok subcommands are intentionally **not** RF-tracked (see architecture non-goals).
