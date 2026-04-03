#!/bin/bash
# file-hook-watcher.sh — File Hook для мультиагентной системы
# Следит за появлением DONE.md в projects/*/
# При обнаружении → webhook в OpenClaw → уведомление {{OWNER_NAME}}
#
# Управление: launchctl start/stop com.openclaw.file-hook-watcher
# Логи: /tmp/file-hook-watcher.log
# PID: /tmp/file-hook-watcher.pid

PROJECTS_DIR="${WORKSPACE_PATH:-$HOME/workspace}/projects"
BOARD_FILE="${WORKSPACE_PATH:-$HOME/workspace}/references/team-board.md"
HOOK_URL="http://127.0.0.1:18789/hooks/agent"
HOOK_TOKEN="${HOOK_TOKEN:-}"
PID_FILE="/tmp/file-hook-watcher.pid"
LOG_FILE="/tmp/file-hook-watcher.log"
PROCESSED_FILE="/tmp/file-hook-processed.log"
BOARD_HASH_FILE="/tmp/file-hook-board-hash"

echo $$ > "$PID_FILE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Защита от дублей: проверяем не обработан ли уже файл
already_processed() {
  local file="$1"
  touch "$PROCESSED_FILE"
  grep -qF "$file" "$PROCESSED_FILE" 2>/dev/null
}

mark_processed() {
  local file="$1"
  echo "$file" >> "$PROCESSED_FILE"
}

# Сохраняем начальный хэш board
# macOS: shasum есть всегда
if [ -f "$BOARD_FILE" ]; then
  shasum "$BOARD_FILE" | awk '{print $1}' > "$BOARD_HASH_FILE"
fi

log "🔍 File Hook Watcher v2 запущен (PID $$)"
log "   📁 DONE.md: $PROJECTS_DIR/*/DONE.md"
log "   📋 Board: $BOARD_FILE"

# --- BOARD WATCHER (фон) ---
BOARD_SNAPSHOT="/tmp/file-hook-board-snapshot.md"

# Сохраняем начальный снимок board
if [ -f "$BOARD_FILE" ]; then
  cp "$BOARD_FILE" "$BOARD_SNAPSHOT"
fi

(
  fswatch -0 --event Updated "$BOARD_FILE" | while IFS= read -r -d '' changed; do
    # Проверяем что файл реально изменился
    new_hash=$(shasum "$BOARD_FILE" | awk '{print $1}')
    old_hash=$(cat "$BOARD_HASH_FILE" 2>/dev/null)

    if [ "$new_hash" = "$old_hash" ]; then
      continue
    fi
    echo "$new_hash" > "$BOARD_HASH_FILE"

    # DIFF: только НОВЫЕ строки (которых не было в снимке)
    new_lines=$(diff "$BOARD_SNAPSHOT" "$BOARD_FILE" 2>/dev/null | grep "^>" | sed 's/^> //')

    # Обновляем снимок СРАЗУ (до обработки, чтобы не дублить)
    cp "$BOARD_FILE" "$BOARD_SNAPSHOT"

    # Ищем ГОТОВО только среди НОВЫХ строк
    new_done=$(echo "$new_lines" | grep -i "ГОТОВО" | head -3)

    if [ -z "$new_done" ]; then
      log "📋 Board обновлён (нет новых ГОТОВО в diff)"
      continue
    fi

    # Защита от дублей по хэшу
    done_hash=$(echo "$new_done" | shasum | awk '{print $1}')
    if grep -qF "$done_hash" "$PROCESSED_FILE" 2>/dev/null; then
      log "📋 Board: ГОТОВО уже отправлено, пропускаю"
      continue
    fi
    echo "$done_hash" >> "$PROCESSED_FILE"

    log "📋 Board: НОВОЕ ГОТОВО (diff): $(echo "$new_done" | head -1)"

    board_message="🪝 BOARD HOOK: Новая завершённая задача на доске.

$new_done

ЗАДАЧА: Отправь {{OWNER_NAME}} уведомление через message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}) что на доске появилась завершённая задача. Кратко перечисли что готово. После отправки — NO_REPLY."

    curl -s -X POST "$HOOK_URL" \
      -H "Authorization: Bearer $HOOK_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg msg "$board_message" --arg name "BoardHook" '{
        message: $msg,
        name: $name,
        wakeMode: "now",
        deliver: true,
        channel: "telegram",
        to: "{{OWNER_TELEGRAM_ID}}",
        model: "anthropic/claude-sonnet-4-5",
        timeoutSeconds: 60
      }')" > /dev/null 2>&1

    log "📨 Board webhook отправлен"
  done
) &

BOARD_PID=$!
log "📋 Board watcher запущен (PID $BOARD_PID)"

# --- DONE.md WATCHER (основной) ---
fswatch -0 --event Created --event Updated --include 'DONE\.md$' --exclude '.*' "$PROJECTS_DIR" | while IFS= read -r -d '' file; do

  basename_file=$(basename "$file")
  if [ "$basename_file" != "DONE.md" ]; then
    continue
  fi

  # Защита от дублей
  if already_processed "$file"; then
    log "⏭️ Уже обработан: $file"
    continue
  fi

  # Проверяем что файл не пустой
  if [ ! -s "$file" ]; then
    log "⚠️ DONE.md пустой, пропускаю: $file"
    continue
  fi

  project_dir=$(dirname "$file")
  project_name=$(basename "$project_dir")
  done_content=$(head -c 500 "$file")

  log "✅ DONE.md обнаружен: $project_name"

  message="🪝 FILE HOOK: Проект \"$project_name\" завершён.

Содержимое DONE.md:
$done_content

ЗАДАЧА: Отправь {{OWNER_NAME}} уведомление через message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}) что проект $project_name готов. Включи краткое содержание DONE.md. После отправки — NO_REPLY."

  response=$(curl -s -w "\n%{http_code}" -X POST "$HOOK_URL" \
    -H "Authorization: Bearer $HOOK_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg msg "$message" --arg name "FileHook-$project_name" '{
      message: $msg,
      name: $name,
      wakeMode: "now",
      deliver: true,
      channel: "telegram",
      to: "{{OWNER_TELEGRAM_ID}}",
      model: "anthropic/claude-sonnet-4-5",
      timeoutSeconds: 60
    }')")

  http_code=$(echo "$response" | tail -1)

  if [ "$http_code" = "200" ]; then
    log "📨 Webhook OK ($project_name)"
    mark_processed "$file"
  else
    log "❌ Webhook ошибка HTTP $http_code ($project_name)"
  fi

done
