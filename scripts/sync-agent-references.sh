#!/bin/bash
# sync-agent-references.sh — синхронизация references/ для всех агентов
# Создаёт симлинки на файлы из общего references/ в workspace каждого агента
# Удаляет битые симлинки если файл удалён из источника

SOURCE="${WORKSPACE_PATH:-$HOME/workspace}/references"
AGENTS_DIR="$HOME/.openclaw/agents"
AGENTS="producer teamlead kaizen hank skyler marketing-funnel researcher"

added=0
removed=0

for agent in $AGENTS; do
  target="$AGENTS_DIR/$agent/agent/references"
  mkdir -p "$target"

  # 1. Создаём симлинки на новые файлы
  for file in "$SOURCE"/*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    link="$target/$name"
    if [ ! -e "$link" ]; then
      ln -s "$file" "$link"
      echo "🔗 $agent: +$name"
      added=$((added + 1))
    fi
  done

  # 2. Удаляем битые симлинки (файл удалён из источника)
  for link in "$target"/*; do
    [ -L "$link" ] || continue
    if [ ! -e "$link" ]; then
      name=$(basename "$link")
      rm "$link"
      echo "🗑  $agent: -$name (битый симлинк)"
      removed=$((removed + 1))
    fi
  done
done

if [ $added -eq 0 ] && [ $removed -eq 0 ]; then
  echo "✅ Всё синхронизировано, изменений нет"
else
  echo "📊 Добавлено: $added, удалено: $removed"
fi
