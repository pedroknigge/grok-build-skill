---
name: grok-build
description: Invoke Grok Build (xAI's coding agent CLI) from the terminal in headless mode to generate images, videos, run code-aware prompts, or drive Grok as a sub-agent. Use when the user asks to "generate an image with Grok", "make a video with Grok", "use imagine / imagine-video", "run Grok headless", "call Grok from a script", "ask Grok to refactor X", or any task that should be delegated to the `grok` CLI. Also useful with /grok-build. Triggers on mentions of `grok`, `xai`, `Grok Build`, `imagine`, `imagine-video`, `grok-build`, or `xai-grok-shell`.
when-to-use: The user wants to delegate image/video generation, coding/refactoring work, repo Q&A, or scripted multi-step tasks specifically to the grok CLI binary in headless mode. Also when they mention running grok from another agent, using /imagine via CLI, or need machine-readable output from a Grok model.
allowed-tools: run_terminal_command
argument-hint: the prompt or task to send to grok
user-invocable: true
metadata:
  version: "3.0"
  last-updated: "2026-08-09"
  focus: "CLI delegation for Grok Build CLI 1.0.0+. Headless contract (dead flags removed), worktree caveat, streaming-messages-json, resume/restore-code, model default grok-4.5, host-side quality. Assumes grok install + auth."
---

# Grok Build CLI

Grok Build is xAI's coding-agent CLI (binary: `grok`). It runs as a TUI and as a fully scriptable **headless** mode that host agents drive through the shell.

**Target surface: Grok Build CLI 1.0.0+** (verified against live `grok 1.0.0` help, `grok models`, `grok doctor`, and local `~/.grok/docs/user-guide/`).

## When to use this skill

Use the `grok` CLI when you want to **delegate** work to a separate Grok agent with its own context, tools, and model:

- Image/video via CLI slash commands: `/imagine`, `/imagine-video`
- Coding / refactor / repo Q&A on a discovered model (default today: **`grok-4.5`**)
- Scripted multi-step work with machine-readable output (`json`, `streaming-json`, `streaming-messages-json`)
- Multi-turn UUID sessions (`-r` / `-c`), optional code restore (`--restore-code`)
- Isolated interactive worktrees (see **worktree caveat** below)

**Do not** use the CLI when native host tools already cover the request (simple edits, local terminal, host web search, host image tools).

## Native Grok capabilities vs CLI delegation

**Prefer native tools when the host is a capable Grok:**
- Images/video: `image_gen`, `image_edit`, `image_to_video`, `reference_to_video`
- Parallel work: native subagents / `todo_write` / plan mode
- MCP integrations: `search_tool` then `use_tool`
- Long ops: background shell + monitor primitives

**Still use `grok -p` when you want:** a separate model/context, auditable CLI output from Claude/Codex/scripts, multi-turn UUID sessions, or features easiest as a full Grok prompt.

Compose both: native orchestration first; CLI when a dedicated Grok session adds value.

## Breaking changes since skill 2.5 / CLI 0.2.97

| Topic | Skill 2.5 / old CLI | CLI 1.0.0+ (this skill) |
|-------|---------------------|-------------------------|
| Dead flags | Taught `--best-of-n`, `--check`, `--self-verify` | **Error if used.** Do not pass them. Quality → host multi-run + tests (see `references/quality-without-best-of-n.md`) |
| Worktree + headless | Implied isolation via `-p --worktree` | **Headless (`-p`) does not create a worktree from `--worktree`.** Use interactive/`agent` worktrees or host-side `git worktree` |
| Default model | Examples fell back to `grok-build` | Default is **`grok-4.5`**. Always `grok models` first; fallback string `grok-4.5` |
| Resume / restore | Conversation resume | Resume by **ID or title** (scripts: **UUID**). `--restore-code` requires `--resume`; restores conversation only without it. **Remote** code restore needs `--worktree` (never checks out into CWD) |
| Output formats | `plain`, `json`, `streaming-json` | Also **`streaming-messages-json`** + **`--include-partial-messages`** |
| Spend JSON | Mixed | `stopReason` is **snake_case** (e.g. `end_turn`); token/cost rules in `references/output-formats.md` |

## Prerequisites & auth matrix

This skill assumes install + auth already done for normal use.

1. Install: `curl -fsSL https://x.ai/cli/install.sh | bash`
2. Log in:
   - `grok login` — default browser OAuth
   - `grok login --oauth` — explicit OAuth
   - `grok login --device-auth` (alias `--device-code`) — headless/remote device code
3. Verify: `grok --version` (≥ **1.0**), `grok doctor`, `grok inspect`, `grok models`

**Auth notes:** Cached session token from login is preferred. `XAI_API_KEY` is a fallback when no session is active (skill recipes do not rely on it). An invalid API key fails auth — re-login or fix the key. Headless without credentials may hang or open a browser.

## Preflight (before heavy delegation)

```bash
command -v grok && grok --version   # require 1.0.0+
grok doctor
grok inspect
grok models
git status --short
```

```bash
MODEL=$(grok models 2>/dev/null | awk '
  /^Default model:/{ print $3; exit }
  /^[[:space:]]*\*/{ print $2; exit }
' || true)
MODEL="${MODEL:-grok-4.5}"
```

## Headless usage (main entry)

Always use `-p` / `--single`, `--prompt-file`, or `--prompt-json`. **Never** spawn the TUI from a script. **Stdin is not the prompt.**

```bash
grok -p "Your prompt here" --always-approve --no-auto-update
```

`--always-approve` auto-approves tools (alias **`--yolo`** works). Prefer narrow `--allow` / `--deny` when possible. Live helpers: `--no-ask-user`, `--no-wait-for-background`.

### Critical recipes (1.0)

```bash
# Robust one-shot
MODEL=$(grok models 2>/dev/null | awk '
  /^Default model:/{ print $3; exit }
  /^[[:space:]]*\*/{ print $2; exit }
')
MODEL="${MODEL:-grok-4.5}"
grok -p "$PROMPT" --cwd "$REPO_ROOT" --model "$MODEL" \
  --output-format json --always-approve --effort high --no-auto-update \
  2>/dev/null | jq -r '.text // empty'

# Multi-turn (UUID only for -s create; resume by UUID preferred)
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -p "Plan feature X. No code yet." --session-id "$SID" --cwd "$REPO" \
  --always-approve --no-auto-update --output-format json
grok -p "Implement the plan." --resume "$SID" --cwd "$REPO" --always-approve --no-auto-update

# Resume + code snapshot (requires --resume; remote needs --worktree)
grok -p "Continue." --resume "$SID" --restore-code --always-approve
# Remote session code restore (never mutates current dir without worktree):
# grok -p "Continue." --resume "$SID" --restore-code --worktree restore-sid --always-approve

# Structured JSON
grok -p "..." --json-schema '{"type":"object","properties":{"ok":{"type":"boolean"}}}' \
  --always-approve --no-auto-update

# Streaming (Messages wire format + partials)
grok -p "..." --output-format streaming-messages-json --include-partial-messages \
  --always-approve --no-auto-update

# Host-side quality (NO --best-of-n / --check)
for i in 1 2 3; do
  grok -p "$PROMPT" --cwd "$REPO" --model "$MODEL" --output-format json \
    --always-approve --no-auto-update 2>/dev/null | jq -r '.text' > "/tmp/run-$i.txt"
done
# Then host: pick best + run project tests/typecheck/lint
```

### Worktree caveat (must remember)

- Interactive / non-`-p` sessions: `-w/--worktree [NAME]` can create an isolated git worktree (`--worktree-ref` / `--ref` optional).
- **`grok -p ... --worktree ...` does not create a worktree** on CLI 1.0. For headless isolation, create a worktree with `git worktree add` (or interactive grok) and pass `--cwd` into that path.
- Cleanup: `grok worktree list|rm|gc` when worktrees were created by grok.

### Output formats (4) + partials

| Format | Shape |
|--------|-------|
| `plain` | Human text (default) |
| `json` | One final object: `text`, `stopReason` (snake_case, e.g. `end_turn`), `sessionId`, `usage`, costs… |
| `streaming-json` | NDJSON ACP-style events; spend on final `end` |
| `streaming-messages-json` | NDJSON Messages API wire format |
| + `--include-partial-messages` | Only with `streaming-messages-json`: `stream_event` deltas |

Token policy: uncached `input_tokens` + `cache_read_input_tokens` + `cache_creation_input_tokens` + `output_tokens` (creation may be 0). Missing `total_cost_usd` means **unreported**, not free (`cost_is_partial` / `usage_is_incomplete`). Details: `references/output-formats.md`.

### Sessions

- `-s/--session-id` **creates** a new session; value **must be a UUID** (not nicknames like `feat-123`).
- `-r/--resume [ID|title]` resumes (omit → most recent); `-c/--continue` → most recent for CWD.
- Scripts: prefer **UUID** from `.sessionId` JSON over titles.
- `--fork-session` with resume/continue branches history.
- `--restore-code` only with `--resume`; remote needs `--worktree` for code.

### Lifecycle

- Headless waits for background tasks/subagents on normal exit, then **kills** model-started bg tasks.
- SIGINT **130** / SIGTERM **143** / error **1** — resume with `--resume` / `-c`; applied edits are **not** rolled back.
- Noise usually on stderr → `2>/dev/null` + `jq`. Prefer `--allow`/`--deny`, `--max-turns`, `--no-auto-update`.

## Slash commands inside prompts

`/imagine`, `/imagine-video`, `/code-review`, `/goal`, `/effort`, `/model`, `/plan`, `/<skill>`. Prefer native image tools on capable Grok hosts.

## Advanced (brief)

- **MCP CLI:** `grok mcp list|enable|disable|doctor` (+ `add`/`remove`). Teach delegated agents `search_tool` → `use_tool`.
- **Workflows:** enabled by default (`GROK_WORKFLOWS=0` to disable). Prefer host workflows over reinventing orchestration when already available.
- **Sessions:** `grok sessions list|search|delete`; `grok export <SESSION_ID> [file]`.
- **Env:** `GROK_SANDBOX`, `GROK_DISABLE_AUTOUPDATER=1`, `GROK_EXTRA_CA_BUNDLE` (custom CA). Prefer native image/video tools over CLI `/imagine` when the host has them.
- **ACP:** `grok agent stdio` for long-lived clients; most hosts should stick to `-p`.

## Failure modes (host must handle)

| Symptom | Fix |
|---------|-----|
| Hang / browser | `grok login` / `--device-auth`; check credentials |
| Dead-flag errors (`--best-of-n`, `--check`, `--self-verify`) | Remove flags; host multi-run + tests |
| Expected worktree missing under `-p` | Host `git worktree` + `--cwd`; do not rely on `-p --worktree` |
| Permission prompts | `--always-approve` or narrow `--allow`/`--deny` |
| Non-UUID `-s` | `uuidgen` lowercase UUID for create only |
| Wrong model | `grok models`; fallback `grok-4.5` |
| Remote resume without code | Add `--restore-code` + `--worktree` |
| Missing cost fields | Unreported, not free |
| Exit 130/143 | Resume; re-verify files |

Full tables: `references/failure-modes.md`, `references/flags-1.0.md`, `references/sessions-and-resume.md`, `references/quality-without-best-of-n.md`, `references/prompt-templates.md`.

## Quick reference

```bash
grok doctor && grok inspect && grok models
MODEL="${MODEL:-grok-4.5}"
grok -p "/imagine ..." --cwd ./out --always-approve --no-auto-update
grok -p "<task>" -m "$MODEL" --cwd "$REPO" --output-format json \
  --always-approve --no-auto-update 2>/dev/null | jq -r '.text // empty'
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -s "$SID" -p "..." --cwd "$REPO" --always-approve
grok -r "$SID" -p "..." --always-approve --cwd "$REPO"
# NOT valid: --best-of-n, --check, --self-verify
# NOT magic: -p --worktree  (no worktree creation in headless)
```

## Sources

- [Grok Build Overview](https://docs.x.ai/build/overview) · [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting) · [Changelog](https://x.ai/build/changelog)
- Local: `~/.grok/docs/user-guide/14-headless-mode.md`, `02-authentication.md`, `17-sessions.md`, `22-permissions-and-safety.md`, `07-mcp-servers.md`
