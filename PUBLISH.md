# How to publish an update

Origin already exists: [pedroknigge/grok-build-skill](https://github.com/pedroknigge/grok-build-skill). This is a **bump → checksum → push → optional tag** recipe, not a first-create bootstrap (`git init` / `gh repo create` / `<your-user>`).

Target surface for consumers: **Grok Build CLI 1.0.13+**, skill version **3.2**.

## Gate (must pass before push)

From the repo root:

```bash
./scripts/validate-skill.sh
./scripts/install-smoke.sh
./scripts/sync-check-cli.sh   # if grok on PATH
```

Do **not** publish until validate + install-smoke pass. Do **not** run `./install.sh` against real `$HOME` until origin is updated.

## Bump content

1. Edit `skills/grok-build/SKILL.md` (entrypoint) and/or `references/*` (exactly six files).
2. Keep SKILL.md slim (≤220 lines); new tables go in `references/flags-1.0.md`.
3. Bump frontmatter `version` (stay 3.x) and `last-updated`.
4. Update `CHANGELOG.md`, `README.md`, and installer banners in the same change.
5. Keep both AGY destinations documented and tested: `~/.gemini/config/skills/grok-build` and `~/.gemini/antigravity-cli/skills/grok-build`; never `~/.agy/skills`.
6. Model fallback: **`grok-4.6`**. Keep a **`grok-4.5`** mention (still available) so validators pass.
7. Do not teach `--best-of-n`, `--check`, or `--self-verify` as live `-p` flags.

## Checksums

Regenerate after any change to hashed files (`install.sh`, `SKILL.md`, `references/*`):

```bash
# from repo root
shasum -a 256 install.sh skills/grok-build/SKILL.md skills/grok-build/references/*.md > SHA256SUMS
```

`SHA256SUMS` does not cover README, CHANGELOG, PUBLISH, scripts, CI, or LICENSE — still commit those when they change.

Prefer **clone + checksum** over piping unknown scripts:

```bash
git clone https://github.com/pedroknigge/grok-build-skill.git
cd grok-build-skill
shasum -a 256 -c SHA256SUMS
./install.sh
```

Pipe-to-bash never verifies checksums of `install.sh` itself.

## Stage, commit, push

Stage **explicit paths only**. Do **not** `git add .` (that can leak `.orderfield/` and other local state). `.orderfield/` and `.grok/` are gitignored.

```bash
git add \
  skills/grok-build/SKILL.md \
  skills/grok-build/references/*.md \
  README.md CHANGELOG.md PUBLISH.md AGENTS.md install.sh \
  scripts/validate-skill.sh scripts/install-smoke.sh scripts/sync-check-cli.sh \
  SHA256SUMS .gitignore \
  docs/
git commit -m "v3.2: Add native AGY skill installation"
git push origin main
```

Public one-liner (unpinned `main`):

```bash
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/main/install.sh | bash
```

Until that push lands, the curl one-liner still serves whatever is already on `origin/main`. Use clone + `./install.sh` (or `GROK_BUILD_SKILL_ROOT`) from this tree.

## Optional tag / GitHub release

Tag-pinned consumers of **v3.1.0** will **not** move on a `main` push:

```bash
curl -fsSL https://raw.githubusercontent.com/pedroknigge/grok-build-skill/v3.1.0/install.sh | bash
```

Cut a new tag/release (deliver may use **`v3.2.0`**) so those URLs can move:

```bash
git tag v3.2.0
git push origin v3.2.0
gh release create v3.2.0 --title "v3.2.0" --notes "Skill 3.2 adds native AGY discovery and keeps the Grok Build CLI 1.0.13+ contract."
```

Keep the README public one-liner on `main`, not the tag.

## After origin is updated

Run `./install.sh` from this clone (local tree, not curl|bash) so Claude, Grok user skills, both AGY global roots, project-local `.grok/skills`, and Codex `AGENTS.md` refresh. The installer has **six** destinations; it does **not** replace `~/.codex/skills/grok-build` and never creates `~/.agy/skills`.

Verify the AGY copies after that install:

```bash
test -f ~/.gemini/config/skills/grok-build/SKILL.md
test -f ~/.gemini/antigravity-cli/skills/grok-build/SKILL.md
diff -qr skills/grok-build ~/.gemini/config/skills/grok-build
diff -qr skills/grok-build ~/.gemini/antigravity-cli/skills/grok-build
test ! -e ~/.agy/skills/grok-build
```

## Discoverability

- Grok skills are auto-discovered from `~/.grok/skills/`, project `.grok/skills/`, and additional paths in `~/.grok/config.toml`; Claude reads `~/.claude/skills/`.
- AGY discovers global skills from `~/.gemini/config/skills/`; `~/.gemini/antigravity-cli/skills/` is the CLI compatibility mirror. Both provide `/grok-build` and semantic discovery.
- Re-running the installer (or `grok inspect`) will pick up updates quickly.
