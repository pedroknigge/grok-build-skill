# Prompt templates for delegated `grok -p`

## Read-only auditor (strict final report)

```
Act as a senior code reviewer for this repository.

Objective: Find real errors, likely regressions, security issues, data inconsistencies, build/test failures, or important UX bugs.

Strict rules:
- DO NOT modify any files. Read-only and safe verification commands only.
- You may run safe commands such as the project's typecheck, lint, test, build, rg, git, etc.
- Prioritize actionable findings with exact file and line.
- If a finding is an inference or you couldn't verify it directly, state that clearly.
- Ignore style nitpicks.
- Focus especially on: [critical areas].

Return a report in English with this exact format:
1. Executive summary: counts by severity (P0/P1/P2/P3).
2. Findings: severity, file:line, description, impact, concrete recommendation.
3. Commands executed and brief result.
4. Residual risks or unverified areas.

If environment hook warnings dominate, summarize what you already analyzed and emit the final report immediately.
When finished emit ONLY the report. Nothing else.
```

## Implement + prove (replaces old `--check`)

```
Implement [feature/fix] in this repo.

Rules:
- Keep changes scoped to the request.
- Run [test command] yourself after edits.
- If tests fail, fix and re-run until green or you hit a clear external blocker.
- Do not force-push or delete branches.
- Final response: summary of changes, files touched, commands + exit codes, residual risks.
```

## Plan then implement (multi-turn)

Turn 1 (new UUID session):

```
Plan the implementation of [feature]. Do not write code yet.
Output: goals, approach, file touch list, risks, test plan.
```

Turn 2 (`--resume $SID`):

```
Implement the approved plan. Stay within the file list unless blocked.
Run tests; report results.
```

## Image / video (CLI only when needed)

Prefer native host image tools when available.

```
/imagine a watercolor map of a fictional medieval city, top-down
```

```
/imagine-video a hummingbird hovering over a hibiscus, macro shot, 4s
```

## Noise-resistant heavy audit invocation

```bash
MODEL="${MODEL:-grok-4.5}"
grok -p "$AUDITOR_PROMPT" \
  --cwd "$REPO_ROOT" --model "$MODEL" \
  --output-format json \
  --always-approve --effort high --max-turns 25 \
  --disable-web-search --no-auto-update \
  2>/dev/null | jq -r '.text // empty'
```
