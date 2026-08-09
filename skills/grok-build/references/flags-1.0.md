# Grok Build CLI 1.0 — flags reference

Verified against live `grok 1.0.0` (`grok --help`) and local headless docs.

## Dead flags (error if used)

Do **not** pass these — CLI returns `unexpected argument`:

| Flag | Skill 2.5 taught | Replacement |
|------|------------------|-------------|
| `--best-of-n <N>` | Parallel N-way pick best | Host-side multi-run; native subagents; tests |
| `--check` | Self-verify loop | Host tests / verification in prompt text |
| `--self-verify` | Alias of check | Same |

## Headless entry

| Flag | Purpose |
|------|---------|
| `-p, --single <PROMPT>` | One prompt, print response, exit. **Primary headless entry.** |
| `--prompt-file <PATH>` | Prompt from file |
| `--prompt-json <JSON>` | Prompt as JSON content blocks (multimodal) |
| `--verbatim` | Send prompt exactly (no client rewrite) |

Stdin is **not** the prompt.

## Model, effort, turns

| Flag | Purpose |
|------|---------|
| `-m, --model <MODEL>` | Model ID. Discover with `grok models`. Default often **`grok-4.5`**. |
| `--reasoning-effort` / `--effort` | Reasoning effort for capable models |
| `--max-turns <N>` | Max agent turns (**headless-only**) |
| `--rules <TEXT>` | Append rules to system prompt |
| `--system-prompt-override <PROMPT>` | Replace system prompt (alias `--system-prompt`) |
| `--agent <NAME>` | Agent name or definition file |
| `--agents <JSON>` | Inline subagent definitions (**headless-only**) |

## Sessions

| Flag | Purpose |
|------|---------|
| `-s, --session-id <UUID>` | **Create** new session; must be valid UUID not already present. Does **not** resume. With resume/continue only valid with `--fork-session`. |
| `-r, --resume [ID\|title]` | Resume by ID or title; omit → most recent. UUID-shaped values always mean IDs. Scripts prefer UUID. |
| `-c, --continue` | Most recent session for current directory |
| `--fork-session` | Fork into a new session ID on resume/continue |
| `--restore-code` | With **`--resume` only**: restore original session repo snapshot. Without it, conversation only. Remote sessions need **`--worktree`** (never checkout into CWD). |

## Worktree

| Flag | Purpose |
|------|---------|
| `-w, --worktree [NAME]` | New git worktree for the session (interactive / non-magic headless). **Headless (`-p`) does not create a worktree from this flag.** With remote resume + `--restore-code`, required to apply snapshot code. |
| `--worktree-ref` / `--ref` | Base branch/tag/commit for worktree |
| `--cwd <PATH>` | Execute as if from this directory |

## Output

| Flag | Purpose |
|------|---------|
| `--output-format <FMT>` | `plain` \| `json` \| `streaming-json` \| `streaming-messages-json` |
| `--include-partial-messages` | Incremental `stream_event` deltas; **only** with `streaming-messages-json` |
| `--json-schema <SCHEMA>` | Constrain final output; implies `--output-format json` |

## Permissions & tools

| Flag | Purpose |
|------|---------|
| `--always-approve` | Auto-approve tools (alias **`--yolo`**; same family as `--permission-mode bypassPermissions`) |
| `--yolo` | Live alias of `--always-approve` |
| `--permission-mode <MODE>` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` |
| `--allow <RULE>` | Permission allow (repeatable), e.g. `Bash(git *)`, `Read(src/**)` |
| `--deny <RULE>` | Permission deny (wins over allow) |
| `--tools <TOOLS>` | Allowlist comma-separated (**headless-only**) |
| `--disallowed-tools <TOOLS>` | Denylist (**headless-only**); supports `Agent`, `Agent(explore)`, … |
| `--no-ask-user` | Live: skip ask-user style interaction |
| `--no-wait-for-background` | Live: do not wait for background tasks before exit |

Prefer narrow allow/deny over blanket approve when the task allows.

## Safety / features toggles

| Flag | Purpose |
|------|---------|
| `--sandbox <PROFILE>` | Sandbox profile; env `GROK_SANDBOX` |
| `--disable-web-search` | Disable web search and fetch tools |
| `--no-plan` | Disable plan mode |
| `--no-subagents` | Disable subagent spawning |
| `--no-memory` / `--experimental-memory` | Cross-session memory off/on |
| `--no-auto-update` | Suppress update checks (recommended in CI). Env: `GROK_DISABLE_AUTOUPDATER=1` |
| `--oauth` | Prefer OAuth when welcome-screen auth starts |

## Useful subcommands (not flags)

| Command | Purpose |
|---------|---------|
| `grok doctor` | Terminal/clipboard/env checks |
| `grok inspect` | Discovered config for this directory |
| `grok models` | List models + default |
| `grok login` / `logout` | Auth |
| `grok mcp list\|enable\|disable\|doctor` | MCP management |
| `grok sessions list\|search\|delete` | Session index |
| `grok export <ID> [file]` | Export transcript as Markdown |
| `grok worktree list\|rm\|gc` | Worktree cleanup |
| `grok agent stdio` | ACP long-lived integration |

## Env vars (skill-relevant)

| Variable | Purpose |
|----------|---------|
| `GROK_SANDBOX` | Sandbox profile |
| `GROK_DISABLE_AUTOUPDATER=1` | No auto-update checks |
| `GROK_EXTRA_CA_BUNDLE` | Extra CA certificates for TLS |
| `GROK_WORKFLOWS=0` | Disable background workflows (default **enabled**) |
| `XAI_API_KEY` | API key fallback when no session token |
