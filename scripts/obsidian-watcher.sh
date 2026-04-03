#!/bin/bash
# =============================================================================
# obsidian-watcher.sh — Демон наблюдения за файлами Obsidian vault
#
# Следит за изменениями *.md файлов в obsidian/ через fswatch.
# При изменении (с debounce через latency fswatch) отправляет уведомление
# агенту OpenClaw для предложения линковки через [[wikilinks]].
#
# Совместим с macOS bash 3.2 (без declare -A)
# Автор: {{AGENT_NICKNAME}} 🦀 | Дата: 2026-03-03
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Конфигурация
# ---------------------------------------------------------------------------
VAULT_DIR="${WORKSPACE_PATH:-$HOME/workspace}/obsidian"
WEBHOOK_URL="http://127.0.0.1:18789/hooks/agent"
WEBHOOK_TOKEN="${WEBHOOK_TOKEN:-}"
MODEL="anthropic/claude-sonnet-4-6"
LOG_FILE="$HOME/.openclaw/logs/obsidian-watcher.log"
PID_FILE="/tmp/obsidian-watcher.pid"
# Debounce через latency fswatch (секунды)
DEBOUNCE_SECONDS=5
FSWATCH="/opt/homebrew/bin/fswatch"

# PID дочернего процесса fswatch
FSWATCH_PID=""

# ---------------------------------------------------------------------------
# Логирование
# ---------------------------------------------------------------------------
log() {
    local level="$1"
    shift
    # Пишем только в stdout — launchd перенаправит в LOG_FILE через StandardOutPath
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

log_info()  { log "INFO " "$@"; }
log_warn()  { log "WARN " "$@"; }
log_error() { log "ERROR" "$@"; }

# ---------------------------------------------------------------------------
# Проверка зависимостей
# ---------------------------------------------------------------------------
check_dependencies() {
    log_info "Проверяю зависимости..."
    local missing=0

    if [ ! -x "$FSWATCH" ]; then
        log_error "fswatch не найден: $FSWATCH"
        missing=1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl не найден"
        missing=1
    fi

    if [ ! -d "$VAULT_DIR" ]; then
        log_error "Vault не найден: $VAULT_DIR"
        missing=1
    fi

    if [ "$missing" -eq 1 ]; then
        log_error "Отсутствуют обязательные зависимости. Выход."
        exit 1
    fi

    log_info "Все зависимости OK"
}

# ---------------------------------------------------------------------------
# Graceful shutdown
# ---------------------------------------------------------------------------
cleanup() {
    log_info "Получен сигнал завершения. Останавливаюсь..."
    if [ -n "$FSWATCH_PID" ] && kill -0 "$FSWATCH_PID" 2>/dev/null; then
        kill "$FSWATCH_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
    log_info "Демон остановлен."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# ---------------------------------------------------------------------------
# Запись PID файла
# ---------------------------------------------------------------------------
write_pid() {
    echo $$ > "$PID_FILE"
    log_info "PID $$ записан в $PID_FILE"
}

# ---------------------------------------------------------------------------
# Фильтрация — возвращает 0 если файл нужно обработать
# ---------------------------------------------------------------------------
should_process() {
    local filepath="$1"

    # Игнорируем системные директории
    case "$filepath" in
        */.obsidian/*) return 1 ;;
        */.trash/*)    return 1 ;;
        */.git/*)      return 1 ;;
        *.tmp)         return 1 ;;
        *.swp)         return 1 ;;
        *~)            return 1 ;;
        *.md)          return 0 ;;
        *)             return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Отправка уведомления агенту
# ---------------------------------------------------------------------------
send_to_agent() {
    local filename="$1"
    local message="📝 Изменён файл в Obsidian: ${filename}. Проверь связи и предложи линковку через [[wikilinks]] если уместно."

    log_info "Отправляю уведомление для файла: $filename"

    # Экранируем JSON через python3
    local message_json
    message_json=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$message" 2>/dev/null) || \
        message_json='"'"$(echo "$message" | sed 's/"/\\"/g')"'"'

    local payload="{\"message\":${message_json},\"model\":\"${MODEL}\"}"

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $WEBHOOK_TOKEN" \
        -d "$payload" \
        --connect-timeout 5 \
        --max-time 10 2>/dev/null) || response="000"

    if [ "$response" = "200" ] || [ "$response" = "202" ] || [ "$response" = "204" ]; then
        log_info "Уведомление отправлено (HTTP $response)"
    else
        log_warn "Неожиданный HTTP ответ: $response"
    fi
}

# ---------------------------------------------------------------------------
# Основной цикл
# ---------------------------------------------------------------------------
main_loop() {
    log_info "Запускаю fswatch (latency=${DEBOUNCE_SECONDS}с)..."

    "$FSWATCH" \
        --recursive \
        --event Created \
        --event Updated \
        --event Renamed \
        --event MovedTo \
        --latency "$DEBOUNCE_SECONDS" \
        --exclude "/\\.obsidian/" \
        --exclude "/\\.trash/" \
        --exclude "/\\.git/" \
        --exclude "\\.tmp\$" \
        --exclude "\\.swp\$" \
        --exclude "~\$" \
        "$VAULT_DIR" 2>/dev/null | while IFS= read -r filepath; do

        # Фильтруем — только .md файлы
        if ! should_process "$filepath"; then
            continue
        fi

        local filename
        filename=$(basename "$filepath")
        log_info "Изменён файл: $filename"

        send_to_agent "$filename"

    done

    log_warn "fswatch завершился"
}

# ---------------------------------------------------------------------------
# Точка входа
# ---------------------------------------------------------------------------
main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    log_info "=========================================="
    log_info "Obsidian Watcher стартует (PID $$)"
    log_info "Vault: $VAULT_DIR"
    log_info "Webhook: $WEBHOOK_URL"
    log_info "Debounce: ${DEBOUNCE_SECONDS}с"
    log_info "=========================================="

    check_dependencies
    write_pid

    # Основной цикл с автоперезапуском при падении fswatch
    while true; do
        main_loop || true
        log_warn "Перезапускаю через 5 сек..."
        sleep 5
    done
}

main "$@"
