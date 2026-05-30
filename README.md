# grok-build skill

A drop-in **skill** that teaches Claude Code, Grok Build, Codex, or any agent that reads `SKILL.md` files how to drive the [xAI Grok Build CLI](https://docs.x.ai/build/overview) from the terminal in **headless mode** — including `/imagine`, `/imagine-video`, multi-turn sessions, and ACP.

Once installed, your agent can:

- Generate images: `grok -p "/imagine ..." --always-approve`
- Generate videos: `grok -p "/imagine-video ..." --always-approve`
- Delegate coding tasks to `grok-build-0.1` with `@file` references
- Stream NDJSON output for live progress
- Resume named sessions across calls
- Speak the Agent Client Protocol (ACP) for long-lived sub-agents

The skill covers every flag, every slash command, every output format, and the common failure modes (auth hangs, permission prompts, `@file` resolution, etc.) so the host agent doesn't have to guess.

## Quick install

### Claude Code

```bash
mkdir -p ~/.claude/skills/grok-build
curl -fsSL https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/skills/grok-build/SKILL.md \
  -o ~/.claude/skills/grok-build/SKILL.md
```

Then invoke inside Claude Code with `/grok-build`.

### Grok Build itself

Grok auto-discovers skills from `~/.claude/skills/` and `~/.grok/skills/` — installing for Claude Code (above) makes it available to Grok with zero extra work. If you want a Grok-only install:

```bash
mkdir -p ~/.grok/skills/grok-build
curl -fsSL https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/skills/grok-build/SKILL.md \
  -o ~/.grok/skills/grok-build/SKILL.md
```

### Codex CLI (OpenAI)

Codex doesn't have the same skill-discovery system; it reads `AGENTS.md`. Append the skill to your global agents file:

```bash
mkdir -p ~/.codex
curl -fsSL https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/skills/grok-build/SKILL.md \
  >> ~/.codex/AGENTS.md
```

Or, per project, copy it as `AGENTS.md` in your repo root.

### One-shot installer

```bash
curl -fsSL https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/install.sh | bash
```

The script detects which agents you have installed and writes the skill in the right place(s).

## What the skill teaches the agent

| Capability | Example |
| --- | --- |
| Image generation | `grok -p "/imagine a neon Tokyo alley, 35mm" --always-approve` |
| Video generation | `grok -p "/imagine-video a hummingbird hovering on a hibiscus, 4s" --always-approve` |
| Repo-level Q&A | `grok -p "@src/ Explain the architecture." --cwd "$REPO" --output-format json` |
| Targeted refactor | `grok -p "@src/utils/date.ts Refactor to handle null inputs." --always-approve` |
| Multi-turn session | `grok -s feat-X -p "Plan it" ... && grok -r feat-X -p "Now build it"` |
| Streaming NDJSON | `grok -p "..." --output-format streaming-json \| jq -r '.content.text'` |
| ACP sub-agent | `grok agent stdio` with JSON-RPC `initialize` / `session/new` / `session/prompt` |

See [`skills/grok-build/SKILL.md`](./skills/grok-build/SKILL.md) for the full reference.

## Prerequisites

1. The `grok` binary on `PATH`:
   - macOS / Linux / WSL: `curl -fsSL https://x.ai/cli/install.sh | bash`
   - Windows PowerShell: `irm https://x.ai/cli/install.ps1 | iex`
2. An xAI API key in `XAI_API_KEY` (or a cached token from `grok login`).

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

PRs welcome. The skill is meant to stay short and current with xAI's docs at [docs.x.ai/build](https://docs.x.ai/build/overview). If xAI ships a new slash command, output format, or flag, open a PR updating `skills/grok-build/SKILL.md` and the cheatsheet section in this README.

## Sources

- [Grok Build — Getting Started](https://docs.x.ai/build/overview)
- [Skills, Plugins & Marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces)
- [Modes and Commands](https://docs.x.ai/build/modes-and-commands)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)
