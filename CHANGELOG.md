# Changelog

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
