# How to publish this repo

Two paths — pick whichever you prefer.

## Option A — One-liner with `gh` CLI (recommended)

Prereq: [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login` once).

From this folder:

```bash
chmod +x install.sh && \
git init -b main && \
git add . && \
git commit -m "Initial commit: grok-build skill" && \
gh repo create grok-build-skill --public --source=. --remote=origin --push \
  --description "Drop-in skill teaching agents to drive the xAI Grok Build CLI in headless mode (plus native Grok tool guidance)."
```

This creates the repo and pushes. Then edit `README.md` and `install.sh` to wire the real username into the raw URLs, commit, and push.

## Option B — Manual via github.com

1. Go to https://github.com/new
2. Name: `grok-build-skill`, visibility: **Public**, no README/license (we already have them)
3. Click **Create repository**
4. Copy the remote URL it shows and run, from this folder:

```bash
git init -b main
git add .
git commit -m "Initial commit: grok-build skill"
git remote add origin git@github.com:<your-user>/grok-build-skill.git
git push -u origin main
```

5. Edit `README.md` and `install.sh` to swap `<YOUR_USER>` / `REPLACE_ME`, commit, push.

## Verifying it works

After pushing, the install one-liner should work for anyone:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-user>/grok-build-skill/main/install.sh | bash
```

…and in Claude Code, `/grok-build` should appear as a slash command. In a Grok TUI, the same. In Codex, the skill content is auto-loaded from `~/.codex/AGENTS.md`.

## (Optional) Make it discoverable

- Skills are auto-discovered from `~/.grok/skills/`, `~/.claude/skills/`, project `.grok/skills/`, and additional paths in `~/.grok/config.toml`.
- You can also configure marketplace sources in config if desired (see current user-guide 08-skills.md and 07-mcp-servers for details).
- Re-running the installer (or `grok inspect`) will pick up updates quickly.
