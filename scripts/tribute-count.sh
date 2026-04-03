#!/bin/bash
# Быстрый подсчёт подписчиков {{PAID_GROUP_NAME}} из snapshot Скайлер
# Использование: bash scripts/tribute-count.sh
SNAPSHOTS=~/.openclaw/agents/skyler/agent/data/snapshots
LATEST=$(ls "$SNAPSHOTS"/*.json 2>/dev/null | sort | tail -1)
if [ -z "$LATEST" ]; then echo "NO_DATA"; exit 1; fi
DATE=$(basename "$LATEST" .json)
COUNT=$(cat "$LATEST" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len([s for s in d.get('result',[]) if s.get('subscriptionId')==175104]))")
echo "TRIBUTE|$DATE|$COUNT"
