#!/bin/bash
# Task Poller — проверяет board на незакрытые задачи БЕЗ AI
# AI вызывается только если найдена задача для обработки
# Экономит токены: чистый bash вместо agentTurn

BOARD="${WORKSPACE_PATH:-$HOME/workspace}/references/team-board.md"

# Считаем незакрытые задачи (📋 НОВАЯ)
NEW_TASKS=$(grep -c "^- 📋" "$BOARD" 2>/dev/null || echo 0)

# Считаем задачи В РАБОТЕ дольше 24 часов
STALE=$(grep "^- ⏳" "$BOARD" 2>/dev/null | while read line; do
  DATE=$(echo "$line" | grep -oE '\[2026-[0-9-]+\]' | tr -d '[]')
  if [ -n "$DATE" ]; then
    TASK_TS=$(date -j -f "%Y-%m-%d" "$DATE" "+%s" 2>/dev/null || date -d "$DATE" "+%s" 2>/dev/null || echo 0)
    NOW_TS=$(date "+%s")
    DIFF=$(( (NOW_TS - TASK_TS) / 86400 ))
    if [ "$DIFF" -gt 1 ]; then
      echo "STALE"
    fi
  fi
done | wc -l | tr -d ' ')

# Результат
if [ "$NEW_TASKS" -gt 0 ] || [ "$STALE" -gt 0 ]; then
  echo "NEEDS_ATTENTION: new=$NEW_TASKS stale=$STALE"
  exit 1
else
  echo "ALL_CLEAR"
  exit 0
fi
