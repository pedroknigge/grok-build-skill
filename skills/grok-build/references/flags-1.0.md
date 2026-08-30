# Grok Build CLI 1.0.13 — flags reference

Verified against live `grok 1.0.13` (`grok --help`, clap-generated completions under `~/.grok/completions/`, and `~/.grok/docs/user-guide/14-headless-mode.md`). Several headless flags are **omitted from default `--help`** but are live (completions + clap): `--memory-flush`, `--background-wait-timeout`, `--load`, `--compaction-mode`, `--compaction-detail`, `--no-ask-user`, `--no-wait-for-background`, `--no-memory`, `--experimental-memory`. `--yolo` is a hidden alias of `--always-approve`.

## Dead flags (error if used)

Do **not** pass these on `grok -p` — CLI returns `unexpected argument`:

| Flag | Skill 2.5 taught | Replacement |
|------|------------------|-------------|
| `--best-of-n <N>` | Parallel N-way pick best | Host-side multi-run; native subagents; tests |
| `--check` | Self-verify loop | Host tests / verification in prompt text. Live only as `grok update --check` |
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
| `-m, --model <MODEL>` | Model ID. Discover with `grok models`. Default today **`grok-4.6`**; **`grok-4.5`** is still available. |
| `--reasoning-effort` / `--effort` | Canonical levels: `none \| minimal \| low \| medium \| high \| xhigh \| max`. A model only accepts advertised levels. **`grok-4.6` extra effort `xhigh`** (4.5 menu has no `xhigh`). |
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
| `--load <ID>` | Alias of `--resume`. |
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
| `--yolo` | Hidden live alias of `--always-approve` |
| `--permission-mode <MODE>` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` |
| `--allow <RULE>` | Permission allow (repeatable), e.g. `Bash(git *)`, `Read(src/**)` |
| `--deny <RULE>` | Permission deny (wins over allow) |
| `--tools <TOOLS>` | Allowlist comma-separated (**headless-only**) |
| `--disallowed-tools <TOOLS>` | Denylist (**headless-only**); supports `Agent`, `Agent(explore)`, … |
| `--no-ask-user` | Skip ask-user style interaction |
| `--no-wait-for-background` | Do not wait for background tasks before exit (**headless-only**; conflicts with `--background-wait-timeout`) |

Prefer narrow allow/deny over blanket approve when the task allows.

## Memory, wait, compaction (headless)

| Flag | Purpose |
|------|---------|
| `--memory-flush` | **Headless-only:** run memory flush after the turn (or instead of a prompt when resuming). Calls `x.ai/memory/flush`. `/flush` as `-p` text is **not** a reliable flush trigger. |
| `--background-wait-timeout <SECS>` | **Headless-only:** max seconds to wait for bash/monitor/subagent work after the first turn. Persistent `monitor(persistent:true)` always waits the full timeout. Conflicts with `--no-wait-for-background`. |
| `--compaction-mode` | `summary` \| `transcript` \| `segments` (default `segments`). Sets `GROK_COMPACTION_MODE`. |
| `--compaction-detail` | `none` \| `minimal` \| `balanced` \| `verbose` (default `verbose`); **only** with `segments`. Sets `GROK_COMPACTION_DETAIL`. |

Process-wide memory off: prefer **`GROK_MEMORY=0`**. `--no-memory` / `--experimental-memory` are **legacy compatibility** flags (still live).

## Safety / features toggles

| Flag | Purpose |
|------|---------|
| `--sandbox <PROFILE>` | Sandbox profile; env `GROK_SANDBOX` |
| `--disable-web-search` | Disable web search and fetch tools |
| `--no-plan` | Disable plan mode |
| `--no-subagents` | Disable subagent spawning |
| `--no-auto-update` | Suppress update checks (recommended in CI). Env: `GROK_DISABLE_AUTOUPDATER=1` |
| `--oauth` | Prefer OAuth when welcome-screen auth starts |

## Useful subcommands (not flags)

| Command | Purpose |
|---------|---------|
| `grok doctor` | Terminal/clipboard/env checks. `--json`; `grok doctor fix …` |
| `grok inspect` | Discovered config for this directory. `--json` |
| `grok models` | List models + default |
| `grok login` / `logout` | Auth |
| `grok mcp list\|enable\|disable\|doctor` | MCP management (`--json` on list/doctor). `grok mcp add` auto-http for bare `http(s)://` URLs |
| `grok sessions list\|search\|delete` | Session index |
| `grok export <ID> [file]` | Export transcript as Markdown (`-c` / `--clipboard`) |
| `grok worktree list\|rm\|gc` | Worktree cleanup (`ls` alias; `show`; `detach`; `gc --max-age`) |
| `grok clone <url> [dir]` | Grove lazy-clone (NFS macOS / FUSE Linux). Gated `[clone] enabled = true` in Grove config. Default **depth-1** selected branch; `--full-history` for full clone; `--branch` / `--cone`. 1.0.10+ can reuse a matching local checkout as a linked worktree. |
| `grok memory clear` | Cross-session memory (`--workspace` / `--global` / `--all` / `-y`) |
| `grok agent stdio` | ACP long-lived integration (most hosts stay on `-p`) |

Low-priority (not skill recipes): `grok du`/`disk-usage`, `trace`, `dashboard`, `wrap`, `share`, `setup`, `plugin`, `leader`, `workspace`, `completions`.

## Env vars (skill-relevant)

| Variable | Purpose |
|----------|---------|
| `GROK_MEMORY=0` | Process-wide memory off (preferred over `--no-memory`) |
| `GROK_HOME` | Override `~/.grok` |
| `GROK_CONFIG` / `GROK_CONFIG_PATH` | Launcher config overlay without editing toml |
| `GROK_LOG_FILE` / `RUST_LOG` | Headless logs to stderr |
| `GROK_COMPACTION_MODE` / `GROK_COMPACTION_DETAIL` | Pair with compaction flags |
| `GROK_SANDBOX` | Sandbox profile |
| `GROK_DISABLE_AUTOUPDATER=1` | No auto-update checks |
| `GROK_EXTRA_CA_BUNDLE` | Extra CA certificates for TLS |
| `GROK_WORKFLOWS=0` | Disable background workflows (default **enabled**) |
| `XAI_API_KEY` | API key fallback when no session token |

Skip dashboard/OTEL/status-line fleet vars.

## Advanced (rarely needed for `-p` recipes)

`--trust`, `--storage-mode` (`local`\|`writeback`), `--hunk-tracker-mode`, `--todo-gate`, `--leader-socket` / `--leader` / `--no-leader`, `--client-identifier`. TUI chrome (`--minimal` / `--fullscreen` / `--no-alt-screen`) and ACP `--terminal` / `--fs-*` are out of this skill’s headless recipes.
