#!/bin/bash
# =============================================================================
# system-health-monitor.sh — Демон мониторинга здоровья системы
#
# Каждые 60 секунд проверяет:
#   1. Диск: свободное место < 10GB → алерт
#   2. Docker: доступность и статус контейнеров
#   3. Gateway: http://127.0.0.1:18789/health (3 попытки с паузой 10с)
#   4. Memory WAL: SQLite WAL mode для ~/.openclaw/memory/main.sqlite
#
# Алерты с cooldown 15 минут (хранятся в /tmp файлах).
# Совместим с macOS bash 3.2 (без declare -A)
#
# Автор: {{AGENT_NICKNAME}} 🦀 | Дата: 2026-03-03
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Конфигурация
# ---------------------------------------------------------------------------
WEBHOOK_URL="http://127.0.0.1:18789/hooks/wake"
WEBHOOK_TOKEN="${WEBHOOK_TOKEN:-}"
LOG_FILE="$HOME/.openclaw/logs/system-health.log"
PID_FILE="/tmp/system-health-monitor.pid"

# Интервал проверок (секунды)
CHECK_INTERVAL=60

# Порог свободного места на диске (GB)
DISK_FREE_THRESHOLD_GB=10

# Cooldown между одинаковыми алертами (секунды: 15 минут)
ALERT_COOLDOWN=900

# Gateway: количество попыток и пауза между ними
GATEWAY_RETRY_COUNT=3
GATEWAY_RETRY_PAUSE=10

# SQLite база памяти
SQLITE_DB="$HOME/.openclaw/memory/main.sqlite"

# Директория для cooldown-файлов (по одному на тип алерта)
COOLDOWN_DIR="/tmp/openclaw-health-cooldown"

# ---------------------------------------------------------------------------
# Логирование
# ---------------------------------------------------------------------------
log() {
    local level="$1"
    shift
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

log_info()     { log "INFO " "$@"; }
log_warn()     { log "WARN " "$@"; }
log_error()    { log "ERROR" "$@"; }
log_critical() { log "CRIT!" "$@"; }

# ---------------------------------------------------------------------------
# Проверка зависимостей
# ---------------------------------------------------------------------------
check_dependencies() {
    log_info "Проверяю зависимости..."
    local missing=0

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl не найден"
        missing=1
    fi

    if ! command -v sqlite3 >/dev/null 2>&1; then
        log_error "sqlite3 не найден"
        missing=1
    fi

    if ! command -v df >/dev/null 2>&1; then
        log_error "df не найден"
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
# Cooldown: проверить можно ли слать алерт по данному типу
# Возвращает 0 (да, слать) или 1 (нет, cooldown ещё идёт)
# ---------------------------------------------------------------------------
cooldown_ok() {
    local alert_type="$1"
    local cooldown_file="${COOLDOWN_DIR}/${alert_type}.ts"
    local now
    now=$(date +%s)

    if [ -f "$cooldown_file" ]; then
        local last_sent
        last_sent=$(cat "$cooldown_file" 2>/dev/null || echo "0")
        local elapsed=$(( now - last_sent ))
        if [ "$elapsed" -lt "$ALERT_COOLDOWN" ]; then
            local remaining=$(( ALERT_COOLDOWN - elapsed ))
            log_info "Алерт '$alert_type' на cooldown (ещё ${remaining}с)"
            return 1
        fi
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Cooldown: обновить timestamp для типа алерта
# ---------------------------------------------------------------------------
cooldown_set() {
    local alert_type="$1"
    local cooldown_file="${COOLDOWN_DIR}/${alert_type}.ts"
    date +%s > "$cooldown_file"
}

# ---------------------------------------------------------------------------
# Отправка алерта
# $1 - тип алерта (уникальный ключ cooldown)
# $2 - текст сообщения
# $3 - "critical" или "warn"
# ---------------------------------------------------------------------------
send_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="${3:-warn}"

    # Проверяем cooldown
    if ! cooldown_ok "$alert_type"; then
        return 0
    fi

    # Формируем текст
    local prefix="⚠️"
    if [ "$severity" = "critical" ]; then
        prefix="🚨 КРИТИЧНО"
    fi

    local full_message="${prefix}: ${message}"
    log_warn "Отправляю алерт [$alert_type]: $full_message"

    # Экранируем JSON
    local message_json
    message_json=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$full_message" 2>/dev/null) || \
        message_json='"'"$(echo "$full_message" | sed 's/"/\\"/g')"'"'

    local payload="{\"message\":${message_json}}"

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $WEBHOOK_TOKEN" \
        -d "$payload" \
        --connect-timeout 5 \
        --max-time 10 2>/dev/null) || response="000"

    if [ "$response" = "200" ] || [ "$response" = "202" ] || [ "$response" = "204" ]; then
        log_info "Алерт отправлен (HTTP $response)"
        cooldown_set "$alert_type"
    else
        log_error "Не удалось отправить алерт (HTTP $response)"
        # Не обновляем cooldown — попробуем снова
    fi
}

# ---------------------------------------------------------------------------
# Проверка 1: Свободное место на диске
# ---------------------------------------------------------------------------
check_disk() {
    local free_kb
    # df -k возвращает размеры в KB
    free_kb=$(df -k / | awk 'NR==2 {print $4}')

    local free_gb=$(( free_kb / 1024 / 1024 ))

    log_info "Диск: свободно ${free_gb}GB"

    if [ "$free_gb" -lt "$DISK_FREE_THRESHOLD_GB" ]; then
        send_alert "disk_space" \
            "Мало места на диске! Свободно только ${free_gb}GB (порог: ${DISK_FREE_THRESHOLD_GB}GB). Нужна очистка!" \
            "warn"
    fi
}

# ---------------------------------------------------------------------------
# Проверка 2: Docker
# ---------------------------------------------------------------------------
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_info "Docker не установлен — пропускаю"
        return 0
    fi

    # Проверяем доступность daemon
    if ! docker info >/dev/null 2>&1; then
        send_alert "docker_daemon" \
            "Docker daemon не отвечает! Проверь что Docker Desktop запущен." \
            "warn"
        return 0
    fi

    log_info "Docker daemon: OK"

    # Ищем упавшие контейнеры (exited с кодом != 0 и dead)
    local exited_containers
    exited_containers=$(docker ps -a --filter "status=exited" --filter "exited=1" --format "{{.Names}}" 2>/dev/null || true)

    local dead_containers
    dead_containers=$(docker ps -a --filter "status=dead" --format "{{.Names}}" 2>/dev/null || true)

    local bad_containers=""
    if [ -n "$exited_containers" ]; then
        bad_containers="exited: $exited_containers"
    fi
    if [ -n "$dead_containers" ]; then
        if [ -n "$bad_containers" ]; then
            bad_containers="${bad_containers}, dead: $dead_containers"
        else
            bad_containers="dead: $dead_containers"
        fi
    fi

    if [ -n "$bad_containers" ]; then
        send_alert "docker_containers" \
            "Docker: проблемные контейнеры! ${bad_containers}" \
            "warn"
    else
        log_info "Docker контейнеры: OK"
    fi
}

# ---------------------------------------------------------------------------
# Проверка 3: Gateway health (3 попытки, пауза 10с)
# ---------------------------------------------------------------------------
check_gateway() {
    local gateway_url="http://127.0.0.1:18789/health"
    local attempt=1
    local success=0

    while [ "$attempt" -le "$GATEWAY_RETRY_COUNT" ]; do
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            "$gateway_url" \
            --connect-timeout 5 \
            --max-time 10 2>/dev/null) || response="000"

        if [ "$response" = "200" ]; then
            log_info "Gateway: OK (попытка $attempt)"
            success=1
            break
        else
            log_warn "Gateway: попытка $attempt/$GATEWAY_RETRY_COUNT — HTTP $response"
            if [ "$attempt" -lt "$GATEWAY_RETRY_COUNT" ]; then
                sleep "$GATEWAY_RETRY_PAUSE"
            fi
        fi

        attempt=$(( attempt + 1 ))
    done

    if [ "$success" -eq 0 ]; then
        send_alert "gateway_health" \
            "Gateway не отвечает! ${GATEWAY_RETRY_COUNT} попыток неудачно. URL: $gateway_url. Перезапуск: openclaw gateway restart" \
            "critical"
    fi
}

# ---------------------------------------------------------------------------
# Проверка 4: SQLite WAL mode
# ---------------------------------------------------------------------------
check_memory_wal() {
    if [ ! -f "$SQLITE_DB" ]; then
        log_warn "SQLite база не найдена: $SQLITE_DB — пропускаю"
        return 0
    fi

    local journal_mode
    journal_mode=$(sqlite3 "$SQLITE_DB" "PRAGMA journal_mode;" 2>/dev/null || echo "error")

    log_info "SQLite journal_mode: $journal_mode"

    if [ "$journal_mode" != "wal" ]; then
        send_alert "sqlite_wal" \
            "КРИТИЧНО: SQLite не в WAL режиме! journal_mode='${journal_mode}' вместо 'wal'. Риск потери данных памяти! Исправить: sqlite3 $SQLITE_DB 'PRAGMA journal_mode=wal;'" \
            "critical"
    fi
}

# ---------------------------------------------------------------------------
# Один цикл всех проверок
# ---------------------------------------------------------------------------
run_checks() {
    log_info "--- Начинаю проверки ---"
    check_disk
    check_docker
    check_gateway
    check_memory_wal
    log_info "--- Проверки завершены, следующий цикл через ${CHECK_INTERVAL}с ---"
}

# ---------------------------------------------------------------------------
# Основной цикл
# ---------------------------------------------------------------------------
main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$COOLDOWN_DIR"

    log_info "=========================================="
    log_info "System Health Monitor стартует (PID $$)"
    log_info "Webhook: $WEBHOOK_URL"
    log_info "Интервал: ${CHECK_INTERVAL}с"
    log_info "Cooldown алертов: ${ALERT_COOLDOWN}с (15 мин)"
    log_info "=========================================="

    check_dependencies
    write_pid

    # Первая проверка сразу при старте
    run_checks

    # Основной цикл
    while true; do
        sleep "$CHECK_INTERVAL"
        run_checks
    done
}

main "$@"
