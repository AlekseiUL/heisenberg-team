#!/bin/bash
# git-backup.sh - Бэкап workspace на GitHub
# Для использования Хэнком и другими агентами
# Только коммит + push в закрытый репо, ничего больше
set -euo pipefail

REPO="${WORKSPACE_PATH:-$HOME/workspace}"
cd "$REPO"

# Проверяем есть ли изменения
CHANGES=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$CHANGES" -eq 0 ]; then
    echo "NO_CHANGES"
    exit 0
fi

# Дата для коммита
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

# Коммит и пуш
git add -A
git commit -m "backup $DATE $TIME: auto-backup ($CHANGES files)"
git push

echo "OK: $CHANGES files committed and pushed"
