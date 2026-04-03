# HEARTBEAT.md — Хэнк Шрейдер 🔫

## Rules
- Quiet hours: 23:00-08:00 (no messages)
- All OK → reply HEARTBEAT_OK
- Problem found → message {{OWNER_NAME}} IMMEDIATELY (security issues skip quiet hours)

## Checks

1. **Open ports** — `lsof -i -P | grep LISTEN` — anything on 0.0.0.0 that shouldn't be? Gateway must be 127.0.0.1 only
2. **LaunchAgents count** — `ls ~/Library/LaunchAgents/ | wc -l` — more than etalon (29)? Unknown plist? Alert
3. **Token exposure** — `grep -r "sk-ant-\|sk-proj-" ~/.openclaw/ --include="*.json" -l | grep -v ".env"` — tokens outside .env?
4. **Docker containers** — `docker ps` — all 4 expected containers running? (searxng, n8n-local, n8n-postgres-backup, n8n-postgres-local)
5. **Sensitive file permissions** — `stat -f "%OLp" ~/.openclaw/openclaw.json ~/.openclaw/.env` — both should be 600
6. **Backup freshness** — Last backup run > 24h? Check backup LaunchAgent last run time
7. **System updates** — `softwareupdate -l` — critical updates pending? Alert if security patch available

## On failure (security)

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="🚨 SECURITY ALERT [Хэнк]: [what failed]. IMMEDIATE action: [what to do]")
```

## Security issues skip quiet hours — alert immediately

## Schedule
Every 30 minutes
Payload: "Run security heartbeat per HEARTBEAT.md. Report any failures."
