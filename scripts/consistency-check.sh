#!/bin/bash
# consistency-check.sh — Проверка консистентности данных между файлами
# Запускается раз в неделю (крон). Не использует LLM, 0 токенов.
# Выводит противоречия для ручной проверки.

set -uo pipefail

WS="${WORKSPACE_PATH:-${HOME}/workspace}"
ISSUES=()

# === Функция: проверяем конкретное значение в нескольких файлах ===
# Ищет ТОЧНЫЙ паттерн и сравнивает найденные значения
check_exact() {
  local label="$1"
  local pattern="$2"
  shift 2
  local files=("$@")
  local found_in=()
  local values=()

  for f in "${files[@]}"; do
    if [ -f "$WS/$f" ]; then
      local match=$(grep -iP "$pattern" "$WS/$f" 2>/dev/null | head -1)
      if [ -n "$match" ]; then
        found_in+=("$f")
        values+=("$(echo "$match" | sed 's/^[[:space:]]*//')")
      fi
    fi
  done

  if [ ${#found_in[@]} -gt 1 ]; then
    local unique=$(printf '%s\n' "${values[@]}" | sort -u | wc -l)
    if [ "$unique" -gt 1 ]; then
      ISSUES+=("⚠️ $label — разные значения:")
      for i in "${!found_in[@]}"; do
        ISSUES+=("   ${found_in[$i]}: ${values[$i]}")
      done
    fi
  fi
}

echo "🔍 Проверка консистентности данных..."
echo "Дата: $(date '+%Y-%m-%d %H:%M')"
echo ""

# === Проверки ===

# Ребёнок - школа
check_exact "Школа" "{{FAMILY_MEMBER_2}}.*школ|школ.*{{FAMILY_MEMBER_2}}" \
  "USER.md" "MEMORY.md" "memory/family-profile.md"

# Доход — конкретная сумма
check_exact "Доход" '\$[0-9,]+.*мес|\bдоход.*\$' \
  "MEMORY.md" "memory/marketing-strategy.md"

# YouTube подписчики — конкретное число
check_exact "YouTube подписчики" '[0-9][.,]?[0-9]*K?\s*(YouTube|подписчик.*YouTube)|(YouTube|youtube).*[0-9][.,]?[0-9]*K?\s*подписчик' \
  "MEMORY.md" "memory/marketing-strategy.md"

# Telegram подписчики — конкретное число
check_exact "Telegram подписчики" '{{TELEGRAM_CHANNEL}}.*[0-9]|Telegram.*[0-9][.,]?[0-9]*K' \
  "MEMORY.md" "memory/marketing-strategy.md"

# ВНЖ — дата продления
check_exact "ВНЖ дата" '{{VNJ_DATE}}' \
  "MEMORY.md" "HEARTBEAT.md" "memory/location-profile.md"

# Питомец — дата последней дозы лекарства
check_exact "Питомец лекарство" '{{PET_MEDICINE_DATE}}.*{{PET_MEDICINE}}|{{PET_MEDICINE}}.*{{PET_MEDICINE_DATE}}' \
  "HEARTBEAT.md" "memory/pet-profile.md"

# Адрес
check_exact "Адрес" '{{DISTRICT}}|{{OWNER_DISTRICT}}' \
  "USER.md" "memory/location-profile.md"

# === Проверка MEMORY.md размера ===
MEM_SIZE=$(wc -c < "$WS/MEMORY.md" 2>/dev/null || echo 0)
if [ "$MEM_SIZE" -gt 3191 ]; then
  ISSUES+=("🔴 MEMORY.md = ${MEM_SIZE} символов (лимит 3191!)")
fi

# === Проверка дубликатов между bootstrap файлами ===
# Ищем содержательные одинаковые строки (>30 символов)
DUPES=$(cat "$WS/AGENTS.md" "$WS/TOOLS.md" "$WS/IDENTITY.md" 2>/dev/null | \
  awk 'length > 30' | sort | uniq -d | grep -v "^$\|^#\|^-\|^\*\|^|\|^\`\`\`" | head -5)
if [ -n "$DUPES" ]; then
  ISSUES+=("📋 Дубликаты между bootstrap файлами:")
  while IFS= read -r line; do
    ISSUES+=("   $line")
  done <<< "$DUPES"
fi

# === Результат ===
echo ""
if [ "${#ISSUES[@]}" -eq 0 ]; then
  echo "✅ ALL_CONSISTENT — противоречий не найдено"
else
  echo "⚠️ Найдено ${#ISSUES[@]} потенциальных проблем:"
  echo ""
  for issue in "${ISSUES[@]}"; do
    echo "$issue"
  done
fi
