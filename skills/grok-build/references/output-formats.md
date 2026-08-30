# Output formats (CLI 1.0.13)

Four headless formats plus optional partials:

| Format | Description |
|--------|-------------|
| `plain` | Human-readable final text (default) |
| `json` | Single JSON object after the run completes |
| `streaming-json` | NDJSON of agent-native ACP-style session updates |
| `streaming-messages-json` | NDJSON in Anthropic Messages API wire format |

## `--include-partial-messages`

- Only affects `--output-format streaming-messages-json`.
- Emits incremental `stream_event` lines (text/thinking deltas) alongside whole messages.
- Other formats: ignored (may warn).

## `json` object (common fields)

Typical final object fields:

| Field | Meaning |
|-------|---------|
| `text` | Final assistant text (what most hosts want) |
| `stopReason` | **snake_case** stop reason, e.g. `end_turn` (not PascalCase `EndTurn`) |
| `sessionId` | Session UUID for `--resume` |
| `requestId` | Request correlation id |
| `num_turns` | Main-agent model rounds |
| `usage` | Token totals for the prompt (includes finished subagents when applied) |
| `modelUsage` | Per-model breakdown + optional `costUSD` (key is the model id, e.g. **`grok-4.6`**) |
| `total_cost_usd` | Complete USD cost when fully stamped |
| `total_cost_usd_ticks` | Integer ticks (1 USD = 10^10 ticks) |

### Token field policy

- `usage.input_tokens` / `modelUsage.*.inputTokens` are **uncached only**.
- `cache_read_input_tokens` / `cacheReadInputTokens` are cache hits.
- `cache_creation_input_tokens` / `cacheCreationInputTokens` are cache writes (often 0).
- Practical total: `input_tokens + cache_read_input_tokens + cache_creation_input_tokens + output_tokens`.

### Partial / incomplete spend

- `total_cost_usd` may be **absent** (OAuth/pool paths often omit cost). Absence = unreported, **not free**.
- When some calls lacked cost, `cost_is_partial` is true and cost floats may be omitted.
- When subagent usage could not be applied or drain timed out, `usage_is_incomplete` may be true and cost floats omitted the same way.

### Extraction

```bash
... --output-format json 2>/dev/null | jq -r '.text // empty'
... | jq '{sessionId, num_turns, stopReason, total_cost_usd, usage}'

SID=$(... | jq -r '.sessionId')
# Noisy multi-object streams: last object fallback
... 2>/dev/null | jq -s 'last | .text // empty'
```

## `streaming-json`

NDJSON events (`text`, `thought`, `end`, `error`, plus others like `max_turns_reached`). Includes tool calls, results, and usage. Spend fields land on the final `end` event. `stopReason` on stream events is snake_case.

```bash
... --output-format streaming-json 2>/dev/null | \
  jq -c 'select(.type == "end" or .type == "final_assistant_message")' | tail -1
```

## `streaming-messages-json`

Messages API-compatible stream-json. Carries assistant/user message bodies, tool_use/tool_result, usage, `stop_reason`, and optional partial framing via `--include-partial-messages`.

```bash
grok -p "..." --output-format streaming-messages-json \
  --include-partial-messages --always-approve --no-auto-update
```

Final `result` (success) typically includes `result` text, `stop_reason`, `num_turns`, `total_cost_usd`, `usage`, `session_id`.

## Noise

Even with JSON formats, hooks/plugins may spam **stderr**. Prefer:

```bash
... 2>/dev/null | jq -r '.text // empty'
```

There is no `--quiet` flag.
