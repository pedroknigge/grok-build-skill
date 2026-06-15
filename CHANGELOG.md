# Changelog

## v2.3 — 2026-06-15

### Noise, hook spam, and long-running delegation robustness (second round of real Codex feedback)
- Added a full new subsection **"Reducing environment noise, hook spam, and extracting only the final report"** right after the main recommended pattern.
- Documented the exact problem reported: even with `--output-format json`, the delegated `grok` process emits large volumes of hook traces ("hooks fallidos del entorno Grok"), plugin/MCP warnings, permission banners, and environment diagnostics. These accumulate over minutes on broad tasks (e.g. full-project error audits), making the caller think the process is stuck or hanging.
- Practical, copy-pasteable mitigations that directly address the trace:
  - `2>/dev/null` (most spam is on stderr)
  - `| jq -s 'last'` to reliably extract only the final report object even if the stream is chatty
  - Streaming-json + `jq` filter + `tail -1` for very long runs
  - Extremely strict instructions *inside the prompt* the delegated grok receives ("emit NOTHING except the exact final structured report at the very end")
  - Aggressive `--tools` allowlist + `--disallowed-tools` for read-only audits to reduce hook firings
  - Caller-side: `--max-turns`, `timeout`, capture-to-file + extract, or kill the process once the final JSON has been seen (exactly the strategy "limitaré la extracción al reporte final disponible o cortaré el proceso para no dejarlo colgado")
- Updated the recommended pattern for heavy/long work to include the above.
- Added a new dedicated row in the Failure modes table for this symptom, with pointer back to the noise-reduction section.
- Enhanced the Quick reference card with:
  - A noise-filtered streaming example
  - A complete "heavy repo audit" example using the new techniques
- Minor cleanups to surrounding advice (JSON preference, long-running notes).
- This iteration makes the skill much more reliable when Codex (or similar agents) are asked to "delegar el análisis a Grok" via the skill.

Additional lessons captured from the full trace:
- The delegated process eventually terminated and produced a *useful* report, but only after many minutes of repeated hook warnings. The caller (Codex) wisely ran parallel local verification (`npm run typecheck` / `lint` / `test` / `check:schema`) instead of blocking.
- Even after receiving the report, the host still had to manually cross-check specific `file:line` claims against the real source and re-run builds to distinguish real bugs from inferences or "ruido del reporte".
- Added an "After you receive the report (verification is your job)" subsection + a complete, battle-tested "read-only auditor" prompt template (in Spanish/English adaptable) that matches the style that actually worked in the reported session.
- Documented the hybrid pattern that emerged: fire fast local checks in parallel + delegate to grok with strict constraints + extract final JSON defensively + always validate grok's findings with local tools and project commands.

## v2.2 — 2026-06-15

### Model discovery & robustness (real-world feedback from Codex usage)
- **Root cause from production use:** Codex (and similar agents) copy-pasted the "recommended invocation" example which hard-coded `--model grok-build-0.1`. In the user's environment the CLI only exposed the model as `grok-build` (listed via `grok models`). The first delegation attempt failed before any work started.
- **Fix:** 
  - Changed primary examples and guidance throughout `SKILL.md` to use `grok-build` as the documented coding model.
  - Added prominent **"Discovering the exact model name first"** section + pre-flight commands (`grok models`, `grok inspect`, `grok --version`, `git status`).
  - Added a small robust discovery one-liner for scripts/other agents:
    `MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)`
  - Updated the flags table, recommended pattern block, coding agent examples, custom models section, failure modes table, and Quick reference card.
  - Kept `grok-build-0.1` only as a historical example in explanations and as a trigger word for skill activation (backward compatibility).
- Also lightly updated README.md table and bullet to reflect the discovery requirement.
- This directly addresses the trace the user shared where Codex had to manually run `grok models` and re-launch.

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
