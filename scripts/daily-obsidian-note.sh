#!/bin/bash
# Ежедневная заметка в Obsidian через Gemini CLI
# Запускается кроном в 23:30 по {{CITY}} (до Кайдзена в 23:55)

set -euo pipefail

# Если передали дату — используем её, иначе сегодня
if [ -n "${1:-}" ]; then
  DATE="$1"
else
  DATE=$(date +%Y-%m-%d)
fi

OBSIDIAN_DIR="${WORKSPACE_PATH:-$HOME/workspace}/obsidian/daily"
OUTPUT="$OBSIDIAN_DIR/$DATE.md"
MEMORY_DIR="${WORKSPACE_PATH:-$HOME/workspace}/memory"
SESSION_DB="$HOME/.openclaw/memory/main.sqlite"
TMPFILE=$(mktemp)

# Перезаписывать — memory/ файл мог обновиться за день
# Бэкап если был
if [ -f "$OUTPUT" ]; then
  cp "$OUTPUT" "$OUTPUT.bak" 2>/dev/null || true
fi

mkdir -p "$OBSIDIAN_DIR"

# Собираем контекст
CONTEXT=""

# 1. Memory файл за этот день
if [ -f "$MEMORY_DIR/$DATE.md" ]; then
  CONTEXT="$CONTEXT

--- MEMORY FILE ($DATE.md) ---
$(cat "$MEMORY_DIR/$DATE.md")"
fi

# 2. Memory-session файл
if [ -f "$MEMORY_DIR/${DATE}-session.md" ]; then
  CONTEXT="$CONTEXT

--- SESSION SUMMARY ---
$(cat "$MEMORY_DIR/${DATE}-session.md")"
fi

# 3. Из sessionMemory (sqlite) — последние 30 часов (ловит late-night разговоры)
if [ -f "$SESSION_DB" ]; then
  RECENT=$(sqlite3 "$SESSION_DB" "SELECT text FROM chunks WHERE updated_at >= datetime('now', '-30 hours') ORDER BY rowid DESC LIMIT 30;" 2>/dev/null || echo "")
  if [ -n "$RECENT" ]; then
    # Обрезаем до ~8000 символов чтобы не перегрузить
    CONTEXT="$CONTEXT

--- SESSION TRANSCRIPTS ---
$(echo "$RECENT" | head -c 8000)"
  fi
fi

# 4. Memory файл за вчера (если создан после 23:30 — мог не попасть)
YESTERDAY=$(python3 -c "from datetime import datetime,timedelta; print((datetime.strptime('$DATE','%Y-%m-%d')-timedelta(1)).strftime('%Y-%m-%d'))")
if [ -f "$MEMORY_DIR/$YESTERDAY.md" ]; then
  CONTEXT="$CONTEXT

--- LATE-NIGHT MEMORY ($YESTERDAY.md, tail) ---
$(tail -30 "$MEMORY_DIR/$YESTERDAY.md")"
fi

# Навигация
# macOS date arithmetic
YESTERDAY=$(python3 -c "from datetime import datetime,timedelta; print((datetime.strptime('$DATE','%Y-%m-%d')-timedelta(1)).strftime('%Y-%m-%d'))")
TOMORROW=$(python3 -c "from datetime import datetime,timedelta; print((datetime.strptime('$DATE','%Y-%m-%d')+timedelta(1)).strftime('%Y-%m-%d'))")

# Промпт для Gemini
# Записываем контекст во временный файл для stdin
CTXFILE=$(mktemp)
cat > "$CTXFILE" <<CTXEOF
Напиши дневную заметку в формате Markdown на русском за $DATE. Используй ТОЛЬКО информацию из контекста ниже. Не выдумывай. Если данных мало — пиши кратко.

ОБЯЗАТЕЛЬНО:
- Все имена людей, проекты, инструменты, скиллы, технологии оборачивай в [[двойные скобки]] — это Obsidian wikilinks
- Примеры: [[{{AGENT_NICKNAME}}]], [[OpenClaw]], [[Telegram]], [[{{FAMILY_MEMBER_1}}]], [[{{FAMILY_MEMBER_2}}]], [[n8n]], [[SQLite]], [[{{CAR_MODEL}}]], [[AI Штаб]], [[Кайдзен]], [[Tribute]], [[GitHub]], [[Docker]], [[Obsidian]]
- В секции "Связи дня" покажи граф связей в формате [[A]] → [[B]]

Формат:
# 📅 $DATE

## 🎯 Главное за день
(2-3 строки с [[wikilinks]])

## 📋 Что сделали
(список с [[wikilinks]] на каждый проект/инструмент/человека)

## 💡 Решения
(ключевые решения с обоснованием, [[wikilinks]])

## 📝 Заметки
(наблюдения, открытые вопросы)

## 🔗 Связи дня
(граф: [[A]] → [[B]], [[C]] → [[D]])

---
⬅️ [[$YESTERDAY]] | ➡️ [[$TOMORROW]]

Контекст:
$CONTEXT
CTXEOF

# Запуск Gemini через stdin
perl -e 'alarm 90; exec @ARGV' -- gemini -p "$(cat "$CTXFILE")" > "$TMPFILE" 2>/dev/null || true
rm -f "$CTXFILE"

if [ -s "$TMPFILE" ]; then
  # Убираем markdown code fences если Gemini обернул
  sed -i '' '/^```markdown$/d;/^```$/d' "$TMPFILE"
  mv "$TMPFILE" "$OUTPUT"
  echo "✅ Daily note created: $OUTPUT"
else
  echo "❌ Failed to create note for $DATE"
  rm -f "$TMPFILE"
  exit 1
fi

# === ЗАПОЛНЕНИЕ ПУСТЫХ WIKILINKS ===
fill_empty_links() {
    local date="$1"
    local note_file="$OBSIDIAN_DIR/$date.md"
    [ -f "$note_file" ] || return

    local vault_dir
    vault_dir=$(dirname "$OBSIDIAN_DIR")
    local refs_dir="$vault_dir/references"
    mkdir -p "$refs_dir"

    # Извлекаем все wikilinks из заметки
    python3 - "$note_file" "$refs_dir" "$vault_dir" << 'PYEOF'
import re, sys, os
from pathlib import Path

note_file, refs_dir, vault_dir = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(note_file).read()
links = re.findall(r'\[\[([^\]|#\d][^\]|#]*?)(?:\|[^\]]+)?\]\]', content)

for link in set(links):
    link = link.strip()
    # Ищем файл в vault
    found = any(
        f.stem == link
        for f in Path(vault_dir).rglob("*.md")
    )
    if not found:
        # Создаём заглушку — Gemini заполнит позже
        ref_file = os.path.join(refs_dir, f"{link}.md")
        if not os.path.exists(ref_file):
            with open(ref_file, "w") as f:
                f.write(f"# {link}\n\n_TODO: заполнить описание_\n\n## Связи\n- [[{{AGENT_NICKNAME}}]]\n")
            print(f"Created stub: {link}.md")
PYEOF
}

# Запускаем проверку после создания заметки
if [ -f "$OUTPUT" ]; then
    fill_empty_links "$DATE"
fi
