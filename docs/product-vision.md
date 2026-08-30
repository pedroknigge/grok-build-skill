# Product vision

> Hub: [AGENTS.md](../AGENTS.md)

**Last updated:** 2026-08-30

## Problem

Host coding agents (Claude Code, Grok, Codex, others) need a **short, accurate** way to delegate work to the `grok` CLI in headless mode. CLI flags and defaults move faster than memory. Copy-pasted recipes that mention dead flags (`--best-of-n`, `--check`, `--self-verify`) or old model names (`grok-build`) fail before any work starts.

## Users

- Agents that load `SKILL.md` and shell out to `grok -p`
- Humans installing the skill via `install.sh` or a clone
- Maintainers keeping the skill in lockstep with Grok Build CLI 1.0.x

## Promise

Once installed, the host learns the **current** headless contract: discover models first, use UUID sessions, stream JSON when needed, isolate via host worktrees + `--cwd` (not magic `-p --worktree`), and prefer native host tools when they already cover the request.

## Outcomes

- A single skill directory (`SKILL.md` + six references) installs into the agents this repo actually supports.
- Re-install is idempotent; uninstall is clean.
- Validators fail the tree if the contract (3.x, dead flags, `grok-4.6` / `grok-4.5`, worktree caveat) is taught incorrectly.

## Non-goals

- Replacing Grok Build itself, or wrapping the TUI
- A fifth installer destination (`~/.codex/skills/grok-build`)
- Teaching every grok subcommand (`dashboard`, `plugin`, `trace`, …) as a recipe
- SaaS, control plane, or a Node/Python runtime in this repo
