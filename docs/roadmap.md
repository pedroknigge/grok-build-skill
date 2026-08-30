# Roadmap

> Hub: [AGENTS.md](../AGENTS.md)

**Last updated:** 2026-08-30

This is a **tracking skill**, not a product with release trains. The work is: stay honest against the live `grok` CLI.

## Now (shipped)

- Skill **3.2** / CLI **1.0.13+**
- Default model **`grok-4.6`**; **`grok-4.5`** still documented
- Dead quality flags removed from recipes
- Six installer destinations, including both AGY global roots; Codex remains embed-only
- Validate + FAKE_HOME smoke + optional `sync-check-cli.sh`

## Next (when CLI moves)

- Re-run `./scripts/sync-check-cli.sh` against a newer `grok --version`
- If `--help` or completions add/remove headless flags, update `references/flags-1.0.md` first, then the slim entrypoint if the contract changed
- Bump frontmatter `version` / `last-updated`, `CHANGELOG.md`, installer banners, `SHA256SUMS`
- Follow [PUBLISH.md](../PUBLISH.md) (checksum → push → optional tag). Tag-pinned `v3.1.0` URLs do not move until a new tag

## Not planned

- A directory copy at `~/.codex/skills/grok-build`
- Teaching `--best-of-n` / `--check` / `--self-verify` as `-p` flags
- Replacing MkDocs/Docusaurus (none in this repo)
- `docs/team/` owners (not requested; no CODEOWNERS engine)
