#!/bin/bash
# OpenClaw Watchdog v3 — проверяет что Gateway жив + API токен валиден
# Запускается через launchd/systemd каждые 2 минуты
# v3: добавлена проверка 401 от Anthropic в логах OpenClaw

# Cross-platform stat
if [[ "$OSTYPE" == "darwin"* ]]; then
  file_mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }
  file_size() { stat -f%z "$1" 2>/dev/null || echo 0; }
else
  file_mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
  file_size() { stat -c %s "$1" 2>/dev/null || echo 0; }
fi

# Cross-platform gateway restart
restart_gateway() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl kickstart -k "gui/$(id -u)/ai.openclaw.gateway" 2>/dev/null || \
    /opt/homebrew/bin/openclaw gateway start &>/dev/null &
  elif command -v systemctl &>/dev/null; then
    systemctl --user restart openclaw-gateway 2>/dev/null || \
    openclaw gateway restart
  else
    openclaw gateway restart
  fi
}

HEALTH_URL="http://127.0.0.1:18789/health"
source $HOME/.openclaw/scripts/hank-watchdog.env
TG_BOT_TOKEN="${HANK_BOT_TOKEN}"
TG_CHAT_ID="${HANK_CHAT_ID}"
LOG_FILE="$HOME/.openclaw/logs/watchdog.log"
ERR_LOG="$HOME/.openclaw/logs/gateway.err.log"
OPENCLAW_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
AUTH_FAIL_FILE="/tmp/openclaw-auth-fail-count"
MAX_RETRIES=3
RETRY_DELAY=10

# Ротация лога (макс 1MB)
if [ -f "$LOG_FILE" ] && [ $(file_size "$LOG_FILE") -gt 1048576 ]; then
  tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TG_CHAT_ID" \
    -d text="$1" \
    -d parse_mode="HTML" > /dev/null 2>&1
}

check_health() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$HEALTH_URL" 2>/dev/null)
  [ "$status" = "200" ]
}

do_restart_gateway() {
  local reason="$1"
  log "🔴 OpenClaw is DOWN ($reason). Attempting restart..."
  send_telegram "🔴 <b>Хайзенберг упал!</b> ($reason) Watchdog пытается перезапустить..."

  for i in $(seq 1 $MAX_RETRIES); do
    log "Restart attempt $i/$MAX_RETRIES"
    
    pkill -f "openclaw.*gateway" 2>/dev/null
    sleep 2
    
    restart_gateway
    
    sleep 15
    
    if check_health; then
      log "✅ Restarted successfully on attempt $i ($reason)"
      send_telegram "✅ <b>Хайзенберг перезапущен!</b> ($reason, попытка $i/$MAX_RETRIES)"
      # Сбрасываем счётчик 401
      rm -f "$AUTH_FAIL_FILE"
      return 0
    fi
  done

  log "🚨 FAILED to restart after $MAX_RETRIES attempts ($reason)"
  send_telegram "🚨 <b>Хайзенберг НЕ удалось перезапустить!</b> ($reason) Нужно ручное вмешательство.
Попробуй: <code>openclaw gateway restart</code>"
  return 1
}

# === Основная логика ===

# 1. Health check
if check_health; then
  # Жив. Проверяем доп. проблемы.
  
  # 2. Token mismatch (после update)
  if [ -f "$ERR_LOG" ]; then
    RECENT_TOKEN_ERR=$(tail -20 "$ERR_LOG" | grep -c "device_token_mismatch" 2>/dev/null; true)
    if [ "$RECENT_TOKEN_ERR" -gt 0 ]; then
      log "⚠️ Token mismatch detected in err log"
    fi
  fi
  
  # 3. Проверка 401 от Anthropic в логах (НОВОЕ в v3)
  # Ищем свежие 401 ошибки за последние 5 минут
  if [ -f "$OPENCLAW_LOG" ]; then
    NOW_TS=$(date +%s)
    # Считаем 401 ошибки в последних 50 строках лога
    # Только ошибки за последние 5 минут (по временной метке в JSON логе)
    FIVE_MIN_AGO=$(date -u -v-5M '+%Y-%m-%dT%H:%M' 2>/dev/null || date -u -d '5 minutes ago' '+%Y-%m-%dT%H:%M' 2>/dev/null)
    if [ -n "$FIVE_MIN_AGO" ]; then
      AUTH_ERRORS=$(python3 -c "
import re, sys
since = '$FIVE_MIN_AGO'
count = 0
try:
  with open('$OPENCLAW_LOG', 'r', errors='replace') as f:
    for line in f:
      m = re.search(r'\"date\":\"([^\"]+)\"', line)
      if m and m.group(1) >= since:
        if any(e in line for e in ['HTTP 401', 'authentication_error', 'Invalid bearer token']):
          count += 1
except: pass
print(count)
" 2>/dev/null || echo 0)
    else
      AUTH_ERRORS=$(tail -20 "$OPENCLAW_LOG" | grep -c "HTTP 401\|authentication_error\|Invalid bearer token" 2>/dev/null; true)
    fi
    
    if [ "$AUTH_ERRORS" -gt 0 ]; then
      # Инкрементируем счётчик (чтобы не рестартить на единичную ошибку)
      PREV_COUNT=$(cat "$AUTH_FAIL_FILE" 2>/dev/null || echo 0)
      NEW_COUNT=$((PREV_COUNT + 1))
      echo "$NEW_COUNT" > "$AUTH_FAIL_FILE"
      
      log "⚠️ Anthropic 401 errors detected ($AUTH_ERRORS in recent log). Consecutive checks: $NEW_COUNT"
      
      # Если 2+ проверки подряд видят 401 (4+ минуты проблемы) - рестартим
      if [ "$NEW_COUNT" -ge 2 ]; then
        log "🔴 Persistent 401 errors ($NEW_COUNT checks). Restarting gateway..."
        send_telegram "🔴 <b>Хайзенберг: 401 от Anthropic!</b> Токен невалиден $NEW_COUNT проверок подряд. Перезапускаю..."
        do_restart_gateway "anthropic_401"
      fi
    else
      # Нет 401 - сбрасываем счётчик
      rm -f "$AUTH_FAIL_FILE"
    fi
  fi
  
  # 4. Проверка что Telegram polling жив (getMe)
  if [ -n "$TG_BOT_TOKEN" ]; then
    TG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
      "https://api.telegram.org/bot${TG_BOT_TOKEN}/getMe" 2>/dev/null)
    if [ "$TG_STATUS" != "200" ]; then
      log "⚠️ Telegram Bot API unreachable (HTTP $TG_STATUS)"
    fi
  fi
  
  exit 0
fi

# Health check failed - ждём и retry
log "⚠️ Health check failed, waiting ${RETRY_DELAY}s before retry..."
sleep "$RETRY_DELAY"

if check_health; then
  log "✅ Recovered after retry"
  exit 0
fi

# Определяем причину падения
REASON="unknown"
if [ -f "$ERR_LOG" ]; then
  if tail -5 "$ERR_LOG" | grep -q "device_token_mismatch"; then
    REASON="token_mismatch"
  elif tail -5 "$ERR_LOG" | grep -q "ENOMEM\|heap"; then
    REASON="OOM"
  elif tail -5 "$ERR_LOG" | grep -q "SIGKILL\|SIGTERM"; then
    REASON="killed"
  fi
fi

do_restart_gateway "$REASON"
