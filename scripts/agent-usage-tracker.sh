#!/bin/bash
# scripts/agent-usage-tracker.sh — Трекинг токенов по агентам
# Парсит логи gateway, считает вызовы и ошибки per agent

LOG_DIR="/tmp/openclaw"
OUTPUT="$HOME/.openclaw/logs/agent-usage.log"
TODAY=$(date '+%Y-%m-%d')

LOG_FILE="$LOG_DIR/openclaw-${TODAY}.log"
[ ! -f "$LOG_FILE" ] && exit 0

echo "=== $TODAY $(date '+%H:%M') ===" >> "$OUTPUT"

for agent in main kaizen teamlead marketing-funnel producer hank skyler copywriter; do
  calls=$(grep -c "agent:${agent}" "$LOG_FILE" 2>/dev/null)
  calls=${calls:-0}
  errors=$(grep "agent:${agent}" "$LOG_FILE" 2>/dev/null | grep -c "error\|rate.limit\|429")
  errors=${errors:-0}
  if [ "$calls" -gt 0 ]; then
    echo "  ${agent}: ${calls} calls, ${errors} errors" >> "$OUTPUT"
  fi
done

cron_runs=$(grep -c "cronRun\|cron.*start\|running cron" "$LOG_FILE" 2>/dev/null)
cron_runs=${cron_runs:-0}
echo "  crons_total: ${cron_runs}" >> "$OUTPUT"

# Alert on budget hogs (>50 calls/day)
source "$HOME/.openclaw/scripts/hank-watchdog.env" 2>/dev/null || true
TG_BOT_TOKEN="${HANK_BOT_TOKEN:-}"
ALERT_DIR="$HOME/.openclaw/logs"

for agent in main kaizen teamlead marketing-funnel producer hank skyler; do
  calls=$(grep -c "agent:${agent}" "$LOG_FILE" 2>/dev/null)
  calls=${calls:-0}
  if [ "$calls" -gt 500 ]; then
    alert_flag="${ALERT_DIR}/.budget-alert-${agent}-${TODAY}"
    if [ ! -f "$alert_flag" ] && [ -n "$TG_BOT_TOKEN" ]; then
      curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
        -d chat_id="${OWNER_TELEGRAM_ID:-}" \
        -d text="⚠️ Агент ${agent}: ${calls} вызовов за сегодня. Возможный перерасход." \
        -d parse_mode="HTML" > /dev/null 2>&1
      touch "$alert_flag"
    fi
  fi
done
