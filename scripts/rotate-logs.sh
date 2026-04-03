#!/bin/bash
# rotate-logs.sh — Авторотация логов OpenClaw
# Запускается ежедневно в 03:45
# Правило: каждый лог не более 10MB, tmp лог не более 50MB

set -euo pipefail

LOG_DIR="$HOME/.openclaw/logs"
TMP_LOG_DIR="/tmp/openclaw"
MAX_SIZE_MB=10       # Максимум для каждого лога в ~/.openclaw/logs/
MAX_TMP_SIZE_MB=50   # Максимум для /tmp/openclaw/*.log
KEEP_DAYS=7          # Удалять логи старше 7 дней

ROTATED=0
DELETED=0

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1"; }

# === 1. Ротация логов в ~/.openclaw/logs/ ===
for f in "$LOG_DIR"/*.log "$LOG_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    size_mb=$(du -m "$f" | cut -f1)
    if [ "${size_mb:-0}" -ge "$MAX_SIZE_MB" ]; then
        # Оставляем последние 1000 строк
        tail -1000 "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        ROTATED=$((ROTATED+1))
        log "✂️ Обрезан: $(basename $f) (был ${size_mb}MB → последние 1000 строк)"
    fi
done

# === 2. Ротация /tmp/openclaw/*.log ===
if [ -d "$TMP_LOG_DIR" ]; then
    for f in "$TMP_LOG_DIR"/*.log; do
        [ -f "$f" ] || continue
        size_mb=$(du -m "$f" | cut -f1)
        if [ "${size_mb:-0}" -ge "$MAX_TMP_SIZE_MB" ]; then
            # Для tmp лога - просто очищаем (это runtime лог, не нужна история)
            > "$f"
            ROTATED=$((ROTATED+1))
            log "🗑️ Очищен tmp лог: $(basename $f) (был ${size_mb}MB)"
        fi
    done

    # Удаляем старые /tmp логи
    find "$TMP_LOG_DIR" -name "*.log" -mtime +$KEEP_DAYS -delete 2>/dev/null && \
        log "🧹 Удалены tmp логи старше ${KEEP_DAYS} дней"
fi

# === 3. Итог ===
total_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
log "✅ Готово: обрезано=$ROTATED удалено=$DELETED | Размер logs/: $total_size"
