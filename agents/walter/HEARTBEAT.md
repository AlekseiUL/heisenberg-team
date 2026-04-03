# HEARTBEAT.md — Уолтер Уайт 👨‍💻

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}}

## Checks

1. **Workspace status** — `git status` in `{{WORKSPACE_PATH}}` — uncommitted changes? Sensitive files staged?
2. **Unfinished tasks** — Check `projects/*/status.md` for last step > 2h without completion
3. **Board tasks** — Check `references/team-board.md` for tasks assigned to Walter (ВЗЯЛ state)
4. **Tool availability** — Can `product-validator` run? Can `minimax-pdf` generate? Quick smoke test
5. **Error log** — Check `~/.openclaw/logs/` for ERROR entries since last heartbeat
6. **Memory hygiene** — `memory/handoff.md` stale (> 8h on active work)? Write fresh one

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT [Уолтер]: [what failed]. Action: [what to do]")
```

## Schedule
Every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report failures."
