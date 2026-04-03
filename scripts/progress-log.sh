#!/bin/bash
# Дописать строку в progress-log.md
# Использование: bash scripts/progress-log.sh "🔒 Security Audit" "Firewall ON, 3 peers ✅"
LOG="${WORKSPACE_PATH:-$HOME/workspace}/memory/progress-log.md"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
TASK="$1"
RESULT="$2"

# Создать заголовок дня если нет
if ! grep -q "## $DATE" "$LOG" 2>/dev/null; then
  echo -e "\n## $DATE" >> "$LOG"
fi

echo "$TIME $TASK - $RESULT" >> "$LOG"
