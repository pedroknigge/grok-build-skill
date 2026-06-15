# Changelog

## v2.1 — 2026-06-15

### Major content updates (SKILL.md + README)
- **Prominent "Native Grok vs CLI Delegation" guidance** added early in the skill. Clearly explains when to prefer direct tools (`image_gen`, `image_to_video`, `spawn_subagent`, `todo_write`, `enter_plan_mode`/`exit_plan_mode`, `search_tool` + `use_tool` for MCPs, background+monitor, etc.) versus delegating via the `grok` CLI binary.
- Prerequisites dramatically simplified per usage: the skill now **assumes `grok` is installed and `grok login` has been performed**. Only a clear warning remains about cached-token-only mode (no `XAI_API_KEY` support).
- Updated headless flags table with current options: `--yolo`, `--permission-mode`, `--tools`/`--disallowed-tools`, `--effort`, `--max-turns`.
- New dedicated sections:
  - MCP Servers (mandatory `search_tool` first → `use_tool` pattern).
  - Subagents, Plan Mode, Background Tasks & Todo Tracking (orchestration primitives).
- Refreshed slash commands, output formats, ACP, Skills/plugins/hooks (with modern discovery and frontmatter notes), and Failure modes (aligned with current permissions model, fast paths, and MCP gotchas).
- Expanded Quick reference card now shows both CLI delegation examples **and** native Grok tool patterns side-by-side.
- Richer `SKILL.md` frontmatter (`when-to-use`, `allowed-tools`, `argument-hint`, `metadata.version`, etc.).
- README tables, intro, "What the skill teaches", prerequisites, contributing, and sources all updated to reflect native + delegation reality and local user-guide docs.

### Installer (`install.sh`)
- Added support for **project-local** installation into `.grok/skills/grok-build/SKILL.md` when run inside a git repository (in addition to user `~/.grok/skills/`).
- Simplified messaging (assumes grok + login already done).
- Version comments and final tips updated. Still fully idempotent + `--uninstall` support.

### Other
- CHANGELOG, README, and sources now reference both official x.ai docs and the local `~/.grok/docs/user-guide/` files (skills, MCPs, subagents, plan-mode, headless, permissions, background tasks).
- Minor hygiene and accuracy improvements while preserving the project's minimal, high-signal character.

## v2.0.0 — 2026-05-30

### Installer
- **Idempotent re-runs.** Running `install.sh` again now safely updates instead of duplicating. Claude Code & Grok files are overwritten; the Codex `AGENTS.md` block is replaced in place using `BEGIN / END grok-build skill` markers.
- **New: `--uninstall` flag.** Removes the skill from every detected agent and restores the original `AGENTS.md` for Codex (content outside the markers is preserved).
- Friendlier output: per-agent status lines, a tip footer, and a clean uninstall summary.

### Skill (`SKILL.md`)
- **Auth flow clarified.** The skill now assumes the user has run `grok login` (cached token) and explicitly states that `XAI_API_KEY` is not used.
- ACP example updated to authenticate with `cached_token`.
- Failure-mode table updated to point at `grok login` instead of API-key env vars.

### README
- Documented idempotency and the `--uninstall` path.
- Prerequisites rewritten around `grok login`.

## v1.0.0 — 2026-05-30

Initial release.

- `SKILL.md` covering headless `grok` usage, slash commands (`/imagine`, `/imagine-video`), output formats, ACP, custom models, and failure modes.
- One-shot installer detecting Claude Code, Grok Build, and Codex.
- MIT license.
