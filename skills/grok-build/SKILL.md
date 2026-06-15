---
name: grok-build
description: Invoke Grok Build (xAI's coding agent CLI) from the terminal in headless mode to generate images, videos, run code-aware prompts, or drive Grok as a sub-agent. Use when the user asks to "generate an image with Grok", "make a video with Grok", "use imagine / imagine-video", "run Grok headless", "call Grok from a script", "ask Grok to refactor X", or any task that should be delegated to the `grok` CLI. Also useful with /grok-build. Triggers on mentions of `grok`, `xai`, `Grok Build`, `imagine`, `imagine-video`, `grok-build-0.1`, or `xai-grok-shell`.
when-to-use: The user wants to delegate image/video generation, coding/refactoring work, repo Q&A, or scripted multi-step tasks specifically to the grok CLI binary in headless mode. Also when they mention running grok from another agent, using /imagine via CLI, or need machine-readable output from a Grok model.
allowed-tools: run_terminal_command
argument-hint: the prompt or task to send to grok
user-invocable: true
metadata:
  version: "2.1"
  last-updated: "2026-06-15"
  focus: "CLI delegation patterns + guidance on when to prefer native Grok tools instead"
---

# Grok Build CLI

Grok Build is xAI's coding-agent CLI (binary: `grok`). It runs as a TUI, but it also has a fully scriptable **headless mode** that any other agent (Claude Code, Codex, custom bots, or even another Grok session) can drive through the shell. This skill teaches the host agent how (and when) to use it effectively.

## When to use this skill

Pick the `grok` CLI (via this skill) when you want to **delegate** work to a Grok instance running as its own agent with its own context, tools, and model choice:

- **Image generation** → `/imagine <prompt>` (Grok Imagine model)
- **Video generation** → `/imagine-video <prompt>` (Grok Imagine video)
- **Coding tasks** routed to `grok-build-0.1` (or another configured model) — refactors, repo Q&A, codegen, tests
- **Scripted multi-step work** where you want machine-readable output (`--output-format json` / `streaming-json`)
- **Isolated second opinion or dedicated session** (named sessions, resume across calls)
- Running Grok as a long-lived sub-agent via ACP

**Do not** use this skill (or the CLI) when the host agent's *native* tools already cover the request perfectly (simple file edits, direct web search, local terminal commands the host can run itself, etc.).

## Native Grok capabilities vs CLI delegation (important)

Modern Grok instances (including this one) have powerful **direct tools** that often make shelling out to `grok -p` unnecessary or suboptimal:

**Prefer native tools when the host is a capable Grok:**
- Images & video: Use `image_gen`, `image_edit`, `image_to_video`, `reference_to_video` directly (faster, native integration, no extra process or stdout parsing).
- Complex/parallel work: `spawn_subagent` (different agent types like `explore`, `plan`, `general-purpose`; supports capability modes and isolation) + `todo_write` for progress tracking.
- Ambiguous engineering tasks: `enter_plan_mode` / `exit_plan_mode` — the host explores, designs an approach in a plan file, then asks for approval before coding.
- Integrations: `search_tool` (to discover MCP schema) followed by `use_tool` for GitHub (push_files, issues, PRs), Railway, Vercel, Chrome DevTools, Pencil designs, etc.
- Long-running operations: `run_terminal_command` with `background: true` + `monitor` / `get_command_or_subagent_output`.
- Structured orchestration: `scheduler`, direct file tools (`search_replace`, `write`, `read_file`, `grep`), subagent spawning.

**Still use the `grok` CLI (via this skill) when you want to:**
- Delegate to a **specific separate model/context** (e.g. `grok-build-0.1`) with its own memory and tool loop.
- Get reproducible, auditable output from "another Grok brain" (especially from Claude Code, Codex, or scripts).
- Use features that are easiest expressed as a full Grok prompt (slash commands inside the prompt, multi-turn named sessions, streaming NDJSON that the delegated grok handles).
- The host agent lacks equivalent native tools or you explicitly want isolation.

The best agents **compose** both: use native tools + subagents for most work, and delegate via `grok -p ...` when a dedicated Grok coding session adds value.

**Recommendation inside prompts you send to grok CLI:** also teach the delegated grok to use `todo_write`, `spawn_subagent`, plan mode, and proper MCP patterns when it makes sense.

## Prerequisites

This skill assumes `grok` is already installed on PATH and the user has successfully run `grok login` (at least once). The `grok login` flow caches a token in `~/.grok/` that headless calls use automatically.

**Important warning (only mode supported):** This skill and all examples are built exclusively for the `grok login` cached-token flow. **It does not support or use `XAI_API_KEY` direct API mode.** If `grok login` has not been completed, headless calls will typically hang (trying to open a browser) or fail.

Before heavy use, run `grok inspect` (from the host or inside a delegated call) to verify the environment, discovered skills, plugins, and MCP servers.

## Headless usage (the main entry point)

The host agent should almost always invoke `grok` with `-p` / `--single <PROMPT>` (or `--prompt-file` / `--prompt-json`) so it executes and exits cleanly. Never spawn the interactive TUI from a script or another agent.

```bash
grok -p "Your prompt here"
```

### Important flags (updated for current versions)

| Flag                        | Purpose |
|-----------------------------|---------|
| `-p, --single <PROMPT>`     | Send one prompt and exit. **Use this for almost all headless/scripted calls.** |
| `-m, --model <MODEL>`       | Choose model (e.g. `grok-build-0.1`). Highly recommended for coding tasks. |
| `-s, --session-id <ID>`     | Create or name a session for multi-turn continuity. |
| `-r, --resume <ID>`         | Resume a previous named session. |
| `-c, --continue`            | Continue the most recent session in the current directory. |
| `--cwd <PATH>`              | Execute as if run from this directory (critical for `@file` / repo context resolution). |
| `--output-format <FMT>`     | `plain` (human text), `json` (final object), `streaming-json` (NDJSON events). |
| `--always-approve`          | Skip permission prompts (equivalent to yolo for the delegated agent). Required for unattended automation. |
| `--yolo`                    | Stronger auto-approve mode (see permissions docs). |
| `--permission-mode <MODE>`  | `bypassPermissions`, `acceptEdits`, etc. |
| `--tools <TOOLS>`           | Comma-separated allowlist of tools the delegated grok may use. |
| `--disallowed-tools <TOOLS>`| Denylist (supports `Agent` entries). |
| `--effort <LEVEL>`          | `low` / `medium` / `high` / `xhigh` / `max` reasoning effort (headless only). |
| `--max-turns <N>`           | Hard limit on agentic turns. |

### Recommended invocation pattern from another agent

```bash
grok -p "$PROMPT" \
  --cwd "$REPO_ROOT" \
  --model grok-build-0.1 \
  --output-format json \
  --always-approve
```

Auth is provided automatically by the `grok login` cached token in `~/.grok/`. No environment variables are required.

For long-running tasks, prefer `--output-format streaming-json` and process NDJSON events (agent_message_chunk, tool_call, tool_result, session_end, etc.).

Parse `json` output with `jq` for the final assistant text + tool summary.

## Slash commands available inside a prompt

Slash commands (including skills) work inside headless prompts. Include them as the prompt text or embed in a larger instruction to the delegated grok.

| Command              | What it does                          | Headless example |
|----------------------|---------------------------------------|------------------------------------------|
| `/imagine <prompt>`  | Generate an image                     | `grok -p "/imagine a neon-lit Tokyo alley at dusk, cinematic, 35mm" --always-approve` |
| `/imagine-video <prompt>` | Generate a video                 | `grok -p "/imagine-video a slow dolly-in on a steaming cup of coffee..." --always-approve` |
| `/model <name>`      | Switch model mid-session              | Inside a resumed session. |
| `/plan`              | Show/enter plan mode (mostly TUI)     | Limited headless value. |
| `/<skill-name>`      | Invoke another skill (e.g. /commit)   | `grok -p "/commit Conventional Commits style"` |
| `/context`, `/plugins`, `/mcps`, `/hooks` | Diagnostics / UIs (TUI-heavy) | Skip or use for inspect only in headless. |

**Note on images/videos:** When the *host* is a modern Grok session that has direct `image_gen` / `image_to_video` tools available, those are usually faster and more integrated than delegating via `/imagine`. Use the CLI delegation when you specifically want the Grok Imagine flow through the grok binary (or the host lacks the native tools).

Image/video files are written to the current working directory (or the location configured for the Imagine plugin). The delegated grok will usually print the paths — the host should `ls` or inspect to confirm.

### Examples for image and video (CLI delegation)

```bash
# Single image via CLI
grok -p "/imagine a watercolor map of a fictional medieval city, top-down" \
     --cwd ./out --always-approve --output-format plain

# Short video clip
grok -p "/imagine-video a hummingbird hovering over a hibiscus, macro shot, 4s" \
     --cwd ./out --always-approve --output-format plain

# Multi-turn image refinement via named session
grok -s img-session -p "/imagine a cyberpunk samurai portrait, ink wash"
grok -r img-session -p "Now redo it with a softer palette and a tea-ceremony background."
```

## Driving Grok as a coding agent

The `grok` binary (especially with `-m grok-build-0.1`) powers a full agent loop. Host agents can delegate substantial work this way:

```bash
# Repo-level question
grok -p "@src/ Explain the request-handling architecture." \
     --cwd "$REPO" --output-format json --always-approve

# Targeted refactor
grok -p "@src/utils/date.ts Refactor formatDate to handle null inputs and add tests." \
     --cwd "$REPO" --model grok-build-0.1 --always-approve

# Multi-turn session (plan → implement → review → test)
grok -s feat-123 -p "Plan the implementation of feature X. Don't write code yet." --cwd "$REPO"
grok -r feat-123 -p "Now implement the plan." --always-approve --cwd "$REPO"
grok -r feat-123 -p "Run the tests and fix any failures." --always-approve --cwd "$REPO"
```

**Tip:** Inside the prompt you send to the delegated grok, also instruct it to use `todo_write` for multi-step work and to respect the host's preferred orchestration style.

`@path` references are resolved relative to `--cwd`. Always pass an explicit `--cwd "$REPO_ROOT"` when the task involves files.

## MCP Servers (powerful integrations)

The delegated `grok` can access MCP servers (GitHub, Railway, Vercel, Chrome DevTools, Pencil for designs, databases, etc.).

**Critical pattern the host must teach:**
1. Call the `search_tool` tool first with a query describing the desired MCP tool (e.g. "github push files" or "railway deploy"). This returns the exact input schema.
2. Then call `use_tool` with the precise `tool_name` (fully qualified, e.g. `grok_com_github__push_files`) and a `tool_input` object that exactly matches the schema.

Example goal you can give the delegated grok:
"Use the GitHub MCP to push these three files to the main branch with message 'Update skill'. First search for the right tool using search_tool."

Host agents that have direct MCP access should usually prefer `search_tool` + `use_tool` natively instead of delegating the entire task.

## Subagents, Plan Mode, Background Tasks & Todo Tracking

When the *host* has modern agent primitives (highly recommended):

- Use `spawn_subagent` to run independent child sessions in parallel (each with its own context window). Specify `subagent_type` (`general-purpose`, `explore`, `plan`, `code-reviewer`, etc.) and `capability_mode`.
- Use `todo_write` to maintain a live task list the user can see.
- Use `enter_plan_mode` for tasks with genuine architectural ambiguity (the agent explores, writes a plan.md, then calls `exit_plan_mode` for approval before implementation).
- Long operations: `run_terminal_command` with `background: true`, then `get_command_or_subagent_output` / `monitor` / `wait_commands_or_subagents`.
- Scheduler for recurring background work.

These are often superior to a single giant `grok -p` call because they preserve context, enable true parallelism, and give the user visibility.

You can still delegate specific sub-tasks to a `grok -p` call from within a subagent if desired.

## ACP mode (advanced, only when needed)

For long-lived integration (IDEs, custom clients) use Agent Client Protocol:

```bash
grok agent stdio
```

It speaks JSON-RPC. Authenticate with the `cached_token` from `grok login`. See current xAI headless scripting docs and the Agent Client Protocol spec for full details (initialize, session/new, session/prompt, streaming updates).

For most automation from another agent, plain `-p` headless is simpler and sufficient.

## Skills, plugins, hooks & discovery

`grok` (the delegated instance) auto-discovers skills from multiple locations (priority: local `./.grok/skills/`, repo `.grok/skills/`, user `~/.grok/skills/`, and `~/.claude/skills/` for compatibility).

Skills are directories containing a `SKILL.md` with YAML frontmatter (`name`, `description`, optional `when-to-use`, `allowed-tools`, `argument-hint`, `metadata`, etc.) followed by instructions.

The delegated grok can invoke other skills via `/<skill-name>` inside prompts.

It also discovers plugins, hooks, agents, and MCP servers. Use `grok inspect` (or instruct the delegated grok to run it) to see the full discovered environment.

Claude Code skills are largely compatible.

## Custom models

Users can configure extra models in `~/.grok/config.toml`:

```toml
[model.my-model]
model = "model-id"
base_url = "..."
name = "My Model"
env_key = "API_KEY"

[models]
default = "grok-build-0.1"
```

Select with `-m my-model`. List via `grok inspect`.

## Failure modes the host agent should handle

| Symptom                        | Likely cause                                      | Fix |
|--------------------------------|---------------------------------------------------|-----|
| `grok` hangs on first run      | No `grok login` cached token (tries browser)      | Tell user to run `grok login` interactively once. |
| Repeated permission prompts    | Default approval_mode or no `--always-approve`    | Add `--always-approve` (or `--yolo`). Configure `[ui] approval_mode = "always-approve"` or use permission modes. |
| `@file` / repo context wrong   | `--cwd` missing or incorrect                      | Always pass `--cwd "$REPO_ROOT"`. |
| Truncated / empty long output  | Used `plain` on a streaming-heavy task            | Switch to `streaming-json` and consume events. |
| Wrong model or behavior        | Default model not what you expect                 | Explicitly pass `-m grok-build-0.1` (or desired model). |
| MCP tool calls fail            | Host (or delegated) didn't call `search_tool` first | Teach the strict `search_tool` → `use_tool` pattern for all MCPs. |
| Subagent / plan mode unavailable | Older grok CLI or subagents disabled in config    | Check `grok inspect` and config (`GROK_SUBAGENTS`, `[subagents]`). |

See the full Permissions & Safety guide for PreToolUse hooks, fast-paths for reads, `bypassPermissions`, etc.

## Quick reference card

**CLI Delegation (via this skill)**

```bash
# Image / video
grok -p "/imagine <prompt>" --cwd ./out --always-approve
grok -p "/imagine-video <prompt>" --cwd ./out --always-approve

# One-shot coding agent (recommended for delegation)
grok -p "<task description>" -m grok-build-0.1 --cwd "$REPO" \
     --output-format json --always-approve

# Multi-turn named session
grok -s feat-xyz -p "First prompt..." --cwd "$REPO" --always-approve
grok -r feat-xyz -p "Next step..." --always-approve --cwd "$REPO"

# Streaming progress
grok -p "..." --output-format streaming-json --always-approve | ...

# Inspect environment (very useful)
grok inspect
```

**When the host is native Grok (prefer these instead of or alongside CLI)**

- Images/video: `image_gen`, `image_to_video`, `image_edit`, `reference_to_video`
- Parallel work: `spawn_subagent({prompt, subagent_type: "explore" | "plan" | ...})`
- Task tracking: `todo_write([{id, content, status}])`
- Ambiguous design: `enter_plan_mode()` → explore → `exit_plan_mode(plan)`
- MCPs: `search_tool({query})` then `use_tool({tool_name, tool_input})`
- Long ops: `run_terminal_command({command, background: true})` + `monitor` / `get_command_or_subagent_output`
- File work: `read_file`, `search_replace`, `write`, `grep`, `list_dir`

## Sources

Official:
- [Grok Build — Getting Started](https://docs.x.ai/build/overview)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)
- [Skills, Plugins & Marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces)

Local environment (authoritative for this Grok version):
- `~/.grok/docs/user-guide/08-skills.md`
- `~/.grok/docs/user-guide/07-mcp-servers.md`
- `~/.grok/docs/user-guide/14-headless-mode.md`
- `~/.grok/docs/user-guide/16-subagents.md`
- `~/.grok/docs/user-guide/19-plan-mode.md`
- `~/.grok/docs/user-guide/20-background-tasks.md`
- `~/.grok/docs/user-guide/22-permissions-and-safety.md`

Keep this skill current as xAI ships new flags, MCPs, or agent primitives. PRs welcome.
