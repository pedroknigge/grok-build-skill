# Documentation claims audit

> Hub: [AGENTS.md](../../AGENTS.md)  
> **Code is source of truth.** Docs do not override implementation.  
> **Living claims v0:** anchors + severity.

**Date:** 2026-08-30  
**Scope:** project  
**Intent:** audit → selective patch  
**Out:** root  
**Auditor:** documentation-manager  
**CLI evidence:** `grok 1.0.13 (5e9a58528b76)`; `grok models` default `grok-4.6`, `grok-4.5` listed

## Summary

| Verdict | Count |
|---------|------:|
| OK | 32 |
| Partial | 0 |
| Missing | 0 |
| Contradicted | 0 |
| Unverifiable | 3 |

| Severity | Count |
|----------|------:|
| critical | 15 |
| normal | 20 |

**Truth score (advisory):** `(32*100 + 0*50) / 35` ≈ **91.4** (Unverifiable counted in TOTAL_V)  
**CI gate:** this repo has **no** `scripts/audit-claims.sh`. Gate here is `validate-skill.sh` + smoke + checksums. No **critical Contradicted**.

**Top risks (pre-patch, now fixed in-tree):**  
1. README compatibility table omitted project-local dest — **patched**.  
2. `--no-auto-update` live-but-hidden was not in the flags-1.0 omitted-from-help list — **patched**.  
3. No AGENTS.md / `docs/` hub — **created**.

**Recommended next Intent:** none (docs now match this tree). Re-audit when CLI version changes.

## Code inventory (high level)

| Kind | Evidence (paths / symbols) | Notes |
|------|----------------------------|-------|
| Packages / apps | none | No `package.json` / `pyproject.toml` / `go.mod` |
| Entry / CLI | `install.sh`; `scripts/*.sh` | POSIX bash |
| Feature modules | `skills/grok-build/SKILL.md`; `references/` | Product is Markdown |
| HTTP / API | none | Do not invent routes |
| UI surfaces | none | |
| Data layer | none | |
| Jobs / workers | `.github/workflows/ci.yml` | validate + checksum + smoke + optional sync |
| Tests | `scripts/validate-skill.sh`, `install-smoke.sh`, `sync-check-cli.sh` | No `*_test.go` / pytest |
| External runtime | user `grok` binary 1.0.13+ | Documented, not vendored |

## Claims matrix

| ID | Claim (quote or paraphrase) | Source doc | Code evidence | Anchor path | Anchor symbol | Anchor hash | Severity | Verdict | Action |
|----|----------------------------|------------|---------------|-------------|---------------|-------------|----------|---------|--------|
| C-001 | Skill metadata version is 3.x / 3.1 | SKILL.md frontmatter | `version: "3.1"` | `skills/grok-build/SKILL.md` | `metadata.version` | | critical | OK | keep |
| C-002 | Entrypoint ≤220 lines | README / PUBLISH | `wc -l` → 214 | `skills/grok-build/SKILL.md` | | | normal | OK | keep |
| C-003 | Exactly six reference files with those names | README, install.sh | `REFERENCE_FILES` + dir listing | `install.sh` | `REFERENCE_FILES` | | critical | OK | keep |
| C-004 | Target surface Grok Build CLI 1.0.13+ | SKILL.md, README | frontmatter focus; live `grok 1.0.13` | `skills/grok-build/SKILL.md` | | | critical | OK | keep |
| C-005 | Default / fallback model `grok-4.6`; `grok-4.5` still available | SKILL.md | `grok models` lists both; default 4.6 | `skills/grok-build/SKILL.md` | | | critical | OK | keep |
| C-006 | Dead `-p` flags: `--best-of-n`, `--self-verify`; `--check` only `grok update --check` | SKILL.md, flags-1.0.md | not in `grok --help`; `grok update --help` has `--check` | `skills/grok-build/references/flags-1.0.md` | | | critical | OK | keep |
| C-007 | Headless (`-p`) does not create a worktree from `--worktree` | SKILL.md | `grok --help` worktree text | `skills/grok-build/SKILL.md` | | | critical | OK | keep |
| C-008 | Four output formats including `streaming-messages-json` + `--include-partial-messages` | SKILL.md, output-formats.md | `grok --help` | `skills/grok-build/references/output-formats.md` | | | critical | OK | keep |
| C-009 | `--load` is alias of `--resume` | SKILL.md, sessions-and-resume.md | zsh completions `--load` alias | `skills/grok-build/references/sessions-and-resume.md` | | | normal | OK | keep |
| C-010 | `-s/--session-id` creates UUID sessions; nicknames fail | SKILL.md | `grok --help` session-id text; validator bans nicknames | `skills/grok-build/SKILL.md` | | | critical | OK | keep |
| C-011 | `--restore-code` requires `--resume`; remote needs `--worktree` | SKILL.md | `grok --help` restore-code text | `skills/grok-build/SKILL.md` | | | critical | OK | keep |
| C-012 | Permission modes: default, acceptEdits, auto, dontAsk, bypassPermissions, plan | flags-1.0.md | `grok --help` | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |
| C-013 | `grok login --device-auth` alias `--device-code` | SKILL.md | `grok login --help` | `skills/grok-build/SKILL.md` | | | normal | OK | keep |
| C-014 | Installer has four destinations; not `~/.codex/skills/grok-build` | PUBLISH.md, install.sh | four blocks in `install.sh`; no codex/skills path | `install.sh` | | | critical | OK | keep |
| C-015 | Project-local dest when `.git` or `.grok/config.toml` | install.sh | condition at project-local block | `install.sh` | | | normal | OK | keep (README patched) |
| C-016 | `curl \| bash` uses `REPO_RAW`, not CWD as skill root | README, install.sh | `resolve_skill_root` | `install.sh` | `resolve_skill_root` | | critical | OK | keep |
| C-017 | Hard-fail if shipped reference missing/empty | README, install.sh | `require_references` | `install.sh` | `require_references` | | critical | OK | keep |
| C-018 | Codex block BEGIN/END; idempotent replace | README, install.sh | `strip_block` + markers; smoke asserts count=1 | `install.sh` | `BEGIN_MARKER` | | critical | OK | keep |
| C-019 | Smoke always uses FAKE_HOME | README, install-smoke.sh | `export HOME="$FAKE_HOME"` | `scripts/install-smoke.sh` | `FAKE_HOME` | | critical | OK | keep |
| C-020 | `SHA256SUMS` covers install.sh + SKILL.md + six refs only | PUBLISH.md | file contents; `shasum -c` OK | `SHA256SUMS` | | | critical | OK | keep |
| C-021 | CI runs validate, checksum, smoke, optional sync | README | `.github/workflows/ci.yml` | `.github/workflows/ci.yml` | | | normal | OK | keep |
| C-022 | `sync-check-cli.sh` skips if grok missing | README | early `exit 0` | `scripts/sync-check-cli.sh` | | | normal | OK | keep |
| C-023 | Validator requires grok-4.6 and grok-4.5 mentions | CHANGELOG, validate-skill.sh | `REQUIRED_CONCEPTS` | `scripts/validate-skill.sh` | | | normal | OK | keep |
| C-024 | Hidden-from-`--help` flags still live in completions | flags-1.0.md | `~/.grok/completions/` lists them | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep (`--no-auto-update` added to list) |
| C-025 | Effort canonical list includes `xhigh`; grok-4.6 extra `xhigh` | flags-1.0.md | user-guide 14-headless-mode.md | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |
| C-026 | MCP: list/enable/disable/doctor; add auto-http for bare URLs | SKILL.md, flags-1.0.md | `grok mcp --help`; `mcp add --help` transport http default on URL | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |
| C-027 | Sessions CLI: list/search/delete; export Markdown + `-c` | flags-1.0.md | `grok sessions --help`; `grok export --help` | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |
| C-028 | `grok memory clear` with `--workspace` / `--global` / `--all` / `-y` | flags-1.0.md | `grok memory clear --help` | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |
| C-029 | `.orderfield/` and `.grok/` gitignored | CHANGELOG, PUBLISH | `.gitignore` | `.gitignore` | | | normal | OK | keep |
| C-030 | MIT license | README | `LICENSE` | `LICENSE` | | | normal | OK | keep |
| C-031 | `stopReason` snake_case (`end_turn`) in JSON | SKILL.md, output-formats.md | user-guide / skill contract; no in-repo fixture JSON | `skills/grok-build/references/output-formats.md` | | | normal | Unverifiable | keep (matches live docs; no captured JSON in this repo) |
| C-032 | SIGINT 130 / SIGTERM 143 | SKILL.md, sessions-and-resume.md | documented in skill; not executed this audit | `skills/grok-build/references/sessions-and-resume.md` | | | normal | Unverifiable | keep |
| C-033 | `grok clone` Grove lazy-clone; gated Grove config; depth-1 default | flags-1.0.md | `grok clone --help` confirms flags; Grove gate not executed | `skills/grok-build/references/flags-1.0.md` | | | normal | Unverifiable | keep (help OK; gate Unverifiable) |
| C-034 | Worktree cleanup recipes are list/rm/gc; salvage / clean-artifacts / db exist and are not recipes | flags-1.0.md | `grok worktree --help` | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |
| C-035 | `--tools` / `--max-turns` / `--agents` are headless-only (user-guide); default `--help` omits that label | flags-1.0.md | user-guide 14-headless-mode.md; flags table notes help omission | `skills/grok-build/references/flags-1.0.md` | | | normal | OK | keep |

### Living-claims columns

| Column | Maps to | Notes |
|--------|---------|-------|
| Anchor path | `anchor.path` | Repo-relative |
| Anchor symbol | `anchor.symbol` | Optional |
| Anchor hash | `anchor.hash` | Unused this pass |
| Severity | `severity` | `critical` \| `normal` |

**Truth score (advisory)** vs CI: score is not a merge gate. This package’s merge gate is `validate-skill.sh` + smoke + `SHA256SUMS`.

## Session patches (integrate follow-on)

- README: four dest + project-local trigger + Codex non-dest
- `references/flags-1.0.md`: `--no-auto-update` in omitted-from-help list
- Created `AGENTS.md` + `docs/**` from code
- PUBLISH.md stage list includes `AGENTS.md` and `docs/`
- CHANGELOG v3.1 docs-audit note

**Non-writes:** `LICENSE`; `SKILL.md` body (contract already OK); historical CHANGELOG entries before v3.1; `install.sh` / scripts logic.

## Follow-on plan

- [x] Patch Contradicted/Partial consumer docs (no Contradicted; README/flags Partial patched)
- [x] Add coverage matrix on hub
- [ ] Optional: offer knowledge dashboard (not generated; Markdown is SSOT)
- [ ] Wire `audit-claims.sh` only if this repo wants docs CI (not present; skip)

## Related

- Status taxonomy used on feature rows: Real / Deprecated (Codex skills dir is not a dest)
- Living claims procedure applied; dashboard score advisory
