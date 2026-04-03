#!/bin/bash
# memory-hygiene.sh — Автогигиена памяти {{AGENT_NICKNAME}}а
# Запускать через крон в 04:00 (ночью, когда агент не активен!)
#
# Что делает:
# 1. Архивирует daily notes старше 14 дней в memory/archive/daily/
# 2. Удаляет архивы старше 90 дней
# 3. Переиндексирует память (ТОЛЬКО ночью чтобы не блокировать SQLite!)
# 4. Выводит отчёт

set -euo pipefail

WORKSPACE="${WORKSPACE_PATH:-$HOME/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
ARCHIVE_DIR="$MEMORY_DIR/archive"
ARCHIVE_DAILY="$ARCHIVE_DIR/daily"

ARCHIVE_AFTER_DAYS=14
PURGE_AFTER_DAYS=90

LOG_FILE="$MEMORY_DIR/hygiene.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M')] $1"
    echo "$msg" >> "$LOG_FILE"
    echo "$msg" >&2
}

archive_daily_notes() {
    mkdir -p "$ARCHIVE_DAILY"
    local count=0
    local cutoff_date=$(date -v-${ARCHIVE_AFTER_DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${ARCHIVE_AFTER_DAYS} days ago" '+%Y-%m-%d')
    
    for file in "$MEMORY_DIR"/20??-*.md; do
        [ -f "$file" ] || continue
        local basename=$(basename "$file")
        local file_date=$(echo "$basename" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        [ -z "$file_date" ] && continue
        
        if [[ "$file_date" < "$cutoff_date" ]]; then
            mv "$file" "$ARCHIVE_DAILY/"
            count=$((count + 1))
        fi
    done
    
    log "Archived $count daily notes older than $ARCHIVE_AFTER_DAYS days"
    echo "$count"
}

purge_old_archives() {
    local count=0
    
    if [ -d "$ARCHIVE_DAILY" ]; then
        local cutoff_date=$(date -v-${PURGE_AFTER_DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${PURGE_AFTER_DAYS} days ago" '+%Y-%m-%d')
        
        for file in "$ARCHIVE_DAILY"/*.md; do
            [ -f "$file" ] || continue
            local basename=$(basename "$file")
            local file_date=$(echo "$basename" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
            [ -z "$file_date" ] && continue
            
            if [[ "$file_date" < "$cutoff_date" ]]; then
                rm "$file"
                count=$((count + 1))
            fi
        done
    fi
    
    log "Purged $count archives older than $PURGE_AFTER_DAYS days"
    echo "$count"
}

reindex_memory() {
    log "Starting reindex..."
    openclaw memory index --force 2>/dev/null || true
    sleep 3
    local status=$(openclaw memory status 2>/dev/null | grep "Dirty:" | head -1)
    log "Reindex done: $status"
}

main() {
    log "=== Memory Hygiene START ==="
    
    local archived=$(archive_daily_notes 2>/dev/null)
    local purged=$(purge_old_archives 2>/dev/null)
    
    reindex_memory
    
    local total=$((archived + purged))
    
    log "=== Memory Hygiene DONE: archived=$archived purged=$purged total=$total ==="
    echo "{\"archived\":$archived,\"purged\":$purged,\"total_actions\":$total}"
}

main "$@"
