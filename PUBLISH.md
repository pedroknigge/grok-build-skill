# How to publish this repo

Two paths — pick whichever you prefer.

## Option A — One-liner with `gh` CLI (recommended)

Prereq: [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login` once).

From this folder (`grok-build-skill/`):

```bash
chmod +x install.sh && \
git init -b main && \
git add . && \
git commit -m "Initial commit: grok-build skill" && \
gh repo create grok-build-skill --public --source=. --remote=origin --push \
  --description "Drop-in skill teaching Claude Code, Grok, and Codex to drive the xAI Grok Build CLI in headless mode (imagine, imagine-video, coding tasks, ACP)."
```

That creates `https://github.com/<your-user>/grok-build-skill` and pushes everything.

Afterwards, edit `README.md` and `install.sh` to replace `<YOUR_USER>` / `REPLACE_ME` with your actual GitHub username, then:

```bash
git commit -am "Wire up install URLs" && git push
```

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

## (Optional) List it in the xAI Build marketplace

Per xAI's docs, marketplaces are configured in `~/.grok/config.toml`:

```toml
[[marketplace.sources]]
name  = "grok-build-skill"
url   = "https://github.com/<your-user>/grok-build-skill"
```

Users who add that block get the skill discoverable via Grok's `/plugins` UI.
