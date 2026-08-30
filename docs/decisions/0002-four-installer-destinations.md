# ADR-0002: Four installer destinations (Codex via AGENTS.md)

**Status:** Superseded by [ADR-0003](./0003-native-agy-destinations.md)
**Date:** 2026-08-30  
**Tags:** architecture, distribution

## Context / Problem

Hosts discover skills from different paths. Codex in this project is taught via `~/.codex/AGENTS.md`, not a skills directory. A fifth dest (`~/.codex/skills/grok-build`) would imply a surface the installer does not maintain.

## Alternatives Considered

1. **Directory copy for every host** — Codex would not auto-load it in the current installer.
2. **Four dest: Claude dir, Grok user dir, project `.grok/skills`, Codex embed** — chosen.
3. **Also write `~/.codex/skills/grok-build`** — rejected; PUBLISH.md and `install.sh` do not.

## Decision

`install.sh` installs to:

1. `$HOME/.claude/skills/grok-build/` when `claude` is on PATH or `~/.claude` exists
2. `$HOME/.grok/skills/grok-build/` when `grok` is on PATH or `~/.grok` exists
3. `.grok/skills/grok-build/` when CWD has `.git` **or** `.grok/config.toml`
4. `$HOME/.codex/AGENTS.md` marked block when `codex` is on PATH or `~/.codex` exists

Detection uses `command -v` **or** the config directory so the skill still installs on machines that have the agent home but not the binary on PATH.

Re-runs overwrite dirs and replace the Codex block in place (`strip_block`). `--uninstall` removes dirs and the marked block only.

## Consequences

**Positive:** Idempotent; smoke test can assert exactly one BEGIN/END pair.  
**Negative / Risks:** Project-local install also runs when this *skill repo* is a git checkout (expected). `curl | bash` from a random CWD still must not copy a stranger's `skills/` tree (`resolve_skill_root`).  
**Neutral:** Footer text historically said “inside a git repo”; the condition is `.git` OR `.grok/config.toml`.

## Links

- Architecture: [../architecture.md](../architecture.md)
- Feature: [../features/installer/README.md](../features/installer/README.md)
- Publish: [../../PUBLISH.md](../../PUBLISH.md)
- Superseding decision: [ADR-0003](./0003-native-agy-destinations.md)
