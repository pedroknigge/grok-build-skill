---
name: grok-build
description: Invoke Grok Build (xAI's coding agent CLI) from the terminal in headless mode to generate images, videos, run code-aware prompts, or drive Grok as a sub-agent. Use when the user asks to "generate an image with Grok", "make a video with Grok", "use imagine / imagine-video", "run Grok headless", "call Grok from a script", "ask Grok to refactor X", or any task that should be delegated to the `grok` CLI. Also useful with /grok-build. Triggers on mentions of `grok`, `xai`, `Grok Build`, `imagine`, `imagine-video`, `grok-build`, `grok-build-0.1`, or `xai-grok-shell`.
when-to-use: The user wants to delegate image/video generation, coding/refactoring work, repo Q&A, or scripted multi-step tasks specifically to the grok CLI binary in headless mode. Also when they mention running grok from another agent, using /imagine via CLI, or need machine-readable output from a Grok model.
allowed-tools: run_terminal_command
argument-hint: the prompt or task to send to grok
user-invocable: true
metadata:
  version: "2.5"
  last-updated: "2026-07-12"
  focus: "CLI delegation for Grok Build ~0.2.97+. Headless flags (best-of-n, worktree, json-schema, spend/usage JSON), UUID sessions, native-vs-CLI guidance. Assumes grok install + `grok login`."
---

# Grok Build CLI

Grok Build is xAI's coding-agent CLI (binary: `grok`). It runs as a TUI, but it also has a fully scriptable **headless mode** that any other agent (Claude Code, Codex, custom bots, or even another Grok session) can drive through the shell. This skill teaches the host agent how (and when) to use it effectively.

Target surface: **Grok Build ~0.2.97+** (verified against local `grok --help` and `~/.grok/docs/user-guide/14-headless-mode.md`).

## When to use this skill

Pick the `grok` CLI (via this skill) when you want to **delegate** work to a Grok instance running as its own agent with its own context, tools, and model choice:

- **Image generation** → `/imagine <prompt>` (Grok Imagine model)
- **Video generation** → `/imagine-video <prompt>` (Grok Imagine video)
- **Coding tasks** routed to `grok-build` (or another configured model) — refactors, repo Q&A, codegen, tests
- **Scripted multi-step work** where you want machine-readable output (`--output-format json` / `streaming-json`), including **usage/cost** fields
- **Isolated second opinion or dedicated session** (UUID sessions, resume across calls, optional git worktree)
- **Quality-sensitive one-shots** via `--best-of-n` and/or `--check`
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
- Delegate to a **specific separate model/context** (e.g. `grok-build`) with its own memory and tool loop.
- Get reproducible, auditable output from "another Grok brain" (especially from Claude Code, Codex, or scripts).
- Use features that are easiest expressed as a full Grok prompt (slash commands inside the prompt, multi-turn UUID sessions, streaming NDJSON that the delegated grok handles).
- Isolate side effects with `--worktree`, quality-boost with `--best-of-n`, or force a verification loop with `--check`.
- The host agent lacks equivalent native tools or you explicitly want isolation.

The best agents **compose** both: use native tools + subagents for most work, and delegate via `grok -p ...` when a dedicated Grok coding session adds value.

**Recommendation inside prompts you send to grok CLI:** also teach the delegated grok to use `todo_write`, `spawn_subagent`, plan mode, and proper MCP patterns when it makes sense.

## Prerequisites

**This skill is meant to be used after you are already logged in.**

### First-time setup (do this once)

1. Install Grok Build (if you don't have the `grok` command yet):
   ```bash
   curl -fsSL https://x.ai/cli/install.sh | bash
   ```

2. Log in (this creates the cached token that headless mode uses):
   ```bash
   grok login
   ```

3. Verify everything is ready:
   ```bash
   grok inspect
   grok models
   ```

This skill assumes you have already completed the steps above. It is designed exclusively for the normal logged-in flow using the token from `grok login`.

**We do not cover `XAI_API_KEY` here.** If you haven't run `grok login`, headless calls will usually hang or try to open a browser.

Before heavy delegation, it's recommended to run `grok inspect` and `grok models` to confirm your setup.

## Headless usage (the main entry point)

The host agent should almost always invoke `grok` with `-p` / `--single <PROMPT>` (or `--prompt-file` / `--prompt-json`) so it executes and exits cleanly. Never spawn the interactive TUI from a script or another agent.

```bash
grok -p "Your prompt here"
```

**Stdin is not the prompt.** Headless mode does not read piped stdin into the prompt. Use `--prompt-file`, `--prompt-json`, or shell command substitution:

```bash
grok -p "Write a commit message for:

$(git diff --staged)" --always-approve

grok --prompt-file ./prompt.txt --always-approve --output-format json
```

### Important flags (Grok Build ~0.2.97+)

| Flag | Purpose |
|------|---------|
| `-p, --single <PROMPT>` | Send one prompt and exit. **Use this for almost all headless/scripted calls.** |
| `--prompt-file <PATH>` | Same as `-p`, but load prompt text from a file. |
| `--prompt-json <JSON>` | Prompt as JSON content blocks (multimodal / structured). |
| `--verbatim` | Send the prompt exactly as given (no client-side rewriting). |
| `-m, --model <MODEL>` | Choose model (e.g. `grok-build`). Run `grok models` first. |
| `-s, --session-id <UUID>` | Create a **new** session. **Must be a valid UUID** that does not already exist. Does **not** resume — use `-r`/`-c`. |
| `-r, --resume [ID]` | Resume a previous session by ID (or most recent if omitted). |
| `-c, --continue` | Continue the most recent session in the current directory. |
| `--fork-session` | With resume/continue, fork into a fresh session ID (optionally name via `-s`). |
| `--restore-code` | With resume: check out the original session's commit. |
| `--cwd <PATH>` | Execute as if run from this directory (critical for `@file` / repo context). |
| `-w, --worktree [NAME]` | Start the session in a **new git worktree** (isolated edits). |
| `--worktree-ref <REF>` / `--ref` | Branch/tag/commit to base the worktree on (with `--worktree`). |
| `--output-format <FMT>` | `plain`, `json`, `streaming-json`. |
| `--json-schema <SCHEMA>` | Constrain final output to a JSON Schema (implies `--output-format json`). |
| `--always-approve` | Auto-approve tools (required for unattended work). Docs also call this `--yolo` in places; prefer `--always-approve` (what `grok --help` lists). |
| `--permission-mode <MODE>` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`. Prefer narrow `--allow`/`--deny` when possible. |
| `--allow <RULE>` | Permission allow rule, repeatable (e.g. `Bash(git *)`, `Read(src/**)`, `MCPTool(...)`). |
| `--deny <RULE>` | Permission deny rule (wins over allow). |
| `--tools <TOOLS>` | Allowlist (comma sep). Internal names e.g. `run_terminal_cmd`. Headless-only. |
| `--disallowed-tools <TOOLS>` | Denylist. Supports `Agent`, `Agent(explore)`, etc. Headless-only. |
| `--effort` / `--reasoning-effort` | `none` / `minimal` / `low` / `medium` / `high` / `xhigh` / `max` (aliases interchangeable). |
| `--max-turns <N>` | Hard limit on agent turns. Headless-only. |
| `--best-of-n <N>` | Run the task **N ways in parallel and pick the best** (headless only). |
| `--check` / `--self-verify` | Append a self-verification loop to the prompt (headless only). |
| `--rules <TEXT>` | Inject custom rules into the system prompt. |
| `--system-prompt-override <PROMPT>` | Replace the agent's system prompt entirely. |
| `--agent <NAME>` | Agent name or definition file path. |
| `--agents <JSON>` | Inline subagent definitions as JSON (headless-only). |
| `--sandbox <PROFILE>` | Sandbox profile (`strict` etc.). Env: `GROK_SANDBOX`. |
| `--disable-web-search` | Disable web search and web fetch tools. |
| `--no-plan` | Disable plan mode. |
| `--no-subagents` | Disable subagent spawning. |
| `--no-memory` / `--experimental-memory` | Disable or enable cross-session memory for this session. |
| `--no-auto-update` | Suppress update checks (recommended in CI/scripts). Env: `GROK_DISABLE_AUTOUPDATER=1`. |

### Recommended invocation pattern from another agent

**Always discover the exact model name first.** Run `grok models` (and `grok inspect`) before delegation.

```bash
# 1. Pre-flight (strongly recommended)
command -v grok && grok --version
git status --short
grok inspect
grok models

# 2. Robust one-shot delegation (assumes install + `grok login`)
MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)

grok -p "$PROMPT" \
  --cwd "$REPO_ROOT" \
  --model "$MODEL" \
  --output-format json \
  --always-approve \
  --effort high \
  --no-auto-update
```

Prefer `--output-format json` + `jq`. For structured data, add `--json-schema`.

#### Isolated worktree (safe for multi-agent hosts)

```bash
MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)

grok -p "Implement feature X from the plan. Keep changes scoped." \
  --worktree feat-x --worktree-ref main \
  --cwd "$REPO_ROOT" \
  --model "$MODEL" \
  --output-format json \
  --always-approve \
  --effort high \
  --no-auto-update
```

Cleanup helpers (brief): `grok worktree list` (alias `ls`), `grok worktree rm`, `grok worktree gc`.

#### Quality-sensitive one-shot (`--best-of-n` + `--check`)

```bash
grok -p "Fix the failing test and prove it passes." \
  --best-of-n 3 \
  --check \
  --cwd "$REPO_ROOT" \
  --model "$MODEL" \
  --output-format json \
  --always-approve \
  --no-auto-update
```

### JSON output, session IDs, usage, and cost (0.2.97+)

With `--output-format json`, headless emits **one JSON object** after the response completes. Typical fields:

| Field | Meaning |
|-------|---------|
| `text` | Final assistant text (what most hosts want) |
| `stopReason` | e.g. `EndTurn` |
| `sessionId` | Use with `--resume` for multi-turn |
| `requestId` | Request correlation id |
| `num_turns` | Main-agent model rounds (same family as `--max-turns`) |
| `usage` | Token totals for the prompt (includes finished subagents) |
| `modelUsage` | Per-model breakdown + optional `costUSD` |
| `total_cost_usd` | Complete USD cost when the server stamped full cost |
| `total_cost_usd_ticks` | Exact integer ticks (1 USD = 10^10 ticks) for billing math |

**Token field policy (important):**
- `usage.input_tokens` / `modelUsage.*.inputTokens` are **uncached only**.
- `cache_read_input_tokens` / `cacheReadInputTokens` are cache hits.
- `total_tokens = input_tokens + cache_read_input_tokens + output_tokens`.

**Partial / incomplete spend:**
- `total_cost_usd` may be **absent** (OAuth/pool paths often omit cost). Absence means unreported — **not free**.
- When some calls lacked cost, `cost_is_partial` is true and **all** cost floats are omitted so you cannot invent a complete bill.
- When subagent usage could not be applied or drain timed out, `usage_is_incomplete` is true and cost floats are omitted the same way.

**Practical extraction:**

```bash
# Prefer field access when stdout is a single JSON object
... --output-format json 2>/dev/null | jq -r '.text // empty'
... | jq '{sessionId, num_turns, total_cost_usd, usage}'

# Capture session for multi-turn
SID=$(grok -p "..." --output-format json --always-approve --no-auto-update 2>/dev/null | jq -r '.sessionId')
grok -p "Continue from previous findings." --resume "$SID" --always-approve --cwd "$REPO"

# Noisy multi-object streams: take last object as fallback
... 2>/dev/null | jq -s 'last | .text // empty'
```

`streaming-json` emits NDJSON events (`text`, `thought`, `end`, `error`, plus non-exhaustive types like `max_turns_reached`). Spend fields land on the final `end` event. Filter with:

```bash
... --output-format streaming-json 2>/dev/null | \
  jq -c 'select(.type == "end" or .type == "final_assistant_message")' | tail -1
```

### Session management (UUID only for `-s`)

- Default: each `grok -p` creates a **fresh** session.
- **`-s/--session-id` only creates a new session** and **must be a valid UUID**. String nicknames like `feat-123` fail.
- Resume with `-r/--resume <id>` or `-c/--continue` (most recent for this directory).
- With `-r`/`-c`, use `--fork-session` (and optional `-s` UUID) to branch history instead of appending.

```bash
# Client-chosen UUID for a new multi-turn series
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -p "Plan feature X. Do not write code yet." \
  --session-id "$SID" --cwd "$REPO" --always-approve --no-auto-update

grok -p "Implement the plan." --resume "$SID" --always-approve --cwd "$REPO"
grok -p "Run tests and fix failures." --resume "$SID" --always-approve --cwd "$REPO"
```

### Headless lifecycle: background tasks and subagents

- On normal completion, headless **waits** for background tasks and subagents before exiting (so the final report can include their work).
- On exit, model-started background tasks are **killed** (no process leak). Do **not** rely on post-exit background processes.
- Put required verification **inside** the prompt, use `--check` / `--self-verify`, or re-run host-side tests after the process exits.

### Interrupted runs

| Signal | Exit code | Resume |
|--------|-----------|--------|
| SIGINT | **130** | `grok -p "continue" --resume "<id>"` or `-c` |
| SIGTERM | **143** | same |
| Normal tool/agent error | **1** | inspect message; often still resumable |

Session state is saved through the last completed tool call. File edits already applied are **not** rolled back.

### Reducing environment noise, hook spam, and extracting only the final report

This is especially important when the caller is **Codex, Claude Code, or another non-Grok agent** delegating long-running or broad tasks.

Even with `--output-format json`, you may still see:
- Hook traces, plugin/MCP warnings
- Permission banners
- Environment diagnostics

Noise is usually on **stderr**; stdout stays cleaner for JSON.

#### Practical noise-reduction techniques

1. **Suppress stderr**:
   ```bash
   grok -p "$PROMPT" --output-format json --always-approve --no-auto-update 2>/dev/null
   ```

2. **Extract final text / object**:
   ```bash
   ... | jq -r '.text // empty'          # single object
   ... | jq -s 'last'                    # multi-object / noisy stdout
   ```

3. **Streaming + filter** (see streaming-json example above).

4. **Strict prompt + escape hatch**:
   Tell the delegated agent to emit **only** the final report and to exit early if only noise remains.

5. **Modern safety + reduced noise with permissions** (preferred over blanket approve when possible):
   ```bash
   grok -p "$PROMPT" \
     --cwd "$REPO_ROOT" --model "$MODEL" \
     --output-format json \
     --no-auto-update \
     --allow 'Read' --allow 'Grep' \
     --allow 'Bash(git *)' --allow 'Bash(npm run *)' \
     --deny 'Bash(rm -rf *)' --deny 'Edit(**/secrets/**)' \
     --max-turns 25 2>/dev/null | jq -r '.text // empty'
   ```

6. **Tool restrictions** (excellent for read-only):
   ```bash
   --tools "read_file,grep,list_dir,run_terminal_cmd" \
   --disallowed-tools "search_replace,write,spawn_subagent,Agent" \
   --disable-web-search
   ```

7. **Caller-side safeguards**:
   - `--max-turns`, `timeout`, capture to file + `jq`.
   - Kill process after seeing final JSON if it keeps spewing noise.
   - **Always run local verification in parallel** (typecheck, lint, test, build, etc.).
   - There is no `--quiet` flag; these layered techniques are the current best practice.
   - Env hygiene: `GROK_DISABLE_AUTOUPDATER=1` and/or `--no-auto-update`.

#### Recommended enhanced pattern for heavy audits / long work

```bash
MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)

grok -p "$PROMPT" \
  --cwd "$REPO_ROOT" \
  --model "$MODEL" \
  --output-format json \
  --always-approve \
  --effort high \
  --max-turns 25 \
  --no-auto-update \
  --disable-web-search \
  2>/dev/null | jq -r '.text // empty'
```

For stricter control, add targeted `--allow` / `--deny`. For structured output, add `--json-schema '{...}'`.

#### After you receive the report (verification is your job)

Even a "useful" report from the delegated grok often contains:
- Inferences instead of direct evidence
- Slightly outdated or hallucinated line numbers
- Findings that are real but low priority

**Always** do this on the host side:
- Re-run the project's own fast verification commands in parallel: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`, etc.
- For every concrete claim (`file:line`), use your own tools (`read_file`, `grep`, `run_terminal_command`) to validate it.
- Separate "P0/P1 confirmed with evidence" from "inference / needs human review".
- The grok report is one high-quality signal among others — never the only source of truth.
- Prefer host-side tests after exit; headless kills leftover background tasks on exit.

#### Recommended strict prompt template for "analyze the project for errors" (read-only auditor)

```
Act as a senior code reviewer for this [framework] repository.

Objective: Analyze the project looking for real errors, likely regressions, security issues, data inconsistencies, build/test failures, or important UX bugs.

Strict rules:
- DO NOT modify any files. Read-only and safe verification commands only.
- You may run safe commands such as npm run typecheck, npm run lint, npm run test, npm run build, npm run check:schema, rg, git, etc.
- Prioritize actionable findings with exact file and line.
- If a finding is an inference or you couldn't verify it directly, state it clearly.
- Ignore style nitpicks.
- Focus especially on: [list of critical project areas, e.g. APIs, auth, Supabase/RLS, storage, webhooks, etc.].

Return a report in English with this exact format:
1. Executive summary: number of findings by severity (P0/P1/P2/P3).
2. Findings: severity, file:line, description, impact, concrete recommendation.
3. Commands executed and brief result.
4. Residual risks or unverified areas.

If after several minutes you only see repeated environment hook warnings, summarize what you have already analyzed and emit the final report immediately.
When finished emit ONLY the report in the requested format. Nothing else.
```

If you are the *host* and you are a capable Grok instance yourself, strongly prefer `spawn_subagent` + `monitor` / `get_command_or_subagent_output` (or `run_terminal_command` with `background: true`) over shelling out to the `grok` CLI for long work. The native primitives give you far better visibility and control than parsing noisy CLI output.

## Slash commands available inside a prompt

Slash commands (including skills) work inside headless prompts. Include them as the prompt text or embed in a larger instruction to the delegated grok.

| Command | What it does | Headless example |
|---------|--------------|------------------|
| `/imagine <prompt>` | Generate an image | `grok -p "/imagine a neon-lit Tokyo alley at dusk, cinematic, 35mm" --always-approve` |
| `/imagine-video <prompt>` | Generate a video | `grok -p "/imagine-video a slow dolly-in on a steaming cup of coffee..." --always-approve` |
| `/code-review` | Bundled code-review command | `grok -p "/code-review Focus on auth and API error paths" --always-approve --cwd "$REPO"` |
| `/goal <objective>` | Goal-mode objective | `grok -p "/goal Ship a green test suite for module X" --always-approve` |
| `/effort <level>` | Reasoning effort mid-session | Best in multi-turn / TUI; prefer `--effort` flag in one-shots |
| `/model <name>` | Switch model mid-session | Inside a resumed session |
| `/plan` | Plan mode (mostly TUI) | Limited headless value; use host plan mode or `--no-plan` to disable |
| `/<skill-name>` | Invoke another skill | `grok -p "/commit Conventional Commits style"` |
| `/docs`, `/context`, `/plugins`, `/mcps`, `/hooks` | Diagnostics / UIs | Prefer `grok inspect` from the host |

**Note on images/videos:** Prefer native `image_gen` etc. on capable Grok hosts. Use CLI `/imagine` delegation only when you specifically need the Grok Imagine path or isolation.

**Structured output:** Use `--json-schema` (headless) to force validated JSON instead of free text. Great for machine consumption.

### Examples for image and video (CLI delegation)

```bash
# Single image via CLI
grok -p "/imagine a watercolor map of a fictional medieval city, top-down" \
     --cwd ./out --always-approve --output-format plain --no-auto-update

# Short video clip
grok -p "/imagine-video a hummingbird hovering over a hibiscus, macro shot, 4s" \
     --cwd ./out --always-approve --output-format plain --no-auto-update

# Multi-turn image refinement via UUID session
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -s "$SID" -p "/imagine a cyberpunk samurai portrait, ink wash" \
     --cwd ./out --always-approve --no-auto-update
grok -r "$SID" -p "Now redo it with a softer palette and a tea-ceremony background." \
     --cwd ./out --always-approve --no-auto-update
```

## Driving Grok as a coding agent

The `grok` binary (especially with `-m grok-build`) powers a full agent loop. Host agents can delegate substantial work this way. Always confirm the model name with `grok models` first.

```bash
# Repo-level question
grok -p "@src/ Explain the request-handling architecture." \
     --cwd "$REPO" --output-format json --always-approve --no-auto-update

# Targeted refactor in an isolated worktree
grok -p "@src/utils/date.ts Refactor formatDate to handle null inputs and add tests." \
     --cwd "$REPO" --model grok-build --worktree fix-date --always-approve --no-auto-update

# Multi-turn session (plan → implement → review → test) with UUID
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -s "$SID" -p "Plan the implementation of feature X. Don't write code yet." --cwd "$REPO" --always-approve
grok -r "$SID" -p "Now implement the plan." --always-approve --cwd "$REPO"
grok -r "$SID" -p "Run the tests and fix any failures." --always-approve --cwd "$REPO" --check
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
- Use `enter_plan_mode` for tasks with genuine architectural ambiguity (the agent explores, writes a plan.md, then calls `exit_plan_mode` for approval before implementation). Plan files commonly live under `.grok/plan.md`.
- Long operations: `run_terminal_command` with `background: true`, then `get_command_or_subagent_output` / `monitor`.
- Scheduler for recurring background work.

These are often superior to a single giant `grok -p` call because they preserve context, enable true parallelism, and give the user visibility.

You can still delegate specific sub-tasks to a `grok -p` call from within a subagent if desired. When using the CLI, constrain the delegated agent with `--no-subagents`, `--no-plan`, or `--disallowed-tools "Agent"` as needed.

## ACP mode (advanced, only when needed)

For long-lived integration (IDEs, custom clients) use Agent Client Protocol:

```bash
grok agent stdio
```

It speaks JSON-RPC. This skill assumes you have Grok Build installed and have already run `grok login` (it uses the cached token). See the official headless scripting docs for full ACP details.

For most automation from another agent, plain `-p` headless is simpler and sufficient.

Related subcommands (rare for host agents): `grok agent headless`, `grok agent serve`, `grok agent leader`.

## Skills, plugins, hooks & discovery

`grok` (the delegated instance) auto-discovers skills from multiple locations (priority: local `./.grok/skills/`, repo `.grok/skills/`, user `~/.grok/skills/`, and `~/.claude/skills/` for compatibility).

Skills are directories containing a `SKILL.md` with YAML frontmatter (`name`, `description`, optional `when-to-use`, `allowed-tools`, `argument-hint`, `metadata`, etc.) followed by instructions.

The delegated grok can invoke other skills via `/<skill-name>` inside prompts.

It also discovers plugins, hooks, agents, and MCP servers. Use `grok inspect` (or instruct the delegated grok to run it) to see the full discovered environment. `grok inspect` lists skills from `[skills].paths` and labels bundled vs user skills.

Claude Code skills are largely compatible. Project skills/commands are discovered even when their directories are gitignored.

## Custom models

Users can configure extra models in `~/.grok/config.toml`:

```toml
[model.my-model]
model = "model-id"
base_url = "..."
name = "My Model"
env_key = "API_KEY"

[models]
default = "grok-build"
```

Select with `-m my-model`. List exact available models (including the default) with:

```bash
grok models
grok inspect
```

## Failure modes the host agent should handle

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Hangs or tries to open browser | Not logged in (no cached credentials) | Install if needed (`curl -fsSL https://x.ai/cli/install.sh \| bash`), then `grok login`. |
| Repeated permission prompts | No auto-approve / restrictive policy | `--always-approve`, or better: `--allow` + `--deny` + `dontAsk` / `bypassPermissions`. |
| Wrong repo context | Missing or incorrect `--cwd` | Always pass `--cwd "$REPO_ROOT"`. |
| Invalid session id / create failed | Non-UUID `-s` or reusing an existing UUID | Use `uuidgen` lowercase UUID for **new** sessions; resume with `-r`/`-c`. |
| Noisy output / appears stuck | Hook/plugin/MCP/permission spam | `2>/dev/null`, `jq -r '.text'`, strict final-report prompt, tool restrictions, `--max-turns`, `--no-auto-update`. |
| Unknown model | Hard-coded old model name | Always `grok models` first. |
| MCP calls fail | Skipped `search_tool` first | Teach `search_tool` → `use_tool` pattern. |
| Subagents/plan unavailable | Disabled in config or flags | Check `--no-subagents` / `--no-plan`; `grok inspect`; `[subagents]` config. |
| Structured output needed | Free text for machine parsing | `--json-schema` or strict JSON in prompt + `--output-format json`. |
| Missing cost fields | OAuth/pool or partial spend | Treat absence as unreported; check `cost_is_partial` / `usage_is_incomplete`. |
| Exit 130 / 143 | SIGINT / SIGTERM | Resume with `--resume` / `-c`; re-verify files (edits are not rolled back). |
| Expected background work gone after exit | Headless kills bg tasks on exit | Finish work inside the turn, use `--check`, or host-side verification. |

See the full Permissions & Safety guide for PreToolUse hooks, fast-paths for reads, `bypassPermissions`, etc.

## Quick reference card

**CLI Delegation (via this skill)**

```bash
# Image / video
grok -p "/imagine <prompt>" --cwd ./out --always-approve --no-auto-update
grok -p "/imagine-video <prompt>" --cwd ./out --always-approve --no-auto-update

# One-shot (discover model first!)
MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)
grok -p "<task>" -m "$MODEL" --cwd "$REPO" \
     --output-format json --always-approve --no-auto-update | jq -r '.text // empty'

# Usage / cost from JSON
... | jq '{sessionId, num_turns, total_cost_usd, usage}'

# Safer than blanket approve when possible
grok -p "..." --allow 'Read' --allow 'Bash(git *)' --deny 'Bash(rm*)' \
     --output-format json --no-auto-update

# Structured JSON output
grok -p "..." --json-schema '{"type":"object","properties":{"findings":{"type":"array"}}}' \
     --always-approve --no-auto-update

# Multi-turn (UUID session)
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -s "$SID" -p "..." --cwd "$REPO" --always-approve --no-auto-update
grok -r "$SID" -p "..." --always-approve --cwd "$REPO"

# Isolated worktree + self-check
grok -p "..." --worktree feat --worktree-ref main --check \
     --cwd "$REPO" -m "$MODEL" --output-format json --always-approve --no-auto-update

# Quality: best-of-n
grok -p "..." --best-of-n 3 --check --cwd "$REPO" \
     --output-format json --always-approve --no-auto-update

# Heavy audit (robust)
grok -p "Strict final report only..." --cwd "$REPO" --model "$MODEL" \
  --output-format json --always-approve --effort high --max-turns 25 \
  --disable-web-search --no-auto-update 2>/dev/null | jq -r '.text // empty'

# Inspect
grok inspect
grok models
grok worktree list
```

**When the host is native Grok (prefer these instead of or alongside CLI)**

- Images/video: `image_gen`, `image_to_video`, `image_edit`, `reference_to_video`
- Parallel work: `spawn_subagent({prompt, subagent_type: "explore" | "plan" | ...})`
- Task tracking: `todo_write([{id, content, status}])`
- Ambiguous design: `enter_plan_mode()` → explore → `exit_plan_mode()`
- MCPs: `search_tool({query})` then `use_tool({tool_name, tool_input})`
- Long ops: `run_terminal_command({command, background: true})` + `monitor` / `get_command_or_subagent_output`
- File work: `read_file`, `search_replace`, `write`, `grep`, `list_dir`

## Sources

Official:
- [Grok Build — Overview](https://docs.x.ai/build/overview)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)
- [Grok Build Changelog](https://x.ai/build/changelog)

Local authoritative docs (this environment):
- `~/.grok/docs/user-guide/14-headless-mode.md`
- `~/.grok/docs/user-guide/08-skills.md`
- `~/.grok/docs/user-guide/22-permissions-and-safety.md`
- `~/.grok/docs/user-guide/16-subagents.md`
- `~/.grok/docs/user-guide/19-plan-mode.md`
- `~/.grok/docs/user-guide/07-mcp-servers.md`
- `~/.grok/docs/user-guide/02-authentication.md`
- `~/.grok/docs/user-guide/17-sessions.md`
- `~/.grok/docs/user-guide/18-sandbox.md`

Run `grok inspect` regularly. PRs to keep this skill accurate are welcome.
