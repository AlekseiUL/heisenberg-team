#!/bin/bash
# Поиск через локальный SearxNG (Docker)
# Использование: web-search.sh "запрос" [количество]
QUERY="$1"
COUNT="${2:-5}"
LANG="${3:-ru}"

if [ -z "$QUERY" ]; then
  echo "Usage: web-search.sh 'query' [count] [lang]"
  exit 1
fi

ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))")

curl -s "http://localhost:8888/search?q=${ENCODED}&format=json&language=${LANG}" 2>/dev/null | \
  python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    results = data.get('results', [])[:${COUNT}]
    if not results:
        print('Ничего не найдено')
        sys.exit(0)
    for i, r in enumerate(results, 1):
        print(f\"{i}. {r.get('title', 'N/A')}\")
        print(f\"   URL: {r.get('url', '')}\")
        content = r.get('content', '')[:200]
        if content:
            print(f\"   {content}\")
        print()
except Exception as e:
    print(f'Ошибка: {e}')
"
