# HEARTBEAT.md — Джесси Пинкман 🎯

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}}

## Checks

1. **Analytics freshness** — Last YouTube stats update > 24h? Run `python3 skills/analytics/scripts/yt-stats.py` to refresh
2. **Telegram channel** — Last channel-analyzer run > 48h? Check for viral posts to swipe
3. **Content plan** — Is `data/content-plan.md` current? Any planned posts overdue?
4. **Scheduled posts** — Any posts scheduled for today not yet published?
5. **Competitor monitoring** — `data/competitors.md` last updated > 7 days? Run fresh research
6. **ERR trend** — ERR dropping vs last week? Flag if down >5% — needs attention

## On failure

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="⚠️ HEARTBEAT [Джесси]: [what failed]. Action: [what to do]")
```

## Schedule
Every 30 minutes (quiet hours excluded)
Payload: "Run heartbeat checks per HEARTBEAT.md. Report failures."
