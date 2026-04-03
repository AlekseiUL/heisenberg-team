# HEARTBEAT.md — Гус Фринг 🎯

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}}

## Checks

1. **Daily goals file** — Does `goals/` have today's entry? If missing on a workday — create from weekly plan
2. **OKR progress** — Check `goals/2-monthly.md` — any metric not updated in > 3 days? Run analytics
3. **Habit tracker** — `habits/tracker.md` — today's habits logged? If evening (after 20:00) and missing — gentle reminder
4. **Kaizen dashboard** — `kaizen/dashboard.md` last updated > 24h? Refresh key metrics
5. **Weekly review** — Is it Friday? No weekly review file this week? Schedule reminder for {{OWNER_NAME}}
6. **Strat session prep** — End of month approaching (day 25+)? `strategy/strat-session-*.md` being prepped?

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT [Гус]: [what failed]. Action: [what to do]")
```

## Schedule
Every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report failures."
