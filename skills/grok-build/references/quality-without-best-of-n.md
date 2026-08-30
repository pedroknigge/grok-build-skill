# Quality without `--best-of-n` / `--check`

CLI 1.0 **removed** `--best-of-n`, `--check`, and `--self-verify`. Passing them errors. `--check` is only `grok update --check`.

Use host-side and native patterns instead.

## 1. Host multi-run

Run the same prompt N times (or with varied seeds/rules), keep artifacts, pick the best:

```bash
MODEL="${MODEL:-grok-4.6}"
PROMPT="Fix the failing unit tests for module X and summarize changes."
for i in 1 2 3; do
  grok -p "$PROMPT" \
    --cwd "$REPO" --model "$MODEL" \
    --output-format json --always-approve --no-auto-update \
    2>/dev/null | jq -r '.text // empty' > "/tmp/grok-run-$i.md"
done
# Host agent: diff candidates, choose best, apply only the winner's edits
```

## 2. Host verification is mandatory

After any coding delegation:

```bash
# Examples — use the project's real scripts
npm test
npm run typecheck
npm run lint
cargo test
pytest -q
```

The delegated agent may claim success; **only host commands prove it**.

## 3. Native subagents (when host is Grok)

Prefer parallel native explore/plan/general-purpose subagents over shelling out N times when the host already has subagent primitives. Aggregate findings with `todo_write` and host tests.

## 4. Put verification inside the prompt

Without `--check`, write the loop into the prompt text:

```
Implement the fix. Then run the project's test command yourself.
If tests fail, fix and re-run until green or you hit a clear blocker.
In the final report include: commands run, exit codes, and remaining failures.
```

## 5. Constrained tools + max turns

Reduce flaky broad exploration:

```bash
grok -p "$PROMPT" \
  --cwd "$REPO" --model "$MODEL" \
  --output-format json \
  --allow 'Read' --allow 'Grep' --allow 'Bash(npm test*)' \
  --deny 'Bash(rm -rf *)' \
  --max-turns 25 \
  --always-approve --no-auto-update \
  2>/dev/null | jq -r '.text // empty'
```

## 6. Structured acceptance criteria

```bash
grok -p "Return JSON only: {\"ok\":bool,\"summary\":string,\"tests_run\":[string]}" \
  --json-schema '{"type":"object","required":["ok","summary"],"properties":{"ok":{"type":"boolean"},"summary":{"type":"string"},"tests_run":{"type":"array","items":{"type":"string"}}}}' \
  --always-approve --no-auto-update
```

Host rejects `ok: false` or missing fields.

## Anti-patterns

- Teaching or copying `--best-of-n` / `--check` / `--self-verify`
- Trusting final text without host tests
- Assuming `-p --worktree` isolates edits (it does not create a worktree)
