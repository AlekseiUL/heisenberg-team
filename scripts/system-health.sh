#!/bin/bash
# system-health.sh — Проверка здоровья системы
# Вывод: ALL_OK или PROBLEM|тип|описание|команда_исправления
set -uo pipefail

WORKSPACE="${WORKSPACE_PATH:-$HOME/workspace}"
PROBLEMS=0

# === RAM ===
if [[ "$OSTYPE" == "darwin"* ]]; then
  free_mb=$(vm_stat | awk '/Pages free/ {printf "%d", $3*4096/1024/1024}')
  inactive_mb=$(vm_stat | awk '/Pages inactive/ {printf "%d", $3*4096/1024/1024}')
  available_mb=$((free_mb + inactive_mb))
elif command -v free &>/dev/null; then
  available_mb=$(free -m | awk '/^Mem:/ {print $7}')
else
  available_mb=9999  # unknown platform, skip check
fi
if [ "$available_mb" -lt 200 ]; then
    echo "PROBLEM|ram|🔴 RAM критично: доступно ${available_mb}MB (< 200MB)|pkill -f 'whisper-server'; docker stop pgadmin-local 2>/dev/null"
    PROBLEMS=$((PROBLEMS+1))
elif [ "$available_mb" -lt 500 ]; then
    echo "PROBLEM|ram|⚠️ RAM мало: доступно ${available_mb}MB (< 500MB)|pkill -f 'whisper-server' 2>/dev/null"
    PROBLEMS=$((PROBLEMS+1))
fi

# === ДИСК ===
disk_pct=$(df / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
if [ "$disk_pct" -gt 90 ]; then
    echo "PROBLEM|disk|🔴 Диск критично: занято ${disk_pct}%|bash ${WORKSPACE}/scripts/night-cleanup.sh"
    PROBLEMS=$((PROBLEMS+1))
elif [ "$disk_pct" -gt 80 ]; then
    echo "PROBLEM|disk|⚠️ Диск заполнен на ${disk_pct}%|bash ${WORKSPACE}/scripts/night-cleanup.sh"
    PROBLEMS=$((PROBLEMS+1))
fi

# === ЛОГИ ===
log_size_mb=$(du -sm ~/.openclaw/logs/ 2>/dev/null | cut -f1)
if [ "${log_size_mb:-0}" -gt 50 ]; then
    echo "PROBLEM|logs|⚠️ Логи: ${log_size_mb}MB (> 50MB)|bash ${WORKSPACE}/scripts/rotate-logs.sh"
    PROBLEMS=$((PROBLEMS+1))
fi

# === SQLITE ===
sqlite_path="$HOME/.openclaw/memory/main.sqlite"
if [ -f "$sqlite_path" ]; then
    sqlite_mb=$(du -m "$sqlite_path" | cut -f1)
    if [ "$sqlite_mb" -gt 1000 ]; then
        echo "PROBLEM|sqlite|🔴 SQLite критично: ${sqlite_mb}MB (> 1GB)|sqlite3 ~/.openclaw/memory/main.sqlite 'VACUUM;'"
        PROBLEMS=$((PROBLEMS+1))
    elif [ "$sqlite_mb" -gt 500 ]; then
        echo "PROBLEM|sqlite|⚠️ SQLite большой: ${sqlite_mb}MB (> 500MB)|sqlite3 ~/.openclaw/memory/main.sqlite 'VACUUM;'"
        PROBLEMS=$((PROBLEMS+1))
    fi
    # WAL mode
    wal_mode=$(sqlite3 "$sqlite_path" "PRAGMA journal_mode;" 2>/dev/null)
    if [ "$wal_mode" != "wal" ]; then
        echo "PROBLEM|sqlite_wal|🔴 SQLite НЕ в WAL режиме! (${wal_mode})|sqlite3 ~/.openclaw/memory/main.sqlite 'PRAGMA journal_mode=WAL;'"
        PROBLEMS=$((PROBLEMS+1))
    fi
fi

# === DOCKER ===
if command -v docker &>/dev/null && docker ps &>/dev/null 2>&1; then
    for container in searxng n8n-local; do
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "PROBLEM|docker_${container}|⚠️ Docker контейнер не запущен: ${container}|docker start ${container}"
            PROBLEMS=$((PROBLEMS+1))
        fi
    done
fi

# === МУСОР ===
junk_count=$(find "$WORKSPACE" -name "*.bak" -o -name "*.tmp" -o -name "*.swp" 2>/dev/null | grep -v ".git" | wc -l | tr -d ' ')
if [ "$junk_count" -gt 5 ]; then
    echo "PROBLEM|junk|⚠️ Мусорные файлы: ${junk_count} шт (*.bak, *.tmp)|find ${WORKSPACE} -name '*.bak' -o -name '*.tmp' | grep -v .git | xargs rm -f"
    PROBLEMS=$((PROBLEMS+1))
fi

# === ИТОГ ===
if [ "$PROBLEMS" -eq 0 ]; then
    echo "ALL_OK"
fi
