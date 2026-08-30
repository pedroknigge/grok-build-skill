# grok-build skill

A drop-in **skill** that teaches Claude Code, Grok Build, Codex, or any agent that reads `SKILL.md` files how to drive the [xAI Grok Build CLI](https://docs.x.ai/build/overview) from the terminal in **headless mode** — including `/imagine`, `/imagine-video`, multi-turn sessions, ACP, **and when to prefer native Grok tools** instead of shelling out.

**Skill 3.1** targets **Grok Build CLI 1.0.13+** (verified against live `grok 1.0.13`). Default model **`grok-4.6`**; **`grok-4.5` is still available**.

Agent hub for this repo: [`AGENTS.md`](./AGENTS.md). On conflict, **code wins**.

Once installed, the host agent learns:

**CLI delegation patterns**
- Generate images/videos via CLI when needed: `grok -p "/imagine ..." --always-approve`
- Delegate coding / refactoring with discovered models (default today: **`grok-4.6`**; **`grok-4.5` still available**)
- Streaming NDJSON (`streaming-json`, **`streaming-messages-json`** + **`--include-partial-messages`**), **UUID sessions** + resume/title, JSON usage/cost
- Resume + optional **`--restore-code`** (remote needs **`--worktree`**)
- Correct **worktree** semantics: headless (`-p`) does **not** create a worktree from `--worktree`

**Quality without dead flags**
- CLI 1.0 **errors** on `--best-of-n`, `--check`, `--self-verify` — skill teaches host multi-run + tests instead

**Plus** clear guidance on native alternatives (subagents, plan mode, MCP `search_tool`+`use_tool`, image tools, etc.).

## Quick install

### One-shot installer (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash
```

Or from a clone (preferred for development / checksum verify):

```bash
git clone https://github.com/pedroknigge/grok-build-skill.git
cd grok-build-skill
./install.sh
# or explicit root: GROK_BUILD_SKILL_ROOT=$PWD ./install.sh
```

The installer copies the full `skills/grok-build/` directory (`SKILL.md` + `references/`) into detected agents. It hard-fails if any shipped reference is missing. Local tree is used only when `install.sh` is a real on-disk script whose directory contains `skills/grok-build/SKILL.md`, or when `GROK_BUILD_SKILL_ROOT` is set — `curl | bash` always uses `REPO_RAW` (not CWD).

Project-local install writes `.grok/skills/grok-build/` when the current directory has `.git` **or** `.grok/config.toml` (either trigger is enough).

**Release note:** the public one-liner and `REPO_RAW` fetches only deliver **this version (skill 3.1)** after this tree is **committed and pushed** to the branch those URLs point at. Until then, use clone + `./install.sh` from this workspace. Tag-pinned `v3.0.0` one-liners will not move until a new tag/release.

**Re-running is safe** — idempotent overwrite for Claude/Grok; Codex `AGENTS.md` block is replaced in place (no duplication).

**Uninstall:**

```bash
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash -s -- --uninstall
# or: ./install.sh --uninstall
```

### Optional integrity check

After clone, verify published checksums:

```bash
shasum -a 256 -c SHA256SUMS
```

`SHA256SUMS` covers `install.sh`, `skills/grok-build/SKILL.md`, and shipped `references/*`. Prefer **clone + `./install.sh`** over piping unknown scripts when you need auditability.

### Manual paths

```bash
# Claude Code — full directory
mkdir -p ~/.claude/skills/grok-build
cp -R skills/grok-build/* ~/.claude/skills/grok-build/

# Grok user skills
mkdir -p ~/.grok/skills/grok-build
cp -R skills/grok-build/* ~/.grok/skills/grok-build/

# Project-local (when the repo has .git or .grok/config.toml)
mkdir -p .grok/skills/grok-build
cp -R skills/grok-build/* .grok/skills/grok-build/
```

Codex: the installer embeds `SKILL.md` into `~/.codex/AGENTS.md` between markers (references path noted in the block). It does **not** write `~/.codex/skills/grok-build`.

## What the skill teaches

| Capability | CLI Delegation (1.0) | Native Grok alternative |
|------------|----------------------|-------------------------|
| Image / video | `grok -p "/imagine ..."` | `image_gen`, `image_to_video`, … |
| Repo Q&A / coding | `grok -p "..." --cwd "$REPO" --output-format json` | Direct tools + subagents |
| Structured output | `--json-schema` | Native tool results |
| Usage / cost | `jq '{sessionId, stopReason, total_cost_usd, usage}'` | Host metering |
| Isolation | Host `git worktree` + `--cwd` (not magic `-p --worktree`) | Subagent isolation |
| Quality | Host multi-run + tests (no `--best-of-n` / `--check`) | Parallel native subagents |
| Multi-turn | UUID `-s` create; `-r` UUID preferred | Native conversation |
| Resume code | `--resume ID --restore-code` (+ `--worktree` if remote) | N/A |
| Stream partials | `streaming-messages-json` + `--include-partial-messages` | Native streams |

Details live in [`skills/grok-build/SKILL.md`](./skills/grok-build/SKILL.md) (≤220-line entrypoint) and [`skills/grok-build/references/`](./skills/grok-build/references/).

## Prerequisites

- **Grok Build CLI 1.0.13+** on PATH (`grok --version`)
- Auth: `grok login` (or `grok login --device-auth` / `--oauth`)

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok login
grok doctor
grok inspect
grok models
```

This skill focuses on the logged-in headless flow. `XAI_API_KEY` is only a fallback when no session token is active.

## Compatibility

| Agent | Loads from | Invocation |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/grok-build/` | `/grok-build` |
| Grok Build (user) | `~/.grok/skills/grok-build/` | `/grok-build` |
| Grok Build (project) | `.grok/skills/grok-build/` | `/grok-build` (when `.git` or `.grok/config.toml` is present) |
| Codex CLI | `~/.codex/AGENTS.md` (embedded block) | Auto-context |
| Other `SKILL.md` hosts | agent skill dirs | varies |

## License

MIT — see [`LICENSE`](./LICENSE).

## Contributing

Keep the skill **short, accurate, and high-signal** for CLI **1.0.13+**. Agent hub: [`AGENTS.md`](./AGENTS.md). On conflict, **code wins**.

When updating:
- Edit `skills/grok-build/SKILL.md` (entrypoint) and/or `references/*` (six files; no 7th unless flags overflows)
- Do **not** teach `--best-of-n`, `--check`, `--self-verify` as live flags
- Model fallback: **`grok-4.6`** (keep a **`grok-4.5`** mention — still available). Never primary `echo grok-build`. grok-4.6 extra effort: **`xhigh`**
- Bump frontmatter `version` / `last-updated` and `CHANGELOG.md`
- If architecture or install destinations change, update `AGENTS.md` and `docs/`
- Run:
  ```bash
  ./scripts/validate-skill.sh
  ./scripts/install-smoke.sh
  ./scripts/sync-check-cli.sh   # optional if grok on PATH
  ```
- Refresh `SHA256SUMS` if `install.sh` or skill files change

### Development helpers

- `./scripts/validate-skill.sh` — 3.x contract (dead flags, required concepts)
- `./scripts/install-smoke.sh` — FAKE_HOME only; idempotency + uninstall
- `./scripts/sync-check-cli.sh` — optional live CLI help comparison

CI (`.github/workflows/ci.yml`) runs validate + install-smoke on push/PR.

## Sources

Prefer local `~/.grok/docs/user-guide/` and live `grok --help` / completions over the public headless-scripting page (it can lag).

- Local: `~/.grok/docs/user-guide/14-headless-mode.md`, `02-authentication.md`, `17-sessions.md`, `26-config-reference.md`, `27-grok-clone.md`
- [Grok Build Overview](https://docs.x.ai/build/overview)
- [Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)
- [Grok Build Changelog](https://x.ai/build/changelog)
