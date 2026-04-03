#!/bin/bash
# Очистка scratchpad — файлы старше 7 дней
# Используем trash (macos-trash) вместо rm — правило workspace
SCRATCHPAD_DIR="${WORKSPACE_PATH:-$HOME/workspace}/memory/scratchpad"
DELETED=0

if [ -d "$SCRATCHPAD_DIR" ]; then
  find "$SCRATCHPAD_DIR" -type f -mtime +7 -print0 | while IFS= read -r -d '' file; do
    if [ "$(basename "$file")" != ".gitkeep" ]; then
      if command -v trash &>/dev/null; then
        trash "$file"
      else
        rm "$file"  # fallback если trash не установлен
      fi
      ((DELETED++)) || true
    fi
  done
fi

echo "Scratchpad cleanup: deleted $DELETED files"
