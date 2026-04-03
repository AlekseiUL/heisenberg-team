# HEARTBEAT.md — Сол Гудман 💼

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}}

## Checks

1. **Pipeline health** — Check `references/team-board.md` for tickets stuck in ВЗЯЛ > 2h without ГОТОВО
2. **ОТК queue** — Any deliverables waiting for quality check > 1h? Escalate to Walter or deliver
3. **Stuck projects** — Check `projects/*/status.md` for last update > 24h on active projects
4. **Pending deliveries** — Any ГОТОВО tickets not yet delivered to user? Deliver or alert
5. **Agent coordination** — Any pending sessions_send responses from Walter/Jesse/Skyler older than 30min?
6. **Handoff freshness** — `memory/handoff.md` older than 12h on active project? Warn

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT [Сол]: [what failed]. Action: [what to do]")
```

## Schedule
Every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report failures."
