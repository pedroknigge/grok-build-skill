# Failure modes (CLI 1.0.13)

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Hangs or tries to open browser | Not logged in / no cached credentials | `grok login`, or `grok login --device-auth` for headless/remote. Check `grok inspect`. |
| Auth failures with API key | Invalid or stale `XAI_API_KEY` | Fix key or prefer session token via `grok login`. Session token wins when present. |
| `unexpected argument '--best-of-n'` / `--check` / `--self-verify` | Dead flags on CLI 1.0 | Remove flags. Host multi-run + project tests. See `quality-without-best-of-n.md`. `--check` is only `grok update --check`. |
| Expected worktree not created under `-p` | Headless ignores worktree creation | Use host `git worktree add` + `--cwd`, or non-headless worktree; for remote restore use `--restore-code --worktree`. |
| Repeated permission prompts | No auto-approve / restrictive policy | `--always-approve` / `--yolo`, or better: `--allow` + `--deny` + modes like `dontAsk` / `bypassPermissions`. |
| Wrong repo context | Missing/incorrect `--cwd` | Always pass `--cwd "$REPO_ROOT"`. |
| Invalid session id / create failed | Non-UUID `-s` or reusing existing UUID | `uuidgen` lowercase for **new** sessions; resume with `-r`/`--load`/`-c`. |
| Title resume ambiguity | Multiple sessions share title | Use UUID from `.sessionId` or `grok sessions list`. |
| `--restore-code` rejected | Missing `--resume` | Always pair: `--resume <id> --restore-code`. |
| Remote resume without code changes | Conversation-only restore | Add `--restore-code` and `--worktree` for remote. |
| Noisy output / appears stuck | Hook/plugin/MCP/permission spam | `2>/dev/null`, `jq -r '.text'`, strict final-report prompt, tool restrictions, `--max-turns`, `--no-auto-update`. |
| Unknown model | Hard-coded old name (`grok-build` may be absent) | Always `grok models` first; fallback **`grok-4.6`**. **`grok-4.5`** is still available. |
| MCP calls fail | Skipped schema discovery | Teach `search_tool` → `use_tool`; host: `grok mcp doctor`. |
| Subagents/plan unavailable | Disabled | Check `--no-subagents` / `--no-plan`; `grok inspect`; config. |
| Structured output needed | Free text for machines | `--json-schema` + `--output-format json`. |
| Missing cost fields | OAuth/pool or partial spend | Treat absence as unreported; check `cost_is_partial` / `usage_is_incomplete`. |
| Exit 130 / 143 | SIGINT / SIGTERM | Resume with `--resume` / `-c`; re-verify files. |
| Expected background work gone after exit | Headless kills bg tasks on exit | Finish work inside the turn, use host-side verification, or `--no-wait-for-background` only when intentional. Bound wait with `--background-wait-timeout`. |
| Cross-session memory leaking into scripts | Memory enabled in config/remote | Prefer **`GROK_MEMORY=0`** for the process. `--no-memory` is legacy compat. |
| Version too old for this skill | Pre-1.0.13 CLI | Upgrade: `grok update` or reinstall; skill targets **1.0.13+**. |

## Since 1.0.0 (headless reliability)

- **1.0.1:** `grok -p` **no longer fails** when the agent asks for user input or plan approval. Still prefer `--no-ask-user` / `--always-approve` for unattended scripts. Headless waits for **MCP servers before tool use**.
- **1.0.11:** Headless sessions are **browsable in the resume picker** without mixing into default history.
- **1.0.13:** Length-truncated responses **continue automatically**; transient inference (stalls/drops/5xx) **retries**. Hang/browser is still mainly **auth**.

## After you receive a report

Always on the host:

1. Re-run project verification: typecheck, lint, test, build.
2. For every concrete `file:line` claim, verify with local tools.
3. Separate P0/P1 confirmed evidence from inference.
4. Treat the delegated report as one signal among others.
