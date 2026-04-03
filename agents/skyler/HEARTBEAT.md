# HEARTBEAT.md — Скайлер Уайт 💰

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}}

## Checks

1. **Upcoming payments** — Check `memory/` for subscriptions expiring in next 3 days → remind {{OWNER_NAME}}
2. **Tribute revenue** — Run `data/tribute-report.sh` — new subscribers/cancellations since last check?
3. **Budget status** — Monthly spend vs budget on track? Check `data/budget-current.md`
4. **Crypto subscriptions** — Any manual subscribers in `projects/*/пользователи.md` expiring within 3 days?
5. **Financial data freshness** — MEMORY.md financial figures > 7 days old? Flag for update
6. **Subscription charges** — It's within 2 days of a charge date (3rd or 20th)? Pre-notify

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT [Скайлер]: [what failed]. Action: [what to do]")
```

## Schedule
Every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report failures."
