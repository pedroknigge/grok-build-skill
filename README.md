# grok-build skill

A drop-in **skill** that teaches Claude Code, Grok Build, Codex, or any agent that reads `SKILL.md` files how to drive the [xAI Grok Build CLI](https://docs.x.ai/build/overview) from the terminal in **headless mode** — including `/imagine`, `/imagine-video`, multi-turn sessions, ACP, **and when to prefer native Grok tools** (direct image/video generation, subagents, plan mode, MCPs via `search_tool`+`use_tool`, todo tracking, etc.) instead of shelling out.

Once installed, the host agent learns:

**CLI delegation patterns**
- Generate images: `grok -p "/imagine ..." --always-approve`
- Generate videos via the CLI
- Delegate coding / refactoring to `grok-build` (run `grok models` to discover exact ID) with proper `@file` + `--cwd`
- Streaming NDJSON, named sessions, JSON output, ACP

**Plus clear guidance on modern native alternatives** when the host *is* a capable Grok (spawn_subagent, todo_write, enter_plan_mode, direct `image_gen` tools, proper MCP usage, background monitoring, etc.).

The skill is kept current with flags, permission models, MCP patterns, and agent orchestration primitives.

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
| Image / video generation    | `grok -p "/imagine a neon Tokyo alley, 35mm" --always-approve` | `image_gen`, `image_to_video`, `image_edit`, `reference_to_video` |
| Repo Q&A / coding tasks     | `grok -p "@src/ Explain..." --cwd "$REPO" --output-format json` | Direct tools + `spawn_subagent` + `todo_write` |
| Targeted refactor           | `grok -p "@src/utils/... Refactor..." --always-approve`     | `search_replace` + subagents or plan mode |
| Multi-turn / long work      | Named sessions (`-s` / `-r`) + streaming-json               | `spawn_subagent`, background tasks + `monitor`, scheduler |
| Ambiguous architecture      | Multi-turn planning prompt to grok-build (use `grok models` first) | `enter_plan_mode` → design → `exit_plan_mode` |
| Integrations (GitHub, deploys, browser, designs) | Delegate via CLI prompt                                     | `search_tool` + `use_tool` (MCP) |
| Progress visibility         | Parse JSON / NDJSON                                         | `todo_write` (live task list) |

See [`skills/grok-build/SKILL.md`](./skills/grok-build/SKILL.md) for the complete reference (including the important "Native Grok vs CLI" decision guide).

## Prerequisites

- `grok` binary already on `PATH`
- User has run `grok login` at least once (cached token — this is the only supported auth mode)

**Warning:** This skill only works with the `grok login` cached token flow. It does **not** support `XAI_API_KEY` direct API usage. A clear warning is included in the skill itself.

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

PRs are very welcome. The goal is to keep the skill **short, accurate, and high-signal** while reflecting the latest Grok Build capabilities (new headless flags, MCP usage patterns with `search_tool`+`use_tool`, subagents, plan mode, direct image tools, background/monitoring, permissions model, richer skill frontmatter, etc.).

When updating:
- Edit the authoritative content in `skills/grok-build/SKILL.md`
- Keep the "Native Grok vs CLI delegation" guidance honest
- Update the quick reference and tables in README
- Bump version in frontmatter + add entry to CHANGELOG.md
- Test that the one-liner installer still works

See the local `~/.grok/docs/user-guide/` files (especially 07-mcp-servers, 08-skills, 14-headless, 16-subagents, 19-plan-mode, 20-background-tasks, 22-permissions) for the current truth.

## Sources

Official:
- [Grok Build — Getting Started](https://docs.x.ai/build/overview)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)

For the current Grok environment also consult the local user guide:
- `~/.grok/docs/user-guide/08-skills.md`
- `~/.grok/docs/user-guide/07-mcp-servers.md`
- `~/.grok/docs/user-guide/16-subagents.md`
- `~/.grok/docs/user-guide/19-plan-mode.md`
- And related files (headless, background tasks, permissions)
