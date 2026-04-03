#!/bin/bash
# Create presentation from outline
# Usage: create-presentation.sh "Title" [input.txt] [output.pdf]

set -e

TITLE="${1:-Презентация}"
INPUT="${2:-}"
OUTPUT="${3:-$HOME/Desktop/presentation.pdf}"

# Determine output format from extension
EXT="${OUTPUT##*.}"

# Create temp markdown file
TEMP_MD=$(mktemp /tmp/presentation.XXXXXX.md)

cat > "$TEMP_MD" << EOF
---
marp: true
theme: default
paginate: true
---

# $TITLE

EOF

if [ -n "$INPUT" ] && [ -f "$INPUT" ]; then
    # Convert input file to slides
    # Each paragraph becomes a slide
    while IFS= read -r line || [ -n "$line" ]; do
        if [ -z "$line" ]; then
            echo -e "\n---\n" >> "$TEMP_MD"
        else
            echo "$line" >> "$TEMP_MD"
        fi
    done < "$INPUT"
else
    cat >> "$TEMP_MD" << 'EOF'

---

## Содержание

- Пункт 1
- Пункт 2
- Пункт 3

---

## Заключение

Спасибо за внимание!

EOF
fi

echo "📊 Creating presentation: $OUTPUT"
marp "$TEMP_MD" -o "$OUTPUT" --allow-local-files

rm "$TEMP_MD"
echo "✅ Done: $OUTPUT"
