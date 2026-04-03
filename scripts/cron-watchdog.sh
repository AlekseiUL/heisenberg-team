#!/bin/bash
# cron-watchdog.sh — Мониторинг кронов OpenClaw
# Проверяет: ошибки, пропущенные запуски, зависания
# Работает без LLM, 0 токенов

set -euo pipefail

SCRIPTS_DIR="$(dirname "$0")"

# Получаем чистый JSON (cron-get-jobs.sh стрипит Doctor banner prefix)
JOBS_JSON=$(bash "$SCRIPTS_DIR/cron-get-jobs.sh" 2>/dev/null) || {
  echo "ERROR: Не удалось получить список кронов (timeout или gateway недоступен)"
  exit 1
}

TMPJSON=$(mktemp /tmp/cron-watchdog.XXXXXX)
echo "$JOBS_JSON" > "$TMPJSON"
WATCHDOG_RESULT=$(python3 - "$TMPJSON" << 'PYEOF' || true
import json, sys, time

now_ms = int(time.time() * 1000)
with open(sys.argv[1]) as f:
    data = json.load(f)
import os; os.unlink(sys.argv[1])
jobs = data.get('jobs', [])

def guess_interval(expr):
    parts = expr.split()
    if len(parts) != 5:
        return 86400000
    _, _, dom, _, dow = parts
    if dow != '*' and dom == '*':
        return 604800000  # weekly
    return 86400000  # daily

problems = []
total = 0
healthy = 0

for job in jobs:
    if not job.get('enabled', True):
        continue
    schedule = job.get('schedule', {})
    if schedule.get('kind') == 'at':
        continue

    total += 1
    name = job.get('name', 'unnamed')
    state = job.get('state', {})
    errors = state.get('consecutiveErrors', 0)
    last_run = state.get('lastRunAtMs', 0)
    last_status = state.get('lastStatus', 'unknown')
    last_duration = state.get('lastDurationMs', 0)

    if errors > 0:
        last_err = state.get('lastError', 'unknown')
        problems.append(f'❌ {name}: {errors} ошибок подряд ({last_err})')
        continue

    expr = schedule.get('expr', '0 0 * * *')
    interval = guess_interval(expr)
    max_gap = interval * 3

    if last_run > 0 and (now_ms - last_run) > max_gap:
        hours_ago = round((now_ms - last_run) / 3600000, 1)
        expected_h = round(interval / 3600000)
        problems.append(f'⏰ {name}: последний запуск {hours_ago}ч назад (ожидалось каждые {expected_h}ч)')
        continue

    if last_duration > 300000:
        mins = round(last_duration / 60000, 1)
        problems.append(f'🐌 {name}: последний запуск занял {mins} мин')

    healthy += 1

total_errors = sum(1 for j in jobs if j.get('enabled', True) and j.get('state', {}).get('consecutiveErrors', 0) > 0)
escalation = ''
if total_errors >= 3:
    escalation = f'\n\n🔴 ЭСКАЛАЦИЯ: {total_errors} из {total} кронов с ошибками!'

if problems:
    msg = f'🚨 Cron Watchdog\n\nКронов: {total} | Здоровых: {healthy} | Проблем: {len(problems)}\n'
    for p in problems:
        msg += f'\n{p}'
    msg += escalation
    print(msg)
    sys.exit(2)
else:
    print(f'ALL_OK:{total}:{healthy}')
    sys.exit(0)
PYEOF
)

echo "$WATCHDOG_RESULT"
# Определяем наличие проблем по содержимому вывода
WATCHDOG_EXIT=0
echo "$WATCHDOG_RESULT" | grep -q "^ALL_OK:" || WATCHDOG_EXIT=2

# Если найдены проблемы — запускаем retry в фоне
if [ "$WATCHDOG_EXIT" -eq 2 ]; then
  echo ""
  echo "🔄 Запускаю auto-retry упавших кронов (результат придёт отдельно)..."
  bash "$SCRIPTS_DIR/cron-retry.sh" >> "$HOME/.openclaw/logs/cron-retry.log" 2>&1 &
fi

exit $([[ $WATCHDOG_EXIT -eq 0 ]] && echo 0 || echo 1)
