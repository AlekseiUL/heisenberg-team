#!/bin/bash
# scripts/cron-retry.sh — Авто-retry упавших кронов
# Правильная логика: запускаем всех → ждём 3 мин → проверяем всех вместе
# Возвращает: 0 если все восстановлены, 1 если остались ошибки

set -euo pipefail

# Cross-platform stat
if [[ "$OSTYPE" == "darwin"* ]]; then
  file_mtime() { stat -f %m "$1"; }
  file_size() { stat -f %z "$1"; }
else
  file_mtime() { stat -c %Y "$1"; }
  file_size() { stat -c %s "$1"; }
fi

OPENCLAW="/opt/homebrew/bin/openclaw"
SCRIPTS_DIR="$(dirname "$0")"
LOG="$HOME/.openclaw/logs/cron-retry.log"
TG_BOT_TOKEN="${GEMINI_DOCTOR_TOKEN:-}"
TG_CHAT_ID="${DOCTOR_CHAT_ID:-${OWNER_TELEGRAM_ID:-}}"

source $HOME/.openclaw/doctor.env 2>/dev/null || true

mkdir -p "$(dirname "$LOG")"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG"; }

# Lock - предотвращаем двойной запуск
LOCK="/tmp/cron-retry.lock"
if [ -f "$LOCK" ]; then
  LOCK_AGE=$(( $(date +%s) - $(file_mtime "$LOCK" 2>/dev/null || echo 0) ))
  if [ "$LOCK_AGE" -lt 600 ]; then  # 10 минут
    log "⏭️ Уже запущен (lock ${LOCK_AGE}s). Пропуск."
    exit 0
  fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
notify() {
  local msg="$1"
  [ -n "$TG_BOT_TOKEN" ] && curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TG_CHAT_ID" -d text="$msg" > /dev/null 2>&1 || true
}

# ============ Проверка gateway ============
check_gateway() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
    "http://127.0.0.1:18789/" 2>/dev/null || echo "000")
  [ "$status" != "000" ]
}

# ============ Классифицировать ошибку ============
classify_error() {
  local err="$1"
  if echo "$err" | grep -qi "timed out"; then echo "TIMEOUT"
  elif echo "$err" | grep -qi "rate.limit\|429\|overloaded"; then echo "RATE_LIMIT"
  elif echo "$err" | grep -qi "token\|auth\|401\|403"; then echo "AUTH"
  else echo "UNKNOWN"
  fi
}

# ============ MAIN ============
log "--- cron-retry started ---"

if ! check_gateway; then
  log "⚠️ Gateway недоступен — retry отложен"
  exit 1
fi

# Получить упавшие кроны
JOBS_JSON=$(bash "$SCRIPTS_DIR/cron-get-jobs.sh" 2>/dev/null) || { log "❌ Не удалось получить список кронов"; exit 1; }

FAILED_IDS=$(echo "$JOBS_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
failed = [
    {'id': j['id'], 'name': j.get('name', j['id']), 'error': j.get('state',{}).get('lastError','unknown')}
    for j in d.get('jobs', [])
    if j.get('enabled', True) and j.get('state', {}).get('consecutiveErrors', 0) > 0
    and j.get('schedule', {}).get('kind') != 'at'  # пропускаем одноразовые
]
print(json.dumps(failed))
" 2>/dev/null || echo "[]")

COUNT=$(echo "$FAILED_IDS" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

if [ "$COUNT" -eq 0 ]; then
  log "✅ Нет упавших кронов"
  exit 0
fi

log "🔍 Упавших кронов: $COUNT — запускаем все, потом ждём 3 мин"

# Пропускаем AUTH — не можем починить без ручного вмешательства
# Все остальные — запускаем параллельно
LAUNCHED=0
SKIPPED_AUTH=0
AUTH_NAMES=""

while IFS= read -r job; do
  JOB_ID=$(echo "$job" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['id'])")
  JOB_NAME=$(echo "$job" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['name'])")
  JOB_ERR=$(echo "$job" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['error'])")
  ERR_TYPE=$(classify_error "$JOB_ERR")

  if [ "$ERR_TYPE" = "AUTH" ]; then
    log "⛔ $JOB_NAME: AUTH ошибка — пропуск"
    SKIPPED_AUTH=$((SKIPPED_AUTH+1))
    AUTH_NAMES="${AUTH_NAMES}, ${JOB_NAME}"
    continue
  fi

  log "▶️ Запускаю: $JOB_NAME [$ERR_TYPE]"
  # Запускаем без ожидания (timeout 5s только на отправку команды)
  perl -e 'alarm 8; exec @ARGV' -- "$OPENCLAW" cron run "$JOB_ID" --force > /dev/null 2>&1 || true
  LAUNCHED=$((LAUNCHED+1))
  sleep 1  # небольшая пауза между запусками
done < <(echo "$FAILED_IDS" | python3 -c "
import json,sys
jobs = json.load(sys.stdin)
for j in jobs:
    print(json.dumps(j))
" 2>/dev/null || true)

if [ "$LAUNCHED" -eq 0 ]; then
  log "⚠️ Нечего перезапускать (все AUTH или пусто)"
  exit $([[ $SKIPPED_AUTH -gt 0 ]] && echo 1 || echo 0)
fi

log "⏳ Запущено $LAUNCHED кронов — ждём 3 минуты для завершения..."
sleep 180

# Проверяем результат
log "🔍 Проверяем результат..."
JOBS_AFTER=$(bash "$SCRIPTS_DIR/cron-get-jobs.sh" 2>/dev/null) || { log "❌ Не удалось получить статус после retry"; exit 1; }

RESULT=$(echo "$JOBS_AFTER" | python3 -c "
import json, sys
d = json.load(sys.stdin)
still_bad = [
    j.get('name', j['id'])
    for j in d.get('jobs', [])
    if j.get('enabled', True)
    and j.get('state', {}).get('consecutiveErrors', 0) > 0
    and j.get('schedule', {}).get('kind') != 'at'
]
all_jobs = [j for j in d.get('jobs', []) if j.get('enabled', True) and j.get('schedule', {}).get('kind') != 'at']
healthy = len(all_jobs) - len(still_bad)
print(json.dumps({'still_bad': still_bad, 'healthy': healthy, 'total': len(all_jobs)}))
" 2>/dev/null || echo '{"still_bad":[],"healthy":0,"total":0}')

STILL_BAD_COUNT=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['still_bad']))" 2>/dev/null || echo "?")
STILL_BAD_NAMES=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(', '.join(d['still_bad'][:5]))" 2>/dev/null || echo "")
HEALTHY=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['healthy'])" 2>/dev/null || echo "?")
TOTAL=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['total'])" 2>/dev/null || echo "?")

RECOVERED=$((COUNT - ${STILL_BAD_COUNT:-0}))

log "--- Итог: запущено=$LAUNCHED восстановлено=$RECOVERED всё_ещё_падают=${STILL_BAD_COUNT:-?} ---"

if [ "${STILL_BAD_COUNT:-1}" -gt 0 ] || [ "$SKIPPED_AUTH" -gt 0 ]; then
  MSG="🔄 Cron Auto-Retry завершён:"$'\n'
  MSG="${MSG}✅ Восстановлено: ${RECOVERED} из ${LAUNCHED}"$'\n'
  [ "${STILL_BAD_COUNT:-0}" -gt 0 ] && MSG="${MSG}❌ Всё ещё падают: ${STILL_BAD_COUNT} — ${STILL_BAD_NAMES}"$'\n'
  [ "$SKIPPED_AUTH" -gt 0 ] && MSG="${MSG}⛔ AUTH ошибки (нужен ручной фикс): ${AUTH_NAMES}"$'\n'
  MSG="${MSG}📊 Здоровых кронов: ${HEALTHY}/${TOTAL}"
  notify "$MSG"
  log "$MSG"
fi

[ "${STILL_BAD_COUNT:-1}" -eq 0 ]
