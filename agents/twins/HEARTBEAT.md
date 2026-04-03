# HEARTBEAT.md — Братья Саламанка 🪓🪓

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}}

## Checks

1. **RSS/Blog feeds** — Run `blogwatcher` check — new posts in monitored feeds since last run?
2. **Competitor monitoring** — `data/competitors.md` last update > 3 days? Run fresh research on top competitors
3. **Trend signals** — Any new viral content in niche (AI agents, OpenClaw, automation) last 24h?
4. **Research queue** — Any pending research tasks in board not started (НАДО state > 2h)?
5. **Data freshness** — Key datasets (competitor stats, market data) > 7 days old? Schedule refresh
6. **News digest** — Worth sending a digest to Хайзенберг today? Any major AI/automation news?

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT [Братья Саламанка]: [what failed]. Action: [what to do]")
```

## Schedule
Every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report failures."
