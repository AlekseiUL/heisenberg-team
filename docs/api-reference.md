# API Reference

This document covers the tools and APIs available to agents in Heisenberg Team.

## Table of Contents

- [Agent Communication](#agent-communication)
- [Messaging](#messaging)
- [Memory Operations](#memory-operations)
- [File Operations](#file-operations)
- [Script Utilities](#script-utilities)
- [Session Keys Reference](#session-keys-reference)

---

## Agent Communication

### `sessions_send`

Send a message to another agent and wait for a reply.

```
sessions_send(
  sessionKey="agent:<name>:main",
  message="<task description>",
  timeoutSeconds=120
)
```

**Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sessionKey` | string | ✅ | Target agent session key (format: `agent:<name>:main`) |
| `message` | string | ✅ | Task description or wake-up message (keep to 1 line for wake-up calls) |
| `timeoutSeconds` | number | ✅ | Max wait time in seconds. Default: `120`. Use `300` for long tasks (e.g. PDF generation). |

**Returns**

The agent's reply as a string.

**Behavior**

- If the agent does not respond within `timeoutSeconds`, the call returns a timeout error.
- `sessions_send` is a **synchronous ping-pong** — the calling agent blocks until a reply arrives or timeout occurs.
- For Board-First tasks, the message is typically a one-liner: `"Задача на board, briefing в projects/X/briefing.md"`. The actual task lives in the briefing file.

**Timeout thresholds** (see `configs/thresholds.yaml`):

| Setting | Value | Notes |
|---------|-------|-------|
| Standard session timeout | 120 s | Default for most agent calls |
| Long-running tasks | 300 s | PDF, code generation, research |
| Max silence before escalation | 60 s | Alert threshold |
| Escalation trigger | 120 s | Auto-escalate to Heisenberg |

**Example — delegating to Walter**

```
sessions_send(
  sessionKey="agent:teamlead:main",
  message="Task on board. Briefing: projects/landing-v2/briefing.md",
  timeoutSeconds=300
)
```

> **Note:** Agent messages are typically in the user's language (Russian by default in this template). The above shows the English equivalent. The actual content of `message` can be in any language.

**Example — requesting research from Twins**

```
sessions_send(
  sessionKey="agent:researcher:main",
  message="Task: competitor research. Briefing: projects/competitor-analysis/briefing.md",
  timeoutSeconds=120
)
```

---

## Messaging

### `message`

Send a Telegram (or other platform) message directly to the user.

```
message(
  action=send,
  channel=telegram,
  to={{OWNER_TELEGRAM_ID}},
  message="<text>"
)
```

**Parameters**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `action` | `send` | Send a message |
| `channel` | `telegram` | Messaging platform |
| `to` | `{{OWNER_TELEGRAM_ID}}` | Recipient user ID (numeric) |
| `message` | string | Message body |

**When to use**

All agents **must** send a message in two situations:

1. **On task receipt** (first tool call, before any work):
   ```
   message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="Принял задачу — [что делаю]")
   ```

2. **On task completion** (after updating the board):
   ```
   message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="Готово — [что сделал]. Передал дальше.")
   ```

Failure to send these messages means the task is considered **not done**. Silence for more than 60 seconds is a protocol violation.

---

## Memory Operations

### `memory_search`

Search agent memory using semantic (vector) or keyword (BM25) search.

```
memory_search(query="<search terms>", limit=10)
```

**Parameters**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | — | Natural language search query |
| `limit` | number | 10 | Maximum number of results to return |
| `namespace` | string | `default` | Memory namespace to search in |

**Returns**

Array of memory entries, each with:
- `key` — unique memory identifier
- `value` — stored content
- `score` — relevance score (higher = more relevant)
- `created_at` — timestamp

**Search modes**

OpenClaw memory supports two search modes:

| Mode | Requirement | Accuracy |
|------|-------------|----------|
| Vector (semantic) | OpenAI embeddings configured | High — finds related concepts |
| BM25 (keyword) | No extra config | Medium — exact keyword matches |

To enable vector search, set `OPENAI_API_KEY` in `.env` (see `docs/environment-variables.md`).

**Example**

```
memory_search(query="клиент предпочитает короткие тексты", limit=5)
```

### `memory_store`

Store a value in agent memory.

```
memory_store(key="<key>", value="<content>", namespace="<ns>")
```

**Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | string | ✅ | Unique identifier for this memory |
| `value` | string | ✅ | Content to store |
| `namespace` | string | ❌ | Logical group (default: `default`) |
| `ttl` | number | ❌ | Time-to-live in seconds (omit for permanent) |

### `memory_retrieve`

Get a specific memory entry by key.

```
memory_retrieve(key="<key>", namespace="<ns>")
```

### Memory Files vs. Database

Agents use two types of persistent memory:

| Type | Location | Use case |
|------|----------|----------|
| SQLite DB | `~/.openclaw/agents/<name>/memory.db` | Searchable facts, lessons, task history |
| Markdown files | `agents/<name>/MEMORY.md`, `agents/<name>/memory/` | Structured notes, handoff state |

**Core memory files per agent:**

| File | Contents |
|------|----------|
| `MEMORY.md` | Persistent facts, key context, client data |
| `memory/handoff.md` | State for recovery after context compaction |
| `memory/YYYY-MM-DD.md` | Session digests |
| `.learnings/LEARNINGS.md` | Accumulated behavioral lessons |
| `.learnings/ERRORS.md` | Error patterns and recovery notes |

---

## File Operations

### Reading Files

```
read(path="references/team-board.md")
read(path="projects/my-project/briefing.md")
```

**Best practices:**
- Always use `offset` and `limit` for large files to avoid loading >100 lines into context
- Read `references/team-constitution.md` first — it's the authority document
- Do **not** re-read files already in context

### Writing Files

```
write(path="projects/my-project/result.md", content="...")
```

### Creating DONE.md (task completion signal)

When a project is fully complete, create `DONE.md` in the project folder. This triggers the auto-notification hook:

```
write(path="projects/my-project/DONE.md", content="""
# DONE
- Агент: walter
- Задача: создать лендинг
- Результат: projects/my-project/result/index.html
- Статус: готово
""")
```

This file triggers `fswatch` → webhook → user notification in ~10 seconds.

---

## Script Utilities

Key scripts available in `scripts/`:

| Script | Command | Purpose |
|--------|---------|---------|
| `trash-agent-session.sh` | `bash scripts/trash-agent-session.sh <agent>` | Reset agent session (run before new tasks) |
| `setup-wizard.sh` | `bash scripts/setup-wizard.sh` | Interactive initial setup |
| `setup.sh` | `bash scripts/setup.sh` | Non-interactive setup |
| `start-team.sh` | `bash scripts/start-team.sh` | Start OpenClaw gateway |
| `stop-team.sh` | `bash scripts/stop-team.sh` | Stop OpenClaw gateway |
| `deploy-team.sh` | `bash scripts/deploy-team.sh` | Full multi-agent deployment |
| `init-workspace.sh` | `bash scripts/init-workspace.sh` | Create workspace directories |
| `agent-health-check.sh` | `bash scripts/agent-health-check.sh` | Run agent health checks |
| `memory-hygiene.sh` | `bash scripts/memory-hygiene.sh` | Clean and compact agent memory |
| `rotate-logs.sh` | `bash scripts/rotate-logs.sh` | Rotate log files |
| `git-backup.sh` | `bash scripts/git-backup.sh` | Commit and push workspace state |

**Before starting any new task — always reset the target agent's session:**

```bash
bash scripts/trash-agent-session.sh walter
sleep 5
# now send sessions_send to walter
```

A heavy session is the #1 cause of timeouts. `trash-agent-session.sh` prevents this.

---

## Session Keys Reference

Each agent has a fixed session key used in `sessions_send`:

| Agent | Character | Session Key |
|-------|-----------|-------------|
| Heisenberg | Walter White (Boss) | `agent:main:main` |
| Saul | Saul Goodman (Coordinator) | `agent:producer:main` |
| Walter | Walter White (Tech Lead) | `agent:teamlead:main` |
| Jesse | Jesse Pinkman (Marketing) | `agent:marketing-funnel:main` |
| Skyler | Skyler White (Finance) | `agent:skyler:main` |
| Hank | Hank Schrader (Security) | `agent:hank:main` |
| Gus | Gus Fring (Kaizen) | `agent:kaizen:main` |
| Twins | Salamanca Twins (Research) | `agent:researcher:main` |

**Config file mapping** (in `configs/`):

| Config File | Session Key | Model Tier |
|-------------|-------------|------------|
| `heisenberg.openclaw.json.example` | `agent:main:main` | MAIN_MODEL (Opus) |
| `saul.openclaw.json.example` | `agent:producer:main` | COORDINATOR_MODEL |
| `walter.openclaw.json.example` | `agent:teamlead:main` | TECH_MODEL (Sonnet) |
| `jesse.openclaw.json.example` | `agent:marketing-funnel:main` | WORKER_MODEL |
| `skyler.openclaw.json.example` | `agent:skyler:main` | WORKER_MODEL |
| `hank.openclaw.json.example` | `agent:hank:main` | WORKER_MODEL |
| `gus.openclaw.json.example` | `agent:kaizen:main` | WORKER_MODEL |
| `twins.openclaw.json.example` | `agent:researcher:main` | WORKER_MODEL |

---

## Skill Invocation

Skills are instruction files in `skills/<name>/SKILL.md`. Agents load skills by reading the file directly:

```
read(path="skills/copywriter/SKILL.md")
```

There is no formal skill registry or invocation API. The agent reads the skill file and follows its instructions.

**Skill matching** — agents select skills by scanning skill descriptions against the task. The description field in the skill's YAML frontmatter (or first paragraph) is used for matching.

**Full skills index:** [`skills/README.md`](../skills/README.md)

---

## Error Handling

### Retry policy (from `configs/thresholds.yaml`)

| Error type | Max retries |
|------------|-------------|
| Tool error | 1 |
| Provider error | 2 |
| Network error | 2 |
| Lock error | 1 |

### Escalation ladder

1. Retry up to the limit
2. If still failing — log the error, notify the user
3. Escalate to Heisenberg via `sessions_send(sessionKey="agent:main:main", ...)`
4. Never retry silently — loud failure beats silent retry

### Common patterns

```
# Pattern: session timeout → reset first, then retry
bash scripts/trash-agent-session.sh <agent>
sleep 5
sessions_send(sessionKey="agent:<name>:main", message="...", timeoutSeconds=300)

# Pattern: task not completing → check board status
read(path="references/team-board.md")
```

---

## Related Documentation

- [Architecture](architecture.md) — communication model and agent roles
- [Environment Variables](environment-variables.md) — configuration reference
- [Troubleshooting](troubleshooting.md) — common issues and fixes
- [Team Constitution](../references/team-constitution.md) — authoritative protocol document
- [configs/thresholds.yaml](../configs/thresholds.yaml) — all numeric limits in one place
