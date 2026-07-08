---
name: grok-build
description: Invoke Grok Build (xAI's coding agent CLI) from the terminal in headless mode to generate images, videos, run code-aware prompts, or drive Grok as a sub-agent. Use when the user asks to "generate an image with Grok", "make a video with Grok", "use imagine / imagine-video", "run Grok headless", "call Grok from a script", "ask Grok to refactor X", or any task that should be delegated to the `grok` CLI. Also useful with /grok-build. Triggers on mentions of `grok`, `xai`, `Grok Build`, `imagine`, `imagine-video`, `grok-build`, `grok-build-0.1`, or `xai-grok-shell`.
when-to-use: The user wants to delegate image/video generation, coding/refactoring work, repo Q&A, or scripted multi-step tasks specifically to the grok CLI binary in headless mode. Also when they mention running grok from another agent, using /imagine via CLI, or need machine-readable output from a Grok model.
allowed-tools: run_terminal_command
argument-hint: the prompt or task to send to grok
user-invocable: true
metadata:
  version: "2.4"
  last-updated: "2026-07-08"
  focus: "CLI delegation patterns + guidance on when to prefer native Grok tools instead. Assumes Grok Build is installed and user has run `grok login`. Includes setup steps for first-time users."
---

# Grok Build CLI

Grok Build is xAI's coding-agent CLI (binary: `grok`). It runs as a TUI, but it also has a fully scriptable **headless mode** that any other agent (Claude Code, Codex, custom bots, or even another Grok session) can drive through the shell. This skill teaches the host agent how (and when) to use it effectively.

## When to use this skill

Pick the `grok` CLI (via this skill) when you want to **delegate** work to a Grok instance running as its own agent with its own context, tools, and model choice:

- **Image generation** → `/imagine <prompt>` (Grok Imagine model)
- **Video generation** → `/imagine-video <prompt>` (Grok Imagine video)
- **Coding tasks** routed to `grok-build` (or another configured model) — refactors, repo Q&A, codegen, tests
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
- Delegate to a **specific separate model/context** (e.g. `grok-build`) with its own memory and tool loop.
- Get reproducible, auditable output from "another Grok brain" (especially from Claude Code, Codex, or scripts).
- Use features that are easiest expressed as a full Grok prompt (slash commands inside the prompt, multi-turn named sessions, streaming NDJSON that the delegated grok handles).
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

### Important flags (updated for current Grok Build)

| Flag                        | Purpose |
|-----------------------------|---------|
| `-p, --single <PROMPT>`     | Send one prompt and exit. **Use this for almost all headless/scripted calls.** |
| `-m, --model <MODEL>`       | Choose model (e.g. `grok-build`). Run `grok models` first. |
| `-s, --session-id <ID>`     | Create a **new** session (UUID only). Use `--fork-session` with `-r`/`-c` if needed. |
| `-r, --resume <ID>`         | Resume a previous session by ID. |
| `-c, --continue`            | Continue the most recent session in the current directory. |
| `--fork-session`            | With resume/continue, fork into a fresh session ID. |
| `--cwd <PATH>`              | Execute as if run from this directory (critical for `@file` / repo context). |
| `--output-format <FMT>`     | `plain`, `json`, `streaming-json`. |
| `--always-approve` / `--yolo` | Auto-approve tools (required for unattended work). |
| `--permission-mode <MODE>` | `bypassPermissions` etc. (limited wiring; prefer `--allow`/`--deny` + `dontAsk`). |
| `--allow <RULE>`            | Permission allow rule, repeatable (e.g. `Bash(git *)`, `Read(src/**)`, `MCPTool(...)`). |
| `--deny <RULE>`             | Permission deny rule (wins over allow). Use for safety. |
| `--tools <TOOLS>`           | Allowlist (comma sep). Internal tool names e.g. `run_terminal_cmd`. |
| `--disallowed-tools <TOOLS>`| Denylist. Supports `Agent`, `Agent(explore)`, etc. |
| `--effort <LEVEL>` / `--reasoning-effort` | `none` / `minimal` / `low` / `medium` / `high` / `xhigh` / `max`. |
| `--max-turns <N>`           | Hard limit on turns. |
| `--json-schema <SCHEMA>`    | Constrain final output to a JSON Schema (headless). |
| `--rules <TEXT>`            | Inject custom rules into the system prompt. |
| `--sandbox <PROFILE>`       | Sandbox profile (`strict` etc.) for the session. |
| `--no-auto-update`          | Suppress update checks (recommended in CI/scripts). |
| `--check` / `--self-verify` | Append a verification loop (headless). |

### Recommended invocation pattern from another agent

**Always discover the exact model name first.** Run `grok models` (and `grok inspect`) before delegation.

This skill assumes you have already installed Grok Build and run `grok login`.

```bash
# 1. Pre-flight (strongly recommended)
command -v grok && grok --version
git status --short
grok inspect
grok models

# 2. Robust one-shot delegation (assumes Grok Build is installed + you ran `grok login`)
MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)

grok -p "$PROMPT" \
  --cwd "$REPO_ROOT" \
  --model "$MODEL" \
  --output-format json \
  --always-approve \
  --effort high \
  --no-auto-update
```

Prefer `--output-format json` + `jq`. For structured data, consider `--json-schema`.

See "Reducing environment noise..." below for production-grade patterns.

### Reducing environment noise, hook spam, and extracting only the final report

This is especially important when the caller is **Codex, Claude Code, or another non-Grok agent** delegating long-running or broad tasks.

**Recent improvement:** Headless runs now wait for background tasks and subagents to finish before exiting (good for correctness).

Even with `--output-format json`, you will often see:
- Hook traces, plugin/MCP warnings
- Permission banners
- Environment diagnostics

Noise can still be significant. Use the mitigations below.

#### Practical noise-reduction techniques (updated)

1. **Suppress stderr**:
   ```bash
   grok -p "$PROMPT" --output-format json --always-approve 2>/dev/null
   ```

2. **Extract final JSON**:
   ```bash
   ... | jq -s 'last'
   ```

3. **Streaming + filter**:
   ```bash
   ... --output-format streaming-json 2>/dev/null | \
     jq -c 'select(.type == "end" or .type == "final_assistant_message")' | tail -1
   ```

4. **Strict prompt + escape hatch** (critical):
   Tell the delegated agent to emit **only** the final report and to exit early if only noise remains.

5. **Modern safety + reduced noise with permissions** (preferred over broad --yolo):
   Use narrow `--allow` / `--deny` instead of blanket approval where possible:
   ```bash
   grok -p "$PROMPT" \
     --cwd "$REPO_ROOT" --model "$MODEL" \
     --output-format json \
     --no-auto-update \
     --allow 'Read' --allow 'Grep' \
     --allow 'Bash(git *)' --allow 'Bash(npm run *)' \
     --deny 'Bash(rm -rf *)' --deny 'Edit(**/secrets/**)' \
     --max-turns 25 2>/dev/null | jq -s 'last'
   ```

6. **Tool restrictions** (still excellent for read-only):
   ```bash
   --tools "read_file,grep,list_dir,run_terminal_cmd" \
   --disallowed-tools "search_replace,write,spawn_subagent,Agent"
   ```

7. **Caller-side safeguards**:
   - `--max-turns`, `timeout`, capture to file + `jq`.
   - Kill process after seeing final JSON if it keeps spewing noise.
   - **Always run local verification in parallel** (typecheck, lint, test, build, etc.).
   - Note: no `--quiet` flag exists; these layered techniques are the current best practice.

Headless now waits for background tasks/subagents, which improves reliability of the final report.

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
  2>/dev/null | jq -s 'last'
```

For stricter control, add targeted `--allow` / `--deny`.

For structured output, add `--json-schema '{...}'`.

#### After you receive the report (verification is your job)

Even a "useful" report from the delegated grok often contains:
- Inferences instead of direct evidence
- Slightly outdated or hallucinated line numbers
- Findings that are real but low priority

**Always** do this on the host side:
- Re-run the project's own fast verification commands in parallel (as Codex did): `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`, `npm run check:schema`, etc.
- For every concrete claim in the report (`file:line`), use your own tools (`read_file`, `grep`, `run_terminal_command`) to validate it.
- Separate "P0/P1 confirmed with evidence" from "inference / needs human review".
- The grok report is one high-quality signal among others — never the only source of truth.

#### Recommended strict prompt template for "analyze the project for errors" (read-only auditor)

Use something close to this when delegating a broad audit (adapted from real successful usage):

```
Actua como revisor senior de codigo para este repositorio [framework].

Objetivo: analizar el proyecto buscando errores reales, regresiones probables, problemas de seguridad, inconsistencias de datos, fallas de build/test o bugs de UX importantes.

Reglas estrictas:
- NO modifiques archivos. Solo lectura y comandos de verificación.
- Puedes ejecutar comandos seguros como npm run typecheck, npm run lint, npm run test, npm run build, npm run check:schema, rg, git, etc.
- Prioriza hallazgos accionables con archivo y linea exacta.
- Si un hallazgo es inferencia o no pudiste verificarlo directamente, dilo claramente.
- Ignora nitpicks de estilo.
- Enfocate especialmente en: [lista de áreas críticas del proyecto, ej. APIs, auth, Supabase/RLS, storage, webhooks, etc.].

Devuelve un reporte en [idioma] con este formato exacto:
1. Resumen ejecutivo: cantidad de hallazgos por severidad (P0/P1/P2/P3).
2. Hallazgos: severidad, archivo:linea, descripcion, impacto, recomendacion concreta.
3. Comandos ejecutados y resultado breve.
4. Riesgos residuales o areas no verificadas.

Si después de varios minutos solo ves warnings repetidos de hooks del entorno, resume lo que ya analizaste y emite el reporte final inmediatamente.
Al terminar emite SOLO el reporte en el formato pedido. Nada más.
```

This style produced a useful report in the trace that motivated these improvements.

If you are the *host* and you are a capable Grok instance yourself, strongly prefer `spawn_subagent` + `monitor` / `get_command_or_subagent_output` (or `run_terminal_command` with `background: true`) over shelling out to the `grok` CLI for long work. The native primitives give you far better visibility and control than parsing noisy CLI output.

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

**Note on images/videos:** Prefer native `image_gen` etc. on capable Grok hosts. Use CLI `/imagine` delegation only when you specifically need the Grok Imagine path or isolation.

**New structured output:** Use `--json-schema` (headless) to force validated JSON instead of free text. Great for machine consumption.

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

The `grok` binary (especially with `-m grok-build`) powers a full agent loop. Host agents can delegate substantial work this way. Always confirm the model name with `grok models` first.

```bash
# Repo-level question
grok -p "@src/ Explain the request-handling architecture." \
     --cwd "$REPO" --output-format json --always-approve

# Targeted refactor
grok -p "@src/utils/date.ts Refactor formatDate to handle null inputs and add tests." \
     --cwd "$REPO" --model grok-build --always-approve

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

It speaks JSON-RPC. This skill assumes you have Grok Build installed and have already run `grok login` (it uses the cached token). See the official headless scripting docs for full ACP details.

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
default = "grok-build"
```

Select with `-m my-model`. List exact available models (including the default) with:

```bash
grok models
grok inspect
```

## Failure modes the host agent should handle

| Symptom                        | Likely cause                                      | Fix |
|--------------------------------|---------------------------------------------------|-----|
| Hangs or tries to open browser | You have not run `grok login` yet (no cached credentials) | First install Grok Build if needed (`curl -fsSL https://x.ai/cli/install.sh | bash`), then run `grok login`. Only use this skill after you are logged in. |
| Repeated permission prompts    | No `--always-approve` / `--yolo` or restrictive policy | Use `--always-approve`, or better: `--allow` + `--deny` rules + `dontAsk`. |
| Wrong repo context             | Missing or incorrect `--cwd`                      | Always pass `--cwd "$REPO_ROOT"`. |
| Noisy output / appears stuck   | Hook/plugin/MCP/permission spam                   | `2>/dev/null \| jq -s 'last'`, strict "final report only" prompt, tool restrictions, `--max-turns`, `--no-auto-update`. |
| Unknown model                  | Hard-coded old model name                         | Always `grok models` first. |
| MCP calls fail                 | Skipped `search_tool` first                       | Teach `search_tool` → `use_tool` pattern. |
| Subagents/plan unavailable     | Disabled in config or old version                 | `grok inspect`; check `[subagents]`. |
| Structured output needed       | Using plain text for machine parsing              | Use `--json-schema` or strict JSON in prompt + `--output-format json`. |

See the full Permissions & Safety guide for PreToolUse hooks, fast-paths for reads, `bypassPermissions`, etc.

## Quick reference card

**CLI Delegation (via this skill)**

```bash
# Image / video
grok -p "/imagine <prompt>" --cwd ./out --always-approve --no-auto-update
grok -p "/imagine-video <prompt>" --cwd ./out --always-approve

# One-shot (discover model first!)
MODEL=$(grok models 2>/dev/null | head -1 | awk '{print $1}' || echo grok-build)
grok -p "<task>" -m "$MODEL" --cwd "$REPO" \
     --output-format json --always-approve --no-auto-update

# With modern permission controls (safer than blanket yolo)
grok -p "..." --allow 'Read' --allow 'Bash(git *)' --deny 'Bash(rm*)' \
     --output-format json --always-approve --no-auto-update

# Structured JSON output
grok -p "..." --json-schema '{"type":"object","properties":{"findings":{"type":"array"}}}' \
     --output-format json --always-approve

# Multi-turn
grok -s feat-xyz -p "..." --cwd "$REPO" --always-approve --no-auto-update
grok -r feat-xyz -p "..." --always-approve --cwd "$REPO"

# Heavy audit (robust)
MODEL=... 
grok -p "Strict final report only..." --cwd "$REPO" --model "$MODEL" \
  --output-format json --always-approve --effort high --max-turns 25 \
  --no-auto-update 2>/dev/null | jq -s 'last'

# Inspect
grok inspect
grok models
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

Run `grok inspect` regularly. PRs to keep this skill accurate are welcome.
