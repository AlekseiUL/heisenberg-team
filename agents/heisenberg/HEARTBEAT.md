# HEARTBEAT.md - Heisenberg

## Rules
- Quiet hours: 23:00–08:00 (no messages, no noise)
- All OK → reply HEARTBEAT_OK
- Problem found → message the user immediately
- Never skip a check. No check = unknown state = risk.

## Checks

1. **Team agents alive** — Verify Walter, Saul, Gus, Jesse, Hank, Skyler, Twins sessions are responsive
2. **Board status** — Check `references/team-board.md` for stuck tickets (ВЗЯЛ > 2h without ГОТОВО)
3. **Cron health** — Confirm scheduled tasks ran since last heartbeat (no missed runs)
4. **Memory hygiene** — Verify `memory/` has no stale handoff.md older than 24h
5. **Context guard** — If main session context >60%, log warning to board
6. **Error log scan** — Check `~/.openclaw/logs/` for ERROR entries since last heartbeat
7. **Pending user asks** — Any unanswered questions older than 1h → escalate

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT ALERT: [what failed]. Action needed: [what to do]")
```

## Example cron setup

Schedule: every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report any failures."
