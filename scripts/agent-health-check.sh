#!/bin/bash
# agent-health-check.sh — Еженедельная проверка здоровья агентов
# Запускается Хайзенбергом (крон воскресенье 12:00)
# Выводит ТОЛЬКО проблемы. Если всё чисто — "✅ Все проверки пройдены"

WORKSPACE="${WORKSPACE_PATH:-$HOME/workspace}"
AGENTS_DIR="$HOME/.openclaw/agents"
AGENTS="producer teamlead kaizen hank skyler marketing-funnel researcher"
CONSTITUTION="$WORKSPACE/references/team-constitution.md"
PROBLEMS=0

problem() {
  echo "❌ $1"
  PROBLEMS=$((PROBLEMS + 1))
}

warn() {
  echo "⚠️  $1"
}

echo "🔍 Agent Health Check — $(date '+%Y-%m-%d %H:%M')"
echo "=================================================="

# ═══════════════════════════════════════════
# 1. ФАЙЛЫ И СТРУКТУРА
# ═══════════════════════════════════════════
echo ""
echo "📁 1. Файлы и структура"

REQUIRED_FILES="AGENTS.md BOOTSTRAP.md HEARTBEAT.md IDENTITY.md MEMORY.md SOUL.md TOOLS.md USER.md"
for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  for f in $REQUIRED_FILES; do
    [ -e "$dir/$f" ] || problem "$agent: отсутствует $f"
  done
done

# ═══════════════════════════════════════════
# 2. СИМЛИНКИ
# ═══════════════════════════════════════════
echo ""
echo "🔗 2. Симлинки"

# USER.md должен быть симлинком
for agent in $AGENTS; do
  f="$AGENTS_DIR/$agent/agent/USER.md"
  [ -L "$f" ] || problem "$agent: USER.md не симлинк (расхождение данных!)"
  [ -L "$f" ] && [ ! -r "$f" ] && problem "$agent: USER.md симлинк битый"
done

# references/ симлинки
REF_FILES="team-constitution.md team-board.md active-projects.md"
for agent in $AGENTS; do
  refdir="$AGENTS_DIR/$agent/agent/references"
  [ -d "$refdir" ] || { problem "$agent: нет папки references/"; continue; }
  for f in $REF_FILES; do
    [ -e "$refdir/$f" ] || problem "$agent: references/$f отсутствует"
    [ -L "$refdir/$f" ] && [ ! -r "$refdir/$f" ] && problem "$agent: references/$f битый симлинк"
  done
done

# Битые симлинки (общий скан)
for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  broken=$(find "$dir" -type l ! -exec test -e {} \; -print 2>/dev/null)
  [ -n "$broken" ] && problem "$agent: битые симлинки: $broken"
done

# ═══════════════════════════════════════════
# 3. TIMEOUTS И ПРОТОКОЛ
# ═══════════════════════════════════════════
echo ""
echo "⏱  3. Timeouts и протокол"

for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  # timeoutSeconds=0 (устаревший fire-and-forget)
  count=$(grep -rh "timeoutSeconds=0" "$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -gt 0 ] && problem "$agent: timeoutSeconds=0 найден ($count раз) — должен быть 120"
  
  # timeoutSeconds=60 (тоже устаревший)
  count60=$(grep -rh "timeoutSeconds=60" "$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$count60" -gt 0 ] && problem "$agent: timeoutSeconds=60 найден — должен быть 120"
done

# ═══════════════════════════════════════════
# 4. ПУТИ
# ═══════════════════════════════════════════
echo ""
echo "📍 4. Пути"

for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  
  # {{PAID_GROUP_NAME}}/ без projects/
  bad_paths=$(grep -rhn "{{PAID_GROUP_NAME}}/" "$dir"/*.md 2>/dev/null | grep -v "projects/{{PAID_GROUP_NAME}}\|платная группа\|подписчик\|тарифы")
  [ -n "$bad_paths" ] && problem "$agent: устаревший путь {{PAID_GROUP_NAME}}/ (нужен projects/{{PAID_GROUP_NAME}}/)"
  
  # team-board с полным путём Desktop
  grep -rq "Desktop/.*/team-board" "$dir"/*.md 2>/dev/null && problem "$agent: team-board с полным путём (нужен references/team-board.md)"
done

# ═══════════════════════════════════════════
# 5. ПРОТИВОРЕЧИЯ
# ═══════════════════════════════════════════
echo ""
echo "⚡ 5. Противоречия"

for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  
  # "доставку делает Хайзенберг" (должен Сол)
  grep -rq "доставку делает Хайзенберг" "$dir"/*.md 2>/dev/null && problem "$agent: 'доставку делает Хайзенберг' — должен Сол"
  
  # "polling каждые 45" (устаревший)
  grep -rq "polling каждые 45" "$dir"/*.md 2>/dev/null && problem "$agent: устаревший 'polling каждые 45 сек'"
done

# SessionKey проверка
for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  grep -roh "agent:[a-z-]*:main" "$dir"/*.md 2>/dev/null | sort -u | while read key; do
    id=$(echo "$key" | cut -d: -f2)
    if [ "$id" != "main" ] && [ "$id" != "producer" ] && [ "$id" != "teamlead" ] && [ "$id" != "marketing-funnel" ] && [ "$id" != "kaizen" ] && [ "$id" != "hank" ] && [ "$id" != "skyler" ] && [ "$id" != "researcher" ]; then
      problem "$agent: неизвестный sessionKey $key"
    fi
  done
done

# Telegram ID
for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  wrong_ids=$(grep -roh "to=[0-9]*" "$dir"/*.md 2>/dev/null | grep -v "to={{OWNER_TELEGRAM_ID}}" | sort -u)
  [ -n "$wrong_ids" ] && problem "$agent: неправильный Telegram ID: $wrong_ids"
done

# ═══════════════════════════════════════════
# 6. ВЕС КОНТЕКСТА
# ═══════════════════════════════════════════
echo ""
echo "📊 6. Вес контекста"

for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  total=0
  for f in "$dir"/*.md; do
    [ -f "$f" ] && total=$((total + $(wc -c < "$f")))
  done
  kb=$((total / 1024))
  [ $kb -gt 30 ] && problem "$agent: system prompt ${kb}KB (лимит 30KB)"
  [ $kb -gt 25 ] && [ $kb -le 30 ] && warn "$agent: system prompt ${kb}KB (близко к лимиту)"
done

# MEMORY.md отдельно
for agent in $AGENTS; do
  mem="$AGENTS_DIR/$agent/agent/MEMORY.md"
  [ -f "$mem" ] || continue
  size=$(wc -c < "$mem")
  [ $size -gt 5000 ] && warn "$agent: MEMORY.md ${size} bytes (>5KB, проверить на мусор)"
done

# ═══════════════════════════════════════════
# 7. КОНСТИТУЦИЯ
# ═══════════════════════════════════════════
echo ""
echo "📜 7. Конституция"

# Все ссылаются на конституцию?
for agent in $AGENTS; do
  dir="$AGENTS_DIR/$agent/agent"
  grep -rq "team-constitution.md" "$dir"/TOOLS.md 2>/dev/null || problem "$agent: TOOLS.md не ссылается на конституцию"
done

# ═══════════════════════════════════════════
# 8. ДАННЫЕ ПОД РОЛЬ
# ═══════════════════════════════════════════
echo ""
echo "🎯 8. Данные под роль"

# Пинкман — конкуренты
[ -r "$AGENTS_DIR/marketing-funnel/agent/data/competitors.md" ] || problem "marketing-funnel: нет data/competitors.md"

# Скайлер — Tribute
[ -r "$AGENTS_DIR/skyler/agent/data/secrets/${PAYMENT_API_ENV:-tribute.env}" ] || problem "skyler: нет data/secrets/payment API env"
[ -r "$AGENTS_DIR/skyler/agent/data/subscribers/manual-subscribers.md" ] || problem "skyler: нет data/subscribers/manual-subscribers.md"

# ═══════════════════════════════════════════
# 9. SYNC REFERENCES (свежесть)
# ═══════════════════════════════════════════
echo ""
echo "🔄 9. Sync references"

# Проверяем есть ли файлы в общем references/ без симлинков у агентов
for file in "$WORKSPACE"/references/*.md; do
  [ -f "$file" ] || continue
  name=$(basename "$file")
  for agent in $AGENTS; do
    [ -e "$AGENTS_DIR/$agent/agent/references/$name" ] || warn "$agent: нет references/$name"
  done
done

# ═══════════════════════════════════════════
# ИТОГ
# ═══════════════════════════════════════════
echo ""
echo "=================================================="
if [ $PROBLEMS -eq 0 ]; then
  echo "✅ Все проверки пройдены. Проблем: 0"
else
  echo "🚨 Найдено проблем: $PROBLEMS"
fi
echo "=================================================="
