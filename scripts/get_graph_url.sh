#!/bin/bash
# Получить публичную ссылку на граф памяти (через ngrok)
# БЕЗОПАСНАЯ ВЕРСИЯ: экспозит ТОЛЬКО graph.html и graph.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SAFE_DIR="/tmp/graph-public"  # Изолированная папка для публикации
HTTP_PORT=8001
NGROK_API="http://localhost:4040/api/tunnels"

cd "$PROJECT_DIR"

# 1. Обновляем граф с актуальными данными
bash "$SCRIPT_DIR/export_graph.sh" > /dev/null

# 2. Создаём изолированную папку и копируем ТОЛЬКО граф
[ -z "$SAFE_DIR" ] && echo "ERROR: SAFE_DIR is empty, aborting" && exit 1
rm -rf "$SAFE_DIR"
mkdir -p "$SAFE_DIR"
cp graph.html "$SAFE_DIR/"
cp graph.json "$SAFE_DIR/"

# Добавляем простой index.html с редиректом
cat > "$SAFE_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html><head><meta http-equiv="refresh" content="0;url=graph.html"></head></html>
EOF

# 3. Останавливаем старый сервер если работает
pkill -f "python3 -m http.server $HTTP_PORT" 2>/dev/null || true
sleep 1

# 4. Запускаем HTTP-сервер из ИЗОЛИРОВАННОЙ папки
cd "$SAFE_DIR"
python3 -m http.server $HTTP_PORT --bind 127.0.0.1 > /dev/null 2>&1 &
sleep 2

# 5. Проверяем ngrok
if ! ps aux | grep -q "[n]grok http"; then
    pkill -9 ngrok 2>/dev/null || true
    sleep 1
    ngrok http $HTTP_PORT --log stdout > /tmp/ngrok.log 2>&1 &
    sleep 3
fi

# 6. Получаем публичный URL из ngrok API
NGROK_URL=$(curl -s $NGROK_API | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        if tunnel.get('proto') == 'https':
            print(tunnel['public_url'])
            break
except:
    pass
" 2>/dev/null)

if [ -z "$NGROK_URL" ]; then
    echo "❌ Не удалось получить ngrok URL"
    exit 1
fi

# 7. Возвращаем URL
echo "$NGROK_URL/graph.html?v=$(date +%s)"
