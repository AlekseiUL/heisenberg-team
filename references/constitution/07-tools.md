# Tools — Конституция команды "Во все тяжкие"
> Источник: references/team-constitution.md
---
## 17. Memory Hygiene Rules

### Directory Structure
- `memory/core/` — permanent facts (family, preferences, accounts). Never delete.
- `memory/decisions/` — key decisions with rationale. Never delete.
- `memory/archive/` — old data moved from MEMORY.md. Keep indefinitely.
- `memory/YYYY-MM-DD.md` — daily session diaries. Auto-created by crons or agents.
- `memory/handoff.md` — current session state for crash recovery. Overwritten each handoff.

### MEMORY.md Limits
- Keep under 3000 characters
- Move old/large sections to `memory/archive/`
- Structure: Facts → Decisions → Project → Temporary

### Rules
1. After each topic — write session digest to `memory/YYYY-MM-DD.md`
2. Before compaction — write handoff to `memory/handoff.md`
3. Skill-specific data goes to `skills/<name>/data/`, NEVER to `memory/`
4. Night cleanup cron archives old daily files (>30 days)
5. SQLite WAL mode — DO NOT CHANGE (memory-core plugin)

---

## 18. Context Management

Context management thresholds are defined per-agent in their `AGENTS.md`. See `agents/heisenberg/AGENTS.md` for the coordinator's context management rules.

General principle: when context gets heavy, delegate to subagents rather than doing everything in the main session.

---

