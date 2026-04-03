# Healthcheck Skill

## Description
Host security hardening and system health checks for OpenClaw deployments.

## Triggers
- "security audit", "check security", "healthcheck", "system health"
- "check ports", "check firewall", "vulnerability scan"
- "security patrol", "аудит безопасности", "проверь безопасность"

## Instructions

### Quick Health Check
1. Run `openclaw doctor` — check for errors
2. Check open ports: `lsof -i -P | grep LISTEN`
3. Verify gateway binds to 127.0.0.1 (not 0.0.0.0)
4. Check disk space: `df -h`
5. Check memory: `vm_stat` (macOS) or `free -m` (Linux)

### Security Audit

1. **Ports:** `lsof -i -P | grep LISTEN` — flag anything on 0.0.0.0
2. **Tokens:** `grep -r "sk-ant-\|sk-proj-\|AAEO" ~/.openclaw/ --include="*.json" -l | grep -v ".env"` — tokens should only be in .env
3. **SSH:** Check `~/.ssh/authorized_keys` for unknown keys
4. **Updates:** `softwareupdate -l` (macOS) or `apt list --upgradable` (Linux)
5. **Git:** `git status` in workspace — uncommitted sensitive files?
6. **Firewall:** macOS: `defaults read /Library/Preferences/com.apple.alf globalstate`; Linux: `ufw status`
7. **LaunchAgents:** `ls ~/Library/LaunchAgents/` — compare count to etalon in MEMORY.md, flag unknown plist files
8. **File permissions:** `stat -f "%OLp" ~/.openclaw/openclaw.json ~/.openclaw/.env` — both must be 600
9. **Docker:** `docker ps` — expected containers running?

### Report Format
```
## Security Report — YYYY-MM-DD
- Ports: ✅/❌ [details]
- Tokens: ✅/❌
- SSH: ✅/❌
- Updates: ✅/❌
- Git: ✅/❌
- Firewall: ✅/❌
- LaunchAgents: ✅/❌ [count vs etalon]
- File permissions: ✅/❌
- Docker: ✅/❌
- Overall: PASS / FAIL
```

### On FAIL
```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}},
  message="🚨 SECURITY REPORT FAIL:\n[items that failed]\nAction needed: [what to do]")
```
