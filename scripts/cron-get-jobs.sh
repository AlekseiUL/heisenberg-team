#!/bin/bash
# cron-get-jobs.sh — Надёжное получение JSON списка кронов
# Решает проблему Doctor banner prefix в выводе openclaw cron list --json
# Использование: bash cron-get-jobs.sh | python3 ...
# Возвращает: чистый JSON {"jobs": [...]} или выходит с кодом 1

OPENCLAW="/opt/homebrew/bin/openclaw"

# Таймаут через perl (macOS совместимо, не требует coreutils)
OUTPUT=$(perl -e 'alarm 20; exec @ARGV' -- "$OPENCLAW" cron list --json 2>/dev/null) || {
  echo '{"jobs":[],"error":"openclaw timeout or failed"}' >&2
  exit 1
}

# Стрипим Doctor banner и plugin логи: находим первый JSON-валидный { или [
echo "$OUTPUT" | python3 -c "
import sys, json
raw = sys.stdin.read()
# Ищем первый '{' или '[' который начинает валидный JSON
for i, c in enumerate(raw):
    if c == '{':
        try:
            json.loads(raw[i:])
            print(raw[i:])
            sys.exit(0)
        except json.JSONDecodeError:
            continue
    elif c == '[' and not raw[i:].startswith('[plugins]'):
        try:
            json.loads(raw[i:])
            print(raw[i:])
            sys.exit(0)
        except json.JSONDecodeError:
            continue
print('{\"jobs\":[]}')
sys.exit(1)
"
