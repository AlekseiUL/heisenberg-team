#!/bin/bash
command -v md5sum &>/dev/null || md5sum() { md5 -q "$@"; }
# night-cleanup.sh — Ночная уборка (Memory Hygiene + Rotate Logs)
# Запускается каждую ночь в 03:30
set -euo pipefail

# Cross-platform stat
if [[ "$OSTYPE" == "darwin"* ]]; then
  file_mtime() { stat -f %m "$1"; }
  file_size() { stat -f %z "$1"; }
else
  file_mtime() { stat -c %Y "$1"; }
  file_size() { stat -c %s "$1"; }
fi

# Cross-platform date: macOS uses date -j, Linux uses date -d
parse_date() {
  local datestr="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    $(date -j -f "%Y-%m-%d" "$datestr" +%s 2>/dev/null || date -d "$datestr" +%s 2>/dev/null || echo 0)
  else
    date -d "$datestr" +%s 2>/dev/null
  fi
}

WORKSPACE="${WORKSPACE_PATH:-$HOME/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
LOG_DIR="$HOME/.openclaw/logs"
TMP_LOG_DIR="/tmp/openclaw"
ARCHIVE_DIR="$MEMORY_DIR/archive/daily"
ERRORS=0
ACTIONS=0

log() { echo "$(date '+%H:%M:%S') $1"; }

# === 1. MEMORY HYGIENE ===
log "📚 Memory Hygiene..."
mkdir -p "$ARCHIVE_DIR"

# Защищённые папки — НИКОГДА не трогать
PROTECTED=("core" "decisions" "projects" "archive" "DO_NOT_DELETE.md" "handoff.md" "topics-digest.md" "recurring-patterns.md" "usage-history.log")

TODAY=$(date +%Y-%m-%d)
ARCHIVED=0
DELETED=0

for f in "$MEMORY_DIR"/*.md; do
    [ -f "$f" ] || continue
    fname=$(basename "$f")
    
    # Пропускаем защищённые
    protected=false
    for p in "${PROTECTED[@]}"; do [ "$fname" = "$p" ] && protected=true && break; done
    $protected && continue
    
    # Только daily notes вида 2026-MM-DD.md
    [[ "$fname" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]] || continue
    
    file_date="${fname%.md}"
    age=$(( ( $(parse_date "$TODAY") - $(parse_date "$file_date") ) / 86400 ))
    
    if [ "$age" -ge 90 ]; then
        rm -f "$f" && DELETED=$((DELETED+1)) && ACTIONS=$((ACTIONS+1))
        log "  🗑️ Удалён (${age}д): $fname"
    elif [ "$age" -ge 14 ]; then
        mv "$f" "$ARCHIVE_DIR/$fname" && ARCHIVED=$((ARCHIVED+1)) && ACTIONS=$((ACTIONS+1))
        log "  📦 Архивирован (${age}д): $fname"
    fi
done

# Удаляем из archive/daily старше 90 дней
for f in "$ARCHIVE_DIR"/*.md; do
    [ -f "$f" ] || continue
    fname=$(basename "$f")
    [[ "$fname" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]] || continue
    file_date="${fname%.md}"
    age=$(( ( $(parse_date "$TODAY") - $(parse_date "$file_date") ) / 86400 ))
    if [ "$age" -ge 90 ]; then
        rm -f "$f" && DELETED=$((DELETED+1))
        log "  🗑️ Удалён из архива (${age}д): $fname"
    fi
done

log "  ✅ Memory: archived=$ARCHIVED deleted=$DELETED"

# === 2. ROTATE LOGS ===
log "🔄 Rotate Logs..."
ROTATED=0

for f in "$LOG_DIR"/*.log "$LOG_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    size_mb=$(du -m "$f" | cut -f1)
    if [ "${size_mb:-0}" -ge 10 ]; then
        tail -1000 "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        ROTATED=$((ROTATED+1)) && ACTIONS=$((ACTIONS+1))
        log "  ✂️ $(basename $f): ${size_mb}MB → 1000 строк"
    fi
done

if [ -d "$TMP_LOG_DIR" ]; then
    for f in "$TMP_LOG_DIR"/*.log; do
        [ -f "$f" ] || continue
        size_mb=$(du -m "$f" | cut -f1)
        if [ "${size_mb:-0}" -ge 50 ]; then
            > "$f" && ROTATED=$((ROTATED+1)) && ACTIONS=$((ACTIONS+1))
            log "  🗑️ tmp лог очищен: $(basename $f) (${size_mb}MB)"
        fi
    done
    find "$TMP_LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null && log "  🧹 tmp логи старше 7д удалены"
fi

log "  ✅ Logs: rotated=$ROTATED"

# === 3. AGENT SESSIONS CLEANUP ===
log "🤖 Agent sessions cleanup..."
AGENT_CLEANED=0
for agent_dir in "$HOME/.openclaw/agents"/*/sessions; do
    [ -d "$agent_dir" ] || continue
    agent_name=$(basename "$(dirname "$agent_dir")")
    for f in "$agent_dir"/*.jsonl; do
        [ -f "$f" ] || continue
        file_age=$(( ( $(date +%s) - $(file_mtime "$f") ) / 86400 ))
        if [ "$file_age" -ge 30 ]; then
            rm -f "$f" && AGENT_CLEANED=$((AGENT_CLEANED+1)) && ACTIONS=$((ACTIONS+1))
            log "  🗑️ $agent_name session (${file_age}д): $(basename $f)"
        fi
    done
done
log "  ✅ Agent sessions: cleaned=$AGENT_CLEANED"

# === 4. SQLITE EMBEDDING CACHE CLEANUP ===
log "🧹 SQLite embedding_cache cleanup..."
SQLITE_DB="$HOME/.openclaw/memory/main.sqlite"
if [ -f "$SQLITE_DB" ]; then
    BEFORE=$(du -m "$SQLITE_DB" | cut -f1)
    sqlite3 "$SQLITE_DB" "DELETE FROM embedding_cache;" 2>/dev/null && ACTIONS=$((ACTIONS+1))
    sqlite3 "$SQLITE_DB" "VACUUM;" 2>/dev/null
    AFTER=$(du -m "$SQLITE_DB" | cut -f1)
    log "  ✅ SQLite: ${BEFORE}MB → ${AFTER}MB"
fi

# === ИТОГ ===
log "✅ Ночная уборка завершена: actions=$ACTIONS errors=$ERRORS"
