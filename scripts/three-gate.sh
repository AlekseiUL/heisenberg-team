#!/bin/bash
# Three-Gate Trigger для кронов OpenClaw
# Использование: scripts/three-gate.sh <cron-name> <min-hours> <min-sessions>
# Пример: scripts/three-gate.sh memory-hygiene 12 3
#
# Gate 1 (TIME):     Проверяет /tmp/openclaw-gate-<cron-name>.last
#                    Если файла нет или прошло >= min-hours часов → PASS
# Gate 2 (ACTIVITY): Проверяет .jsonl файлы в ~/.openclaw/sessions/
#                    модифицированных за последние min-hours часов. Если >= min-sessions → PASS
# Gate 3 (LOCK):     Проверяет /tmp/openclaw-gate-<cron-name>.lock
#                    Нет файла → создать, PASS
#                    Есть и процесс жив → FAIL
#                    Есть но процесс мёртв → удалить stale lock, PASS
#
# При прохождении всех gates:
#   - Создаёт lock-файл с PID
#   - Обновляет .last файл
#   - Выводит "THREE-GATE PASSED: <cron-name>" и exit 0
#
# При блокировке:
#   - Выводит "THREE-GATE BLOCKED: <gate-name> for <cron-name>" и exit 1
#
# ВАЖНО: скрипт НЕ запускает команду. Только проверяет gates.
# Использование в кроне:
#   scripts/three-gate.sh memory-hygiene 12 3 && [основная задача]

set -euo pipefail

# ─── Аргументы ───────────────────────────────────────────────────────────────
if [[ $# -lt 3 ]]; then
    echo "Usage: three-gate.sh <cron-name> <min-hours> <min-sessions>" >&2
    exit 2
fi

CRON_NAME="$1"
MIN_HOURS="$2"
MIN_SESSIONS="$3"

# ─── Пути ────────────────────────────────────────────────────────────────────
LAST_FILE="/tmp/openclaw-gate-${CRON_NAME}.last"
LOCK_FILE="/tmp/openclaw-gate-${CRON_NAME}.lock"
SESSIONS_DIR="${HOME}/.openclaw/sessions"

# ─── Lock cleanup trap ───────────────────────────────────────────────────────
# Вызывается при ранних exit-ах ДО того как lock был создан успешно.
# После успешного прохождения всех gates — lock снимает внешний процесс (крон).
LOCK_ACQUIRED=0

cleanup() {
    if [[ "$LOCK_ACQUIRED" -eq 1 ]]; then
        rm -f "$LOCK_FILE"
    fi
}
trap cleanup EXIT

# ─── Gate 1: TIME ─────────────────────────────────────────────────────────────
if [[ -f "$LAST_FILE" ]]; then
    LAST_TS=$(cat "$LAST_FILE" 2>/dev/null || echo 0)
    NOW_TS=$(date +%s)
    ELAPSED_SEC=$(( NOW_TS - LAST_TS ))
    MIN_SEC=$(( MIN_HOURS * 3600 ))

    if [[ "$ELAPSED_SEC" -lt "$MIN_SEC" ]]; then
        ELAPSED_H=$(( ELAPSED_SEC / 3600 ))
        echo "THREE-GATE BLOCKED: TIME for ${CRON_NAME} (elapsed ${ELAPSED_H}h < required ${MIN_HOURS}h)"
        exit 1
    fi
fi
# Нет .last файла или прошло достаточно времени → PASS

# ─── Gate 2: ACTIVITY ─────────────────────────────────────────────────────────
if [[ "$MIN_SESSIONS" -gt 0 ]]; then
    if [[ -d "$SESSIONS_DIR" ]]; then
        # Ищем .jsonl файлы, изменённые за последние min-hours часов
        # find -mmin принимает минуты
        MIN_MINUTES=$(( MIN_HOURS * 60 ))
        # Защита: если MIN_HOURS == 0 → проверяем за последние 60 минут
        if [[ "$MIN_MINUTES" -le 0 ]]; then
            MIN_MINUTES=60
        fi
        ACTIVE_COUNT=$(find "$SESSIONS_DIR" -name "*.jsonl" -mmin "-${MIN_MINUTES}" 2>/dev/null | wc -l | tr -d ' ')
    else
        ACTIVE_COUNT=0
    fi

    if [[ "$ACTIVE_COUNT" -lt "$MIN_SESSIONS" ]]; then
        echo "THREE-GATE BLOCKED: ACTIVITY for ${CRON_NAME} (active sessions ${ACTIVE_COUNT} < required ${MIN_SESSIONS})"
        exit 1
    fi
fi
# min-sessions == 0 или достаточно активных сессий → PASS

# ─── Gate 3: LOCK ─────────────────────────────────────────────────────────────
if [[ -f "$LOCK_FILE" ]]; then
    LOCKED_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")

    if [[ -n "$LOCKED_PID" ]] && kill -0 "$LOCKED_PID" 2>/dev/null; then
        # Процесс жив — конкурентное выполнение
        echo "THREE-GATE BLOCKED: LOCK for ${CRON_NAME} (PID ${LOCKED_PID} is alive)"
        exit 1
    else
        # Stale lock — процесс мёртв или PID пустой
        echo "THREE-GATE INFO: removing stale lock for ${CRON_NAME} (PID ${LOCKED_PID:-unknown} is dead)"
        rm -f "$LOCK_FILE"
    fi
fi

# Создаём lock-файл с текущим PID
echo $$ > "$LOCK_FILE"
LOCK_ACQUIRED=1

# ─── Все gates пройдены: обновляем .last ─────────────────────────────────────
date +%s > "$LAST_FILE"

# Снимаем cleanup trap — lock теперь принадлежит крону (внешний процесс уберёт)
# Крон должен сам удалить lock-файл после завершения работы:
#   rm -f /tmp/openclaw-gate-<cron-name>.lock
LOCK_ACQUIRED=0

echo "THREE-GATE PASSED: ${CRON_NAME}"
exit 0
