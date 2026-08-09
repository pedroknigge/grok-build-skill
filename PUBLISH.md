# How to publish this repo

Two paths — pick whichever you prefer.

## Option A — One-liner with `gh` CLI (recommended)

Prereq: [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login` once).

From this folder:

```bash
chmod +x install.sh scripts/*.sh && \
git init -b main && \
git add . && \
git commit -m "Initial commit: grok-build skill 3.0 (CLI 1.0)" && \
gh repo create grok-build-skill --public --source=. --remote=origin --push \
  --description "Drop-in skill teaching agents to drive the xAI Grok Build CLI 1.0 headless mode (plus native Grok tool guidance)."
```

This creates the repo and pushes. Then edit `README.md` and `install.sh` to wire the real username into the raw URLs if needed, commit, and push.

## Option B — Manual via github.com

1. Go to https://github.com/new
2. Name: `grok-build-skill`, visibility: **Public**, no README/license (we already have them)
3. Click **Create repository**
4. Copy the remote URL it shows and run, from this folder:

```bash
git init -b main
git add .
git commit -m "Initial commit: grok-build skill 3.0 (CLI 1.0)"
git remote add origin git@github.com:<your-user>/grok-build-skill.git
git push -u origin main
```

5. Edit `README.md` and `install.sh` to swap `<YOUR_USER>` / `REPLACE_ME` if needed, commit, push.

## Verifying it works

After pushing, the install one-liner should work for anyone:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-user>/grok-build-skill/main/install.sh | bash
```

Prefer clone + checksum for audit:

```bash
git clone https://github.com/<your-user>/grok-build-skill.git
cd grok-build-skill
shasum -a 256 -c SHA256SUMS
./install.sh
```

…and in Claude Code, `/grok-build` should appear. In a Grok TUI, the same. In Codex, the skill content is auto-loaded from `~/.codex/AGENTS.md`.

Before release, run:

```bash
./scripts/validate-skill.sh
./scripts/install-smoke.sh
./scripts/sync-check-cli.sh   # if grok on PATH
```

Regenerate checksums after content changes:

```bash
# from repo root
shasum -a 256 install.sh skills/grok-build/SKILL.md skills/grok-build/references/*.md > SHA256SUMS
```

**Shipping v3.0 remotely:** local tree completeness is not enough for the curl one-liner. Commit and push `skills/grok-build/references/`, `SHA256SUMS`, `.github/workflows/ci.yml`, updated scripts, and `install.sh`, then re-verify:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/grok-build-skill/main/install.sh | bash
# and from a clean clone:
shasum -a 256 -c SHA256SUMS
```

Until that push lands, prefer `git clone` + `./install.sh` (or `GROK_BUILD_SKILL_ROOT`).

## (Optional) Make it discoverable

- Skills are auto-discovered from `~/.grok/skills/`, `~/.claude/skills/`, project `.grok/skills/`, and additional paths in `~/.grok/config.toml`.
- Re-running the installer (or `grok inspect`) will pick up updates quickly.
- Target surface for consumers: **Grok Build CLI 1.0.0+**, skill version **3.0**.
