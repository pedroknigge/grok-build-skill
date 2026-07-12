# grok-build skill

A drop-in **skill** that teaches Claude Code, Grok Build, Codex, or any agent that reads `SKILL.md` files how to drive the [xAI Grok Build CLI](https://docs.x.ai/build/overview) from the terminal in **headless mode** — including `/imagine`, `/imagine-video`, multi-turn sessions, ACP, **and when to prefer native Grok tools** (direct image/video generation, subagents, plan mode, MCPs via `search_tool`+`use_tool`, todo tracking, etc.) instead of shelling out.

Once installed, the host agent learns:

**CLI delegation patterns**
- Generate images: `grok -p "/imagine ..." --always-approve`
- Generate videos via the CLI
- Delegate coding / refactoring to `grok-build` (run `grok models` to discover exact ID) with proper `@file` + `--cwd`
- Streaming NDJSON, **UUID sessions** + resume, JSON output (including **usage/cost**), ACP
- Isolated edits via `--worktree`, quality via `--best-of-n` / `--check`

**Plus clear guidance on modern native alternatives** when the host *is* a capable Grok (spawn_subagent, todo_write, enter_plan_mode, direct `image_gen` tools, proper MCP usage, background monitoring, etc.).

The skill is kept current with Grok Build ~0.2.97+ flags, permission models, MCP patterns, and agent orchestration primitives.

## Quick install

### Claude Code

```bash
mkdir -p ~/.claude/skills/grok-build
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/skills/grok-build/SKILL.md \
  -o ~/.claude/skills/grok-build/SKILL.md
```

Then invoke inside Claude Code with `/grok-build`.

### Grok Build itself

Grok auto-discovers skills from `~/.claude/skills/` and `~/.grok/skills/` — installing for Claude Code (above) makes it available to Grok with zero extra work. If you want a Grok-only install:

```bash
mkdir -p ~/.grok/skills/grok-build
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/skills/grok-build/SKILL.md \
  -o ~/.grok/skills/grok-build/SKILL.md
```

### Codex CLI (OpenAI)

Codex doesn't have the same skill-discovery system; it reads `AGENTS.md`. Append the skill to your global agents file:

```bash
mkdir -p ~/.codex
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/skills/grok-build/SKILL.md \
  >> ~/.codex/AGENTS.md
```

Or, per project, copy it as `AGENTS.md` in your repo root.

### One-shot installer (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash
```

The script detects which agents you have installed (Claude Code, Grok, Codex) and writes the skill in the right place(s).

**Re-running is safe** — `install.sh` is idempotent: it overwrites the Claude Code & Grok files and replaces the marked block inside Codex's `AGENTS.md` in place, so updating to a new version is just running the same one-liner again.

**To uninstall**, run the script with `--uninstall`:

```bash
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash -s -- --uninstall
```

That removes the skill from all detected agents and restores the original `AGENTS.md` for Codex (anything outside the `BEGIN / END grok-build skill` markers is preserved).

## What the skill teaches the agent

| Capability                  | CLI Delegation Example                                      | Native Grok Alternative (when available) |
|-----------------------------|-------------------------------------------------------------|------------------------------------------|
| Image / video generation    | `grok -p "/imagine ..." --always-approve` | `image_gen`, `image_to_video`, `image_edit`, `reference_to_video` |
| Repo Q&A / coding tasks     | `grok -p "@src/ ..." --cwd "$REPO" --output-format json --no-auto-update` | Direct tools + `spawn_subagent` + `todo_write` |
| Structured output           | `--json-schema '...'` (implies json) | Native tool results |
| Usage / cost from headless  | `jq '{sessionId, num_turns, total_cost_usd, usage}'` | Host metering |
| Isolated edits              | `--worktree feat --worktree-ref main` | `spawn_subagent` isolation / worktree |
| Quality one-shots           | `--best-of-n 3 --check` | Parallel subagents + host tests |
| Multi-turn sessions         | UUID via `-s` / capture `.sessionId`, then `-r` | Native conversation |
| Long / noisy work           | `--allow`/`--deny` + `2>/dev/null \| jq` + strict prompt | `monitor`, subagents |
| Ambiguous architecture      | Multi-turn to grok-build (discover with `grok models`)     | `enter_plan_mode` → `exit_plan_mode` |
| Integrations (GitHub, deploys, etc.) | Delegate via CLI prompt                                     | `search_tool` + `use_tool` (MCP) |
| Permission control          | `--allow 'Bash(git *)' --deny 'Bash(rm*)'`                  | Built-in permission system + hooks |

See [`skills/grok-build/SKILL.md`](./skills/grok-build/SKILL.md) for the complete reference (including the important "Native Grok vs CLI" decision guide).

## Prerequisites

- You have **Grok Build installed** (`grok` command on PATH)
- You have **already run `grok login`** successfully

If you're not set up yet:
1. Install: `curl -fsSL https://x.ai/cli/install.sh | bash`
2. Log in: `grok login`
3. Then use this skill.

This skill is for the logged-in flow only. It does not cover `XAI_API_KEY`. Full details in `skills/grok-build/SKILL.md`.

Before heavy delegation, `grok inspect` is recommended to verify the environment.

## Compatibility

| Agent | Loads from | Slash invocation |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/grok-build/SKILL.md` | `/grok-build` |
| Grok Build (TUI) | `~/.grok/skills/` or `~/.claude/skills/` | `/grok-build` |
| Codex CLI | `~/.codex/AGENTS.md` or `./AGENTS.md` | Auto-context |
| Anything else that reads `SKILL.md` | wherever it scans | varies |

## License

MIT — see [`LICENSE`](./LICENSE).

## Contributing

PRs are very welcome. The goal is to keep the skill **short, accurate, and high-signal** while reflecting the latest Grok Build capabilities.

When updating:
- Edit the authoritative content in `skills/grok-build/SKILL.md`
- Keep the "Native Grok vs CLI delegation" guidance honest
- Update quick reference tables + CHANGELOG.md
- Bump `version` in the frontmatter of SKILL.md
- Run `./scripts/validate-skill.sh`
- Run `./scripts/install-smoke.sh` (tests idempotency and uninstall)
- Verify the one-liner installer still works

See local `~/.grok/docs/user-guide/` (especially 14-headless-mode.md, 08-skills.md, 22-permissions-and-safety.md) and the official changelog at https://x.ai/build/changelog.

### Development helpers

- `./scripts/validate-skill.sh` — basic frontmatter and structure checks
- `./scripts/install-smoke.sh` — tests installer idempotency and uninstall

## Sources

Official:
- [Grok Build Overview](https://docs.x.ai/build/overview)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)
- [Grok Build Changelog](https://x.ai/build/changelog)

For the current Grok environment also consult:
- `~/.grok/docs/user-guide/14-headless-mode.md`
- `~/.grok/docs/user-guide/08-skills.md`
- `~/.grok/docs/user-guide/22-permissions-and-safety.md`
