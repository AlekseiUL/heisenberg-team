#!/bin/bash
# Умный сброс сессии агента перед новой задачей
# Сбрасывает ТОЛЬКО если >50K токенов
# Использование: bash trash-agent-session.sh <agent_id> [--force]
# --force: сбросить независимо от размера

AGENT=$1
FORCE=$2
THRESHOLD=50000

if [ -z "$AGENT" ]; then
  echo "Использование: bash trash-agent-session.sh <agent_id> [--force]"
  echo "Агенты: producer teamlead marketing-funnel skyler hank kaizen"
  echo "Порог: ${THRESHOLD} токенов (--force игнорирует)"
  exit 1
fi

SESSION_FILE="$HOME/.openclaw/agents/$AGENT/sessions/sessions.json"
if [ ! -f "$SESSION_FILE" ]; then
  echo "❌ Файл не найден: $SESSION_FILE"
  exit 1
fi

KEY="agent:${AGENT}:main"
python3 -c "
import json, sys
with open('$SESSION_FILE') as f:
    data = json.load(f)
if '$KEY' not in data:
    print(f'⏭️ $AGENT: сессия чистая')
    sys.exit(0)

tokens = data['$KEY'].get('totalTokens', 0) or 0
status = data['$KEY'].get('status', 'unknown')
force = '$FORCE' == '--force'

# Сбрасываем ВСЕГДА если сессия завершена (done) — агент не слушает sessions_send
if status == 'done':
    force = True
    print(f'⚠️ $AGENT: сессия завершена (done, {tokens} tokens) — СБРАСЫВАЮ принудительно')

if not force and tokens < $THRESHOLD:
    print(f'⏭️ $AGENT: сессия лёгкая ({tokens} tokens < $THRESHOLD) — НЕ сбрасываю')
    sys.exit(0)

del data['$KEY']
with open('$SESSION_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print(f'✅ $AGENT: сессия сброшена ({tokens} tokens)')
"
