#!/bin/bash
# Удаляет кроновые/isolated сессии из vectorDB
# Оставляет только main-сессии (диалоги с пользователем)
set -euo pipefail

DB="$HOME/.openclaw/memory/main.sqlite"
SESSIONS_MAIN="$HOME/.openclaw/agents/main/sessions/sessions.json"
SESSIONS_KAIZEN="$HOME/.openclaw/agents/kaizen/sessions/sessions.json"

python3 << 'PYEOF'
import json, sqlite3

run_ids = set()

for path in [
    "$HOME/.openclaw/agents/main/sessions/sessions.json",
    "$HOME/.openclaw/agents/kaizen/sessions/sessions.json"
]:
    try:
        with open(path) as f:
            sessions = json.load(f)
        for key, val in sessions.items():
            if ":run:" in key or "isolated" in key.lower():
                sid = val.get("sessionId", val.get("id", ""))
                if sid:
                    run_ids.add(sid)
    except:
        pass

db = sqlite3.connect("$HOME/.openclaw/memory/main.sqlite")
total = 0
for sid in run_ids:
    cursor = db.execute("SELECT COUNT(*) FROM chunks WHERE source='sessions' AND path LIKE ?", (f"%{sid}%",))
    count = cursor.fetchone()[0]
    if count > 0:
        db.execute("DELETE FROM chunks WHERE source='sessions' AND path LIKE ?", (f"%{sid}%",))
        total += count

db.commit()

# Итог
cursor = db.execute("SELECT source, COUNT(*) FROM chunks GROUP BY source")
stats = dict(cursor.fetchall())
db.close()

print(f"Удалено: {total} кроновых чанков. Осталось: memory={stats.get('memory',0)}, sessions={stats.get('sessions',0)}")
PYEOF
