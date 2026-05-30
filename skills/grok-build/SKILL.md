---
name: grok-build
description: Invoke Grok Build (xAI's coding agent CLI) from the terminal in headless mode to generate images, videos, run code-aware prompts, or drive Grok as a sub-agent. Use when the user asks to "generate an image with Grok", "make a video with Grok", "use imagine / imagine-video", "run Grok headless", "call Grok from a script", "ask Grok to refactor X", or any task that should be delegated to the `grok` CLI. Triggers on mentions of `grok`, `xai`, `Grok Build`, `imagine`, `imagine-video`, `grok-build-0.1`, or `xai-grok-shell`.
---

# Grok Build CLI

Grok Build is xAI's coding-agent CLI (binary: `grok`). It runs as a TUI, but it also has a fully scriptable **headless mode** that any other agent (Claude Code, Codex, custom bots, etc.) can drive through the shell. This skill teaches the host agent how to use it.

## When to use this skill

Pick `grok` over a local tool when the user wants:

- **Image generation** → `/imagine <prompt>` (Grok Imagine model)
- **Video generation** → `/imagine-video <prompt>` (Grok Imagine video)
- **Coding tasks** routed to `grok-build-0.1` (xAI's coding model) — refactors, repo Q&A, codegen
- **Scripted multi-step work** where you want machine-readable output (`--output-format json` / `streaming-json`)
- **A second opinion** alongside the current agent

Do **not** use this skill when the host agent's native tools already cover the request (e.g. simple file edits, web search), or when there is no `grok` binary on PATH and the user cannot install it.

## Prerequisites

1. `grok` on PATH. Install if missing:
   - macOS / Linux / WSL: `curl -fsSL https://x.ai/cli/install.sh | bash`
   - Windows PowerShell: `irm https://x.ai/cli/install.ps1 | iex`
2. Authentication, in priority order:
   - `XAI_API_KEY` env var (preferred for non-interactive use), or
   - `GROK_CODE_XAI_API_KEY` for ACP mode, or
   - A cached token from a previous `grok login`.
3. Verify before doing real work: `grok inspect` (lists discovered config, skills, plugins, MCPs).

If no API key is set and no cached token exists, **stop and ask the user** — `grok` will try to open a browser, which will hang in a headless context.

## Headless usage (the main entry point)

The host agent should always invoke `grok` with `-p` (single prompt) so it returns and exits. Never spawn the TUI from a script.

```bash
grok -p "Your prompt here"
```

### Flags worth knowing

| Flag | Purpose |
| --- | --- |
| `-p, --single <PROMPT>` | Send one prompt and exit. **Always use this in scripts.** |
| `-m, --model <MODEL>` | Pick a model (e.g. `grok-build-0.1`, or a custom one from config). |
| `-s, --session-id <ID>` | Create / resume a named headless session (lets you keep context across calls). |
| `-r, --resume <ID>` | Resume an existing session by ID. |
| `-c, --continue` | Continue the most recent session in the current directory. |
| `--cwd <PATH>` | Run as if invoked from `<PATH>` (so `@file` references resolve correctly). |
| `--output-format <FMT>` | `plain` (default, human text), `json` (one final object), `streaming-json` (NDJSON event stream). |
| `--always-approve` | Skip tool-call permission prompts. Required for unattended runs. |

### Recommended invocation pattern from another agent

```bash
XAI_API_KEY="$XAI_API_KEY" \
grok -p "$PROMPT" \
  --cwd "$REPO_ROOT" \
  --model grok-build-0.1 \
  --output-format json \
  --always-approve
```

Parse the final JSON object for the assistant text + tool-call summary. For long tasks, switch to `streaming-json` and consume newline-delimited events live.

## Slash commands available inside a prompt

Slash commands work the same in headless prompts — just include the command as the prompt body, or embed it inside a longer instruction.

| Command | What it does | Headless example |
| --- | --- | --- |
| `/imagine <prompt>` | Generate an image from text. | `grok -p "/imagine a neon-lit Tokyo alley at dusk, cinematic, 35mm" --always-approve` |
| `/imagine-video <prompt>` | Generate a video from text. | `grok -p "/imagine-video a slow dolly-in on a steaming cup of coffee on a wooden desk" --always-approve` |
| `/model <name>` | Switch active model mid-session. | Inside a resumed session. |
| `/plan` | Show current plan-mode plan. | Mostly TUI-useful. |
| `/context` | Inspect context usage. | Diagnostic only. |
| `/plugins`, `/mcps`, `/hooks` | Open management UIs (TUI only). | Skip in headless. |
| `/<skill-name>` | Run any user-invocable Grok skill as a command. | `grok -p "/commit Conventional Commits style"` |

The image/video outputs are written to the current working directory (or wherever the active Imagine plugin is configured to put them). Always run `ls` after the call to discover the produced file paths, since Grok prints them to stdout but the host agent should confirm.

### Examples for image and video

```bash
# Single image
grok -p "/imagine a watercolor map of a fictional medieval city, top-down" \
     --cwd ./out --always-approve --output-format plain

# Short video clip
grok -p "/imagine-video a hummingbird hovering over a hibiscus, macro shot, 4s" \
     --cwd ./out --always-approve --output-format plain

# Image then refine in a follow-up using the same session
grok -s img-session -p "/imagine a cyberpunk samurai portrait, ink wash"
grok -r img-session -p "Now redo it with a softer palette and a tea-ceremony background."
```

## Driving Grok as a coding agent

The same binary powers an agent loop over `grok-build-0.1`. Useful patterns the host agent can fire and parse:

```bash
# Repo-level question
grok -p "@src/ Explain the request-handling architecture." \
     --cwd "$REPO" --output-format json --always-approve

# Targeted refactor
grok -p "@src/utils/date.ts Refactor formatDate to handle null inputs and add tests." \
     --cwd "$REPO" --model grok-build-0.1 --always-approve

# Multi-turn session (e.g. plan -> implement -> review)
grok -s feat-123 -p "Plan the implementation of feature X. Don't write code yet." --cwd "$REPO"
grok -r feat-123 -p "Now implement the plan." --always-approve --cwd "$REPO"
grok -r feat-123 -p "Run the tests and fix any failures." --always-approve --cwd "$REPO"
```

`@path` references inside the prompt are resolved by Grok against `--cwd`, so always set `--cwd` to the project root when asking about files.

## Output-format cheatsheet

- **`plain`** — Use when piping into a human-readable report or capturing with `tee`.
- **`json`** — Use when the host agent only needs the final assistant text + metadata. One object on stdout at the end. Parse with `jq`.
- **`streaming-json`** — Use for long tasks, progress UIs, or when you want to intercept tool calls live. Each line is a JSON event (e.g. `agent_message_chunk`, `tool_call`, `tool_result`, `session_end`).

```bash
grok -p "Audit this repo for TODOs and group them by file." \
     --cwd "$REPO" --output-format streaming-json --always-approve \
  | while IFS= read -r line; do
      jq -r 'select(.type=="agent_message_chunk") | .content.text' <<<"$line"
    done
```

## ACP mode (advanced, only when needed)

If the host agent wants Grok as a long-lived sub-agent rather than one-shot prompts, use ACP:

```bash
grok agent stdio
```

This speaks JSON-RPC over stdin/stdout. Initialize with `initialize`, authenticate (`xai.api_key` if `GROK_CODE_XAI_API_KEY` is set, otherwise `cached_token`), open a session with `session/new`, and send `session/prompt`. Assistant text streams back as `session/update` events with `sessionUpdate == "agent_message_chunk"`. The final `session/prompt` response carries `stopReason`. See xAI docs for the full Node example: https://docs.x.ai/build/cli/headless-scripting

Prefer plain headless (`grok -p`) unless the host genuinely needs persistent bidirectional state — ACP adds a lot of plumbing.

## Skills, plugins, hooks (worth knowing it's there)

`grok` auto-discovers:

- Skills in `./.grok/skills/`, `<repo>/.grok/skills/`, `~/.grok/skills/`, and **`~/.claude/skills/`** (yes — Claude Code skills work as-is).
- Plugins in `.grok/plugins/` and `~/.grok/plugins/`, or `--plugin-dir <PATH>`.
- Hooks in `.grok/hooks/`.
- Claude Code marketplaces, MCPs, agents, and `AGENTS.md` / `CLAUDE.md` — fully compatible with zero config.

If a Claude Code skill already exists for a task, the host agent can forward to it via `grok -p "/<skill-name> ..."` without rewriting anything.

## Custom models

If the user has configured a non-default model in `~/.grok/config.toml`:

```toml
[model.my-model]
model = "model-id"
base_url = "https://api.example.com/v1"
name = "Display Name"
env_key = "API_KEY"

[models]
default = "my-model"
```

…the host agent can pick it with `-m my-model`, or list available ones via `grok inspect`.

## Failure modes the host agent should handle

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `grok` hangs on first run | Trying to open a browser for auth. | Set `XAI_API_KEY` and re-run, or have the user run `grok login` once interactively. |
| Permission prompts in headless | `approval_mode = "ask"` (default). | Add `--always-approve`, or set `[ui] approval_mode = "always-approve"` in `~/.grok/config.toml`. |
| `@file` not found | `--cwd` not set / wrong path. | Pass `--cwd` to the project root explicitly. |
| Empty or truncated output | Used `plain` for a long streaming task. | Switch to `streaming-json` and consume events. |
| Wrong model picked | No `-m` and config default differs. | Always pass `-m grok-build-0.1` (or the desired ID) when correctness matters. |

## Quick reference card

```bash
# Image
grok -p "/imagine <prompt>" --cwd ./out --always-approve

# Video
grok -p "/imagine-video <prompt>" --cwd ./out --always-approve

# Coding agent, one-shot, JSON-parseable
grok -p "<task>" -m grok-build-0.1 --cwd "$REPO" \
     --output-format json --always-approve

# Multi-turn session
grok -s <id> -p "<first prompt>" --cwd "$REPO" --always-approve
grok -r <id> -p "<next prompt>" --cwd "$REPO" --always-approve

# Diagnose config
grok inspect
```

## Sources

- [Getting Started](https://docs.x.ai/build/overview)
- [Skills, Plugins & Marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces)
- [Modes and Commands](https://docs.x.ai/build/modes-and-commands)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)
