#!/bin/bash
# Compaction Watchdog — если compaction падает 2+ раз, делает /reset
# Проверяет gateway.err.log на свежие ошибки compaction/401

LOG="$HOME/.openclaw/logs/gateway.err.log"
STATE="$HOME/.openclaw/logs/compaction-watchdog.state"
THRESHOLD=2

# Ошибки за последний час
RECENT_ERRORS=$(grep "$(date -v-1H '+%Y-%m-%dT%H')\|$(date '+%Y-%m-%dT%H')" "$LOG" 2>/dev/null | \
  grep -c "compaction.*fail\|summariz.*fail\|context overflow\|prompt too large" || echo 0)

# 401 ошибки за последний час  
AUTH_ERRORS=$(grep "$(date -v-1H '+%Y-%m-%dT%H')\|$(date '+%Y-%m-%dT%H')" "$LOG" 2>/dev/null | \
  grep -c "401.*bearer\|Invalid bearer" || echo 0)

echo "$(date '+%Y-%m-%d %H:%M') compaction_errors=$RECENT_ERRORS auth_errors=$AUTH_ERRORS" >> "$STATE"

if [ "$RECENT_ERRORS" -ge "$THRESHOLD" ] || [ "$AUTH_ERRORS" -ge 5 ]; then
  echo "ALERT: compaction=$RECENT_ERRORS auth=$AUTH_ERRORS"
  exit 1
else
  echo "OK: compaction=$RECENT_ERRORS auth=$AUTH_ERRORS"
  exit 0
fi
