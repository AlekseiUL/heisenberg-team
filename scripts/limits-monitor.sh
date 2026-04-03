#!/bin/bash
md5sum() { python3 -c "import hashlib,sys; print(hashlib.md5(open(sys.argv[1],'rb').read()).hexdigest())" "$@"; }
# scripts/limits-monitor.sh — Мониторинг лимитов Claude

# Cross-platform stat
if [[ "$OSTYPE" == "darwin"* ]]; then
  file_mtime() { stat -f %m "$1"; }
  file_size() { stat -f %z "$1"; }
else
  file_mtime() { stat -c %Y "$1"; }
  file_size() { stat -c %s "$1"; }
fi

# Cross-platform gateway restart
restart_gateway() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl kickstart -k "gui/$(id -u)/com.openclaw.gateway" 2>/dev/null || \
    openclaw gateway restart
  elif command -v systemctl &>/dev/null; then
    systemctl --user restart openclaw-gateway 2>/dev/null || \
    openclaw gateway restart
  else
    openclaw gateway restart
  fi
}
# Быстрый (0.2с), надёжный, без браузера
# Алертит при rate limits, высоком контексте, трендах

ERR_LOG="$HOME/.openclaw/logs/gateway.err.log"
USAGE_LOG="${WORKSPACE_PATH:-$HOME/workspace}/memory/usage-history.log"
SELF_LOG="$HOME/.openclaw/logs/limits-monitor.log"
ALERT_FLAG="$HOME/.openclaw/logs/.rate-limit-alerted"

source $HOME/.openclaw/scripts/hank-watchdog.env 2>/dev/null || true
TG_BOT_TOKEN="${HANK_BOT_TOKEN:-}"
TG_CHAT_ID="{{OWNER_TELEGRAM_ID}}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$SELF_LOG"; }

send_tg() {
  if [ -n "$TG_BOT_TOKEN" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
      -d chat_id="$TG_CHAT_ID" -d text="$1" -d parse_mode="HTML" > /dev/null 2>&1
  fi
}

# ============ 1. RATE LIMIT из логов ============
check_rate_limits() {
  [ ! -f "$ERR_LOG" ] && return

  # Ошибки за последние 15 минут
  local cutoff=$(date -v-15M '+%Y-%m-%dT%H:%M' 2>/dev/null || date -d '15 minutes ago' '+%Y-%m-%dT%H:%M' 2>/dev/null)
  local cutoff_1h=$(date -v-1H '+%Y-%m-%dT%H:%M' 2>/dev/null || date -d '1 hour ago' '+%Y-%m-%dT%H:%M' 2>/dev/null)
  
  local errors_15m
  errors_15m=$(awk -v cutoff="$cutoff" '$0 >= cutoff' "$ERR_LOG" 2>/dev/null | grep -c "rate.limit\|rate limit\|all in cooldown") || errors_15m=0
  local errors_1h
  errors_1h=$(awk -v cutoff="$cutoff_1h" '$0 >= cutoff_1h' "$ERR_LOG" 2>/dev/null | grep -c "rate.limit\|rate limit\|all in cooldown") || errors_1h=0

  if [ "$errors_15m" -ge 3 ]; then
    # Не спамим - раз в час
    if [ -f "$ALERT_FLAG" ]; then
      local flag_age=$(( $(date +%s) - $(file_mtime "$ALERT_FLAG" 2>/dev/null || echo 0) ))
      [ "$flag_age" -lt 3600 ] && return
    fi
    
    send_tg "🚨 <b>Лимиты Claude!</b>

Rate limit ошибок:
• За 15 мин: $errors_15m
• За час: $errors_1h

Opus может не отвечать. Sonnet лимит может ещё работать."
    
    touch "$ALERT_FLAG"
    log "⚠️ Rate limit alert: ${errors_15m}/15m, ${errors_1h}/1h"
  else
    [ -f "$ALERT_FLAG" ] && rm -f "$ALERT_FLAG"
  fi
}

# ============ 2. USAGE TRACKING из логов ============
track_usage() {
  local today=$(date '+%Y-%m-%d')
  
  # Rate limit ошибки за сегодня
  local today_errors
  today_errors=$(grep "$today" "$ERR_LOG" 2>/dev/null | grep -c "rate.limit\|rate limit\|all in cooldown") || today_errors=0
  
  # Auth ошибки за сегодня (токен протух)
  local auth_errors
  auth_errors=$(grep "$today" "$ERR_LOG" 2>/dev/null | grep -c "401\|auth\|unauthorized\|token.*invalid") || auth_errors=0
  
  # Gateway uptime (есть ли PID)
  local gw_pid
  gw_pid=$(launchctl list ai.openclaw.gateway 2>/dev/null | grep '"PID"' | grep -oE '[0-9]+' || echo "DOWN")
  
  echo "$(date '+%Y-%m-%d %H:%M') | gw:${gw_pid} | rate_errs:${today_errors} | auth_errs:${auth_errors}" >> "$USAGE_LOG"
}

# ============ 3. TREND ALERT ============
check_trend() {
  local today=$(date '+%Y-%m-%d')
  local today_errors
  today_errors=$(grep "$today" "$ERR_LOG" 2>/dev/null | grep -c "rate.limit\|rate limit") || today_errors=0
  
  local trend_flag="$HOME/.openclaw/logs/.trend-alerted-$today"
  if [ "$today_errors" -ge 20 ] && [ ! -f "$trend_flag" ]; then
    send_tg "📊 <b>Тренд дня:</b> $today_errors rate limit ошибок.

Лимиты расходуются быстро. Тяжёлые задачи → Sonnet субагент."
    touch "$trend_flag"
    log "📊 Trend alert: $today_errors errors today"
  fi
}

# ============ RUN ============
log "--- check ---"
check_rate_limits
track_usage
check_trend

# ============ 4. AGENT USAGE TRACKING ============
bash "${WORKSPACE_PATH:-$HOME/workspace}/scripts/agent-usage-tracker.sh" 2>/dev/null
