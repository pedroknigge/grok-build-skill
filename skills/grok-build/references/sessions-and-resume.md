# Sessions and resume (CLI 1.0.13)

## Create vs resume

| Action | Flag | Rules |
|--------|------|-------|
| Create | `-s` / `--session-id <UUID>` | Must be a **valid UUID** that does not already exist. **Does not resume.** Nicknames (`feat-123`) fail. |
| Resume | `-r` / `--resume [ID\|title]` | Resume by session ID or title; omit for most recent. **`--load <ID>` is an alias of `--resume`.** |
| Continue | `-c` / `--continue` | Most recent session for the **current directory**. |
| Fork | `--fork-session` | With resume/continue: new session ID (optionally named via `-s` UUID). |

Default headless: each `grok -p` creates a **fresh** session unless you resume/continue.

Since **1.0.11**, headless sessions are **browsable in the resume picker** without mixing into default history.

## Title vs UUID

- Resume accepts **ID or title** (case-insensitive title match for current directory).
- If several sessions share a title: a sole manually renamed match wins; otherwise ambiguity error with IDs listed.
- **UUID-shaped values always mean IDs**, never titles.
- **Scripts should prefer UUID** from JSON `.sessionId` (or `uuidgen` on create).

```bash
SID=$(uuidgen | tr '[:upper:]' '[:lower:]')
grok -p "Plan feature X." --session-id "$SID" --cwd "$REPO" \
  --always-approve --no-auto-update --output-format json

grok -p "Implement." --resume "$SID" --cwd "$REPO" --always-approve --no-auto-update
# equivalent: grok -p "Implement." --load "$SID" --cwd "$REPO" --always-approve --no-auto-update

# Capture from JSON
SID=$(grok -p "..." --output-format json --always-approve --no-auto-update 2>/dev/null | jq -r '.sessionId')
grok -p "Continue." --resume "$SID" --always-approve --cwd "$REPO"
```

## `--restore-code`

- Requires **`--resume`** (CLI errors without it).
- Restores the original session's **repository snapshot** when resuming.
- Without this flag: resume restores **conversation only**.
- **Remote sessions:** code restore requires **`--worktree`** — never checks out into the current directory.
- Conversation is restored either way on remote resume; code only with restore + worktree when remote.

```bash
# Local-style resume + code
grok -p "Continue from snapshot." --resume "$SID" --restore-code --always-approve

# Remote code restore (isolated worktree)
grok -p "Continue." --resume "$SID" --restore-code --worktree restore-"$SID" --always-approve
```

## Worktree + sessions

- Interactive sessions can create worktrees with `-w/--worktree`.
- **Headless (`-p`) does not create a worktree from `--worktree`.**
- For headless isolation: `git worktree add ...` then `--cwd` into that path, or restore remote code with `--restore-code --worktree`.

## Session management CLI

```bash
grok sessions list              # recent for CWD / worktree labels
grok sessions search <keyword>  # titles + prompts (local index + remote)
grok sessions delete <id>       # permanent delete
grok export <SESSION_ID> [file] # Markdown transcript (default stdout)
grok export <SESSION_ID> -c     # copy to clipboard
```

## Interrupted runs

| Signal | Exit | Resume |
|--------|------|--------|
| SIGINT | 130 | `grok -p "continue" --resume "<id>"` or `-c` |
| SIGTERM | 143 | same |
| Tool/agent error | 1 | inspect message; often still resumable |

Session state is saved through the last completed tool call. File edits already applied are **not** rolled back.
