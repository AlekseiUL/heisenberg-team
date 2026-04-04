#!/bin/bash
set -uo pipefail

# OpenClaw Post-Update Check & Repair Script
# Usage: ./post-update-check.sh

# ==================== CROSS-PLATFORM ====================
# Cross-platform stat
if [[ "$OSTYPE" == "darwin"* ]]; then
  file_mtime() { stat -f "%m" "$1" 2>/dev/null || echo 0; }
  file_size() { stat -f "%z" "$1" 2>/dev/null || echo 0; }
else
  file_mtime() { stat -c "%Y" "$1" 2>/dev/null || echo 0; }
  file_size() { stat -c "%s" "$1" 2>/dev/null || echo 0; }
fi

# Cross-platform gateway restart
restart_gateway_service() {
  local label="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl kickstart -k "gui/$(id -u)/$label" 2>/dev/null
  elif command -v systemctl &>/dev/null; then
    systemctl --user restart openclaw-gateway 2>/dev/null || \
    openclaw gateway restart
  else
    openclaw gateway restart
  fi
}

# Cross-platform service list
service_list() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl list 2>/dev/null || true
  elif command -v systemctl &>/dev/null; then
    systemctl --user list-units --type=service 2>/dev/null || true
  fi
}

service_has() {
  local label="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl list 2>/dev/null | grep -q "$label"
  elif command -v systemctl &>/dev/null; then
    systemctl --user is-active "$label" &>/dev/null
  else
    return 1
  fi
}

service_get_pid() {
  local label="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    launchctl list 2>/dev/null | grep "$label" | awk '{print $1}'
  elif command -v systemctl &>/dev/null; then
    systemctl --user show -p MainPID "$label" 2>/dev/null | cut -d= -f2
  else
    echo "-"
  fi
}

# ==================== CONFIG ====================
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
DB_MAIN="$HOME/.openclaw/memory/main.sqlite"
DB_KAIZEN="$HOME/.openclaw/memory/kaizen.sqlite"
EXPECTED_PORT=18789
GATEWAY_LABEL="ai.openclaw.gateway"

# ==================== COLORS ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== COUNTERS ====================
CHECKED=0
FIXED=0
FAILED=0
FIXES=()
FAILURES=()

# ==================== HELPERS ====================
check_start() {
    CHECKED=$((CHECKED + 1))
    printf "[%2d/24] %-20s " "$CHECKED" "$1"
}

check_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    FAILED=$((FAILED + 1))
    FAILURES+=("$2")
}

check_fixed() {
    echo -e "${BLUE}🔧 $1${NC}"
    FIXED=$((FIXED + 1))
    FIXES+=("$2")
}

# Get OpenClaw version
get_version() {
    openclaw --version 2>/dev/null | head -1 || echo "unknown"
}

# JSON helper using python3
json_get() {
    local file="$1"
    local path="$2"
    python3 -c "
import json, sys
try:
    with open('$file') as f:
        data = json.load(f)
    keys = '$path'.split('.')
    val = data
    for k in keys:
        val = val[k]
    print(val)
except:
    sys.exit(1)
"
}

json_set() {
    local file="$1"
    local path="$2"
    local value="$3"
    python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
keys = '$path'.split('.')
obj = data
for k in keys[:-1]:
    obj = obj[k]
obj[keys[-1]] = $value
with open('$file', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# ==================== HEADER ====================
echo -e "${BLUE}🔍 OpenClaw Post-Update Check${NC}"
echo -e "${BLUE}📦 Version: $(get_version)${NC}"
echo "================================"
echo ""

# ==================== CHECKS ====================

# 1. Gateway
check_start "Gateway"
if service_has "$GATEWAY_LABEL"; then
    PID=$(service_get_pid "$GATEWAY_LABEL")
    if curl -sf http://127.0.0.1:$EXPECTED_PORT/health >/dev/null 2>&1; then
        check_ok "PID $PID"
    else
        # Try to restart
        restart_gateway_service "$GATEWAY_LABEL" >/dev/null 2>&1
        sleep 2
        if curl -sf http://127.0.0.1:$EXPECTED_PORT/health >/dev/null 2>&1; then
            check_fixed "Restarted" "Gateway restarted"
        else
            check_fail "Health check failed" "Gateway not responding"
        fi
    fi
else
    check_fail "Not running" "Gateway service not found"
fi

# 1b. Gateway code freshness (prevent stale binary after update)
check_start "Gateway code freshness"
if [ -n "$PID" ] && [ "$PID" != "-" ]; then
    # Get process start time (epoch seconds)
    PROC_START=$(ps -p "$PID" -o lstart= 2>/dev/null)
    PROC_EPOCH=$(date -j -f "%a %b %d %T %Y" "$PROC_START" "+%s" 2>/dev/null || echo "0")
    # Get code modification time
    OPENCLAW_PKG="/opt/homebrew/lib/node_modules/openclaw/package.json"
    if [ -f "$OPENCLAW_PKG" ]; then
        CODE_EPOCH=$(file_mtime "$OPENCLAW_PKG")
        if [ "$CODE_EPOCH" -gt "$PROC_EPOCH" ]; then
            # Code is newer than running process - stale gateway!
            restart_gateway_service "$GATEWAY_LABEL" >/dev/null 2>&1
            sleep 3
            if curl -sf http://127.0.0.1:$EXPECTED_PORT/health >/dev/null 2>&1; then
                check_fixed "Restarted (code was newer)" "Gateway was running stale code after update"
            else
                check_fail "Restart failed" "Gateway code stale, restart didn't help"
            fi
        else
            check_ok "Code matches running process"
        fi
    else
        check_ok "Skipped (package.json not found)"
    fi
else
    check_ok "Skipped (no PID)"
fi

# 1c. CLI-Gateway connectivity (device signature check)
check_start "CLI-Gateway auth"
openclaw cron list --json > /tmp/openclaw-cli-test.json 2>/dev/null || true
if grep -q '"jobs"' /tmp/openclaw-cli-test.json 2>/dev/null; then
    check_ok "CLI connects OK"
else
    if echo "$CLI_TEST" | grep -qi "signature invalid"; then
        # Signature mismatch - restart gateway
        restart_gateway_service "$GATEWAY_LABEL" >/dev/null 2>&1
        sleep 3
        CLI_RETRY=$(openclaw cron list --json 2>&1)
        if echo "$CLI_RETRY" | grep -q '"jobs"'; then
            check_fixed "Restarted (signature mismatch)" "Gateway had stale device signature protocol"
        else
            check_fail "CLI still can't connect" "Device signature invalid even after restart"
        fi
    else
        check_fail "CLI error: $(head -1 /tmp/openclaw-cli-test.json 2>/dev/null)" "CLI cannot connect to gateway"
    fi
fi

# 2. Port
check_start "Port"
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_PORT=$(json_get "$CONFIG_FILE" "gateway.port" 2>/dev/null || echo "")
    if [ "$CURRENT_PORT" = "$EXPECTED_PORT" ]; then
        check_ok "$EXPECTED_PORT"
    else
        json_set "$CONFIG_FILE" "gateway.port" "$EXPECTED_PORT" 2>/dev/null
        if [ $? -eq 0 ]; then
            check_fixed "Fixed to $EXPECTED_PORT" "Port restored to $EXPECTED_PORT"
        else
            check_fail "Can't fix" "Failed to update port"
        fi
    fi
else
    check_fail "Config missing" "Config file not found"
fi

# 3. Plugins
check_start "Plugins"
PLUGINS_OK=true
for plugin in "memory-core" "telegram" "moltguard"; do
    ENABLED=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
entries = data.get('plugins', {}).get('entries', {})
p = entries.get('$plugin', {})
print(p.get('enabled', True) if p else 'missing')
" 2>/dev/null)
    
    if [ "$ENABLED" != "True" ] && [ "$ENABLED" != "true" ]; then
        python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
data.setdefault('plugins',{}).setdefault('entries',{}).setdefault('$plugin',{})['enabled'] = True
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null
        PLUGINS_OK=false
    fi
done

if $PLUGINS_OK; then
    check_ok "All enabled"
else
    check_fixed "Enabled plugins" "memory-core, telegram, moltguard enabled"
fi

# 4. Hooks
check_start "Hooks"
HOOKS_OK=true
for hook in "boot-md" "session-memory" "command-logger" "custom-skills-loader"; do
    ENABLED=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
entries = data.get('hooks', {}).get('internal', {}).get('entries', {})
h = entries.get('$hook', {})
print(h.get('enabled', False) if h else 'missing')
" 2>/dev/null)
    
    if [ "$ENABLED" != "True" ] && [ "$ENABLED" != "true" ]; then
        python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
data.setdefault('hooks',{}).setdefault('internal',{})['enabled']=True
data['hooks']['internal'].setdefault('entries',{}).setdefault('$hook',{})['enabled']=True
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null
        HOOKS_OK=false
    fi
done

if $HOOKS_OK; then
    check_ok "All enabled"
else
    check_fixed "Enabled hooks" "All hooks enabled"
fi

# 5. SQLite WAL
check_start "SQLite WAL"
WAL_OK=true
for db in "$DB_MAIN" "$DB_KAIZEN"; do
    if [ -f "$db" ]; then
        MODE=$(sqlite3 "$db" "PRAGMA journal_mode;" 2>/dev/null)
        if [ "$MODE" != "wal" ]; then
            sqlite3 "$db" "PRAGMA journal_mode=WAL;" >/dev/null 2>&1
            WAL_OK=false
        fi
    fi
done

if $WAL_OK; then
    check_ok "Both in WAL"
else
    check_fixed "WAL restored" "SQLite WAL mode restored"
fi

# 6. SQLite integrity
check_start "SQLite integrity"
INTEGRITY_OK=true
for db in "$DB_MAIN" "$DB_KAIZEN"; do
    if [ -f "$db" ]; then
        CHECK=$(sqlite3 "$db" "PRAGMA integrity_check;" 2>/dev/null)
        if [ "$CHECK" != "ok" ]; then
            INTEGRITY_OK=false
        fi
        
        # Check empty embeddings
        EMPTY=$(sqlite3 "$db" "SELECT COUNT(*) FROM chunks WHERE embedding IS NULL OR embedding='';" 2>/dev/null || echo "0")
        if [ "$EMPTY" != "0" ]; then
            check_warn "Empty embeddings: $EMPTY"
            INTEGRITY_OK=false
        fi
    fi
done

if $INTEGRITY_OK; then
    check_ok "OK"
else
    check_fail "Issues found" "Database integrity issues"
fi

# 7. memoryFlush
check_start "memoryFlush"
ENABLED=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('agents', {}).get('defaults', {}).get('compaction', {}).get('memoryFlush', {}).get('enabled', False))
" 2>/dev/null)

if [ "$ENABLED" = "True" ]; then
    check_ok "Enabled"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
if 'agents' not in data:
    data['agents'] = {}
if 'defaults' not in data['agents']:
    data['agents']['defaults'] = {}
if 'compaction' not in data['agents']['defaults']:
    data['agents']['defaults']['compaction'] = {}
if 'memoryFlush' not in data['agents']['defaults']['compaction']:
    data['agents']['defaults']['compaction']['memoryFlush'] = {}
data['agents']['defaults']['compaction']['memoryFlush']['enabled'] = True
data['agents']['defaults']['compaction']['memoryFlush']['softThresholdTokens'] = 6000
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null
    check_fixed "Enabled" "memoryFlush enabled"
fi

# 8. sessionMemory
check_start "sessionMemory"
SEARCH_ENABLED=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('agents', {}).get('defaults', {}).get('memorySearch', {}).get('enabled', False))
" 2>/dev/null)

SESSION_ENABLED=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('agents', {}).get('defaults', {}).get('memorySearch', {}).get('experimental', {}).get('sessionMemory', False))
" 2>/dev/null)

if [ "$SEARCH_ENABLED" = "True" ] && [ "$SESSION_ENABLED" = "True" ]; then
    check_ok "Enabled"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
if 'agents' not in data:
    data['agents'] = {}
if 'defaults' not in data['agents']:
    data['agents']['defaults'] = {}
if 'memorySearch' not in data['agents']['defaults']:
    data['agents']['defaults']['memorySearch'] = {}
data['agents']['defaults']['memorySearch']['enabled'] = True
if 'experimental' not in data['agents']['defaults']['memorySearch']:
    data['agents']['defaults']['memorySearch']['experimental'] = {}
data['agents']['defaults']['memorySearch']['experimental']['sessionMemory'] = True
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null
    check_fixed "Enabled" "sessionMemory enabled"
fi

# 9. Heartbeat
check_start "Heartbeat"
HEARTBEAT=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('agents', {}).get('defaults', {}).get('heartbeat', {}).get('every', ''))
" 2>/dev/null)

if [ "$HEARTBEAT" = "1h" ]; then
    check_ok "1h"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
if 'agents' not in data:
    data['agents'] = {}
if 'defaults' not in data['agents']:
    data['agents']['defaults'] = {}
if 'heartbeat' not in data['agents']['defaults']:
    data['agents']['defaults']['heartbeat'] = {}
data['agents']['defaults']['heartbeat']['every'] = '1h'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null
    check_fixed "Set to 1h" "Heartbeat set to 1h"
fi

# 10. Playwright
check_start "Playwright"
echo "" # newline for playwright output
echo -n "   Installing chromium... "
if npx playwright install chromium >/dev/null 2>&1; then
    echo -e "${BLUE}🔧 Installed${NC}"
    FIXED=$((FIXED + 1))
    FIXES+=("Playwright chromium installed")
else
    echo -e "${RED}❌ Failed${NC}"
    FAILED=$((FAILED + 1))
    FAILURES+=("Playwright install failed")
fi

# 11. Cron models
check_start "Cron models"
BAD_CRONS=$(openclaw cron list 2>/dev/null | grep -E "(deepseek|model.*:.*\"\")" | wc -l | tr -d ' ')
if [ "$BAD_CRONS" = "0" ]; then
    check_ok "OK"
else
    check_warn "Found $BAD_CRONS crons with bad models"
fi

# 12. Compaction mode
check_start "Compaction mode"
COMP_MODE=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('agents',{}).get('defaults',{}).get('compaction',{}).get('mode',''))
" 2>/dev/null)
if [ "$COMP_MODE" = "safeguard" ]; then
    check_ok "safeguard"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
data.setdefault('agents',{}).setdefault('defaults',{}).setdefault('compaction',{})['mode']='safeguard'
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "safeguard restored (was: $COMP_MODE)" "Compaction mode → safeguard"
fi

# 13. Gateway bind (security)
check_start "Gateway bind"
GW_BIND=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('gateway',{}).get('bind',''))
" 2>/dev/null)
if [ "$GW_BIND" = "loopback" ]; then
    check_ok "loopback"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
data.setdefault('gateway',{})['bind']='loopback'
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "loopback restored (was: $GW_BIND)" "Gateway bind → loopback (SECURITY FIX)"
fi

# 14. Gateway auth token
check_start "Gateway auth"
HAS_TOKEN=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
t = data.get('gateway',{}).get('auth',{}).get('token','')
print('yes' if len(t) > 10 else 'no')
" 2>/dev/null)
if [ "$HAS_TOKEN" = "yes" ]; then
    check_ok "Token present"
else
    check_fail "NO AUTH TOKEN!" "Gateway auth token missing - anyone can connect!"
fi

# 15. Telegram nativeSkills
check_start "TG nativeSkills"
NATIVE=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
tg = data.get('plugins',{}).get('entries',{}).get('telegram',{})
print(tg.get('nativeSkills', 'unset'))
" 2>/dev/null)
if [ "$NATIVE" = "False" ] || [ "$NATIVE" = "false" ]; then
    check_ok "Disabled (correct)"
elif [ "$NATIVE" = "True" ] || [ "$NATIVE" = "true" ]; then
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
data['plugins']['entries']['telegram']['nativeSkills']=False
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "Disabled (was enabled, 100 cmd limit!)" "nativeSkills → false"
else
    check_ok "Unset (default off)"
fi

# 15b. Telegram allowFrom (prevent lockout after config migration)
check_start "TG allowFrom"
TG_AUTH=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
tg = data.get('channels', {}).get('telegram', {})
problems = []
# Check top-level
if tg.get('dmPolicy') != 'allowlist':
    problems.append('top-level dmPolicy != allowlist')
if '{{OWNER_TELEGRAM_ID}}' not in (tg.get('allowFrom') or []):
    problems.append('top-level allowFrom missing {{OWNER_TELEGRAM_ID}}')
# Check accounts
for name, acc in tg.get('accounts', {}).items():
    if acc.get('dmPolicy') and acc['dmPolicy'] != 'allowlist':
        problems.append(f'accounts.{name}.dmPolicy != allowlist')
    if acc.get('allowFrom') is not None and '{{OWNER_TELEGRAM_ID}}' not in acc['allowFrom']:
        problems.append(f'accounts.{name}.allowFrom missing {{OWNER_TELEGRAM_ID}}')
if problems:
    print('FAIL:' + '; '.join(problems))
else:
    print('OK')
" 2>/dev/null)

if echo "$TG_AUTH" | grep -q "^OK"; then
    check_ok "allowlist + {{OWNER_TELEGRAM_ID}}"
elif echo "$TG_AUTH" | grep -q "^FAIL"; then
    # Auto-fix
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
tg = data['channels']['telegram']
tg['dmPolicy'] = 'allowlist'
tg['allowFrom'] = ['{{OWNER_TELEGRAM_ID}}']
for name, acc in tg.get('accounts', {}).items():
    acc['dmPolicy'] = 'allowlist'
    acc['allowFrom'] = ['{{OWNER_TELEGRAM_ID}}']
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null
    check_fixed "Restored allowlist + {{OWNER_TELEGRAM_ID}}" "TG auth was broken: ${TG_AUTH#FAIL:}"
else
    check_fail "Can't check" "Python error"
fi

# 16. memoryFlush prompt
check_start "Flush prompt"
PROMPT_LEN=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
p = data.get('agents',{}).get('defaults',{}).get('compaction',{}).get('memoryFlush',{}).get('prompt','')
print(len(p))
" 2>/dev/null)
if [ "$PROMPT_LEN" -gt 50 ] 2>/dev/null; then
    check_ok "Present (${PROMPT_LEN} chars)"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
flush = data.setdefault('agents',{}).setdefault('defaults',{}).setdefault('compaction',{}).setdefault('memoryFlush',{})
flush['enabled'] = True
flush['softThresholdTokens'] = 6000
flush['prompt'] = '''Контекст почти заполнен. СРОЧНО запиши в memory/handoff.md:

## Текущий разговор
- Что обсуждали
- Какие решения приняли и почему
- Что осталось сделать
- Открытые вопросы

Формат: краткий, по сути. Это прочитает будущий-ты после компактификации.
После записи ответь NO_REPLY.'''
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "Prompt restored" "memoryFlush prompt restored"
fi

# 17. Model fallback chain
check_start "Model fallbacks"
FALLBACKS_OK=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
m = data.get('agents',{}).get('defaults',{}).get('model',{})
primary = m.get('primary','')
fb = m.get('fallbacks',[])
expected_primary = 'anthropic/claude-opus-4-6'
expected_fb = ['anthropic/claude-opus-4-5','anthropic/claude-sonnet-4-5','anthropic/claude-haiku-4-5','google-gemini-cli/gemini-3-pro-preview']
if primary == expected_primary and fb == expected_fb:
    print('ok')
else:
    print(f'primary={primary} fb={len(fb)}')
" 2>/dev/null)
if [ "$FALLBACKS_OK" = "ok" ]; then
    check_ok "Opus 4.6 → Opus 4.5 → Sonnet → Haiku → Gemini"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
m = data.setdefault('agents',{}).setdefault('defaults',{}).setdefault('model',{})
m['primary'] = 'anthropic/claude-opus-4-6'
m['fallbacks'] = ['anthropic/claude-opus-4-5','anthropic/claude-sonnet-4-5','anthropic/claude-haiku-4-5','google-gemini-cli/gemini-3-pro-preview']
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "Fallback chain restored" "Model fallback chain restored"
fi

# 18. TTS settings
check_start "TTS settings"
TTS_OK=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
tts = data.get('messages',{}).get('tts',{})
provider = tts.get('provider','')
edge = tts.get('edge',{})
voice = edge.get('voice','')
rate = edge.get('rate','')
if provider == 'edge' and voice == 'ru-RU-DmitryNeural' and rate == '+50%':
    print('ok')
else:
    print(f'{provider}/{voice}/{rate}')
" 2>/dev/null)
if [ "$TTS_OK" = "ok" ]; then
    check_ok "Edge/Dmitry/+50%"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
tts = data.setdefault('messages',{}).setdefault('tts',{})
tts['provider'] = 'edge'
e = tts.setdefault('edge',{})
e['enabled'] = True
e['voice'] = 'ru-RU-DmitryNeural'
e['lang'] = 'ru-RU'
e['rate'] = '+50%'
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "TTS restored (was: $TTS_OK)" "TTS → Edge/Dmitry/+50%"
fi

# 19. Kaizen agent
check_start "Kaizen agent"
KAIZEN_OK=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
agents = data.get('agents',{}).get('list',[])
for a in agents:
    if a.get('id') == 'kaizen':
        model = a.get('model','')
        ws = a.get('workspace','')
        if 'sonnet' in model and ('kaizen' in ws or 'obsidian' in ws):
            print('ok')
        else:
            print(f'{model}|{ws}')
        break
else:
    print('missing')
" 2>/dev/null)
if [ "$KAIZEN_OK" = "ok" ]; then
    check_ok "Sonnet, workspace OK"
elif [ "$KAIZEN_OK" = "missing" ]; then
    check_fail "Kaizen MISSING from agents.list!" "Kaizen agent deleted from config"
else
    check_warn "Kaizen config changed: $KAIZEN_OK"
fi

# 20. Audio transcription
check_start "Audio transcription"
AUDIO_OK=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
audio = data.get('tools',{}).get('media',{}).get('audio',{})
enabled = audio.get('enabled', False)
models = audio.get('models',[])
has_script = any('transcribe' in str(m.get('command','')) for m in models) if models else False
if enabled and has_script:
    print('ok')
else:
    print(f'enabled={enabled} script={has_script}')
" 2>/dev/null)
if [ "$AUDIO_OK" = "ok" ]; then
    check_ok "transcribe.sh configured"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
audio = data.setdefault('tools',{}).setdefault('media',{}).setdefault('audio',{})
audio['enabled'] = True
audio['models'] = [{'type':'cli','command':'${WORKSPACE_PATH:-$HOME/workspace}/scripts/transcribe.sh','args':[],'timeoutSeconds':300}]
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "Audio transcription restored" "Audio transcription → transcribe.sh"
fi

# 21. Context pruning
check_start "Context pruning"
PRUNING_OK=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
cp = data.get('agents',{}).get('defaults',{}).get('contextPruning',{})
mode = cp.get('mode','')
ttl = cp.get('ttl','')
if mode == 'cache-ttl' and ttl == '4h':
    print('ok')
else:
    print(f'{mode}/{ttl}')
" 2>/dev/null)
if [ "$PRUNING_OK" = "ok" ]; then
    check_ok "cache-ttl / 4h"
else
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
cp = data.setdefault('agents',{}).setdefault('defaults',{}).setdefault('contextPruning',{})
cp['mode'] = 'cache-ttl'
cp['ttl'] = '4h'
with open('$CONFIG_FILE','w') as f:
    json.dump(data,f,indent=2,ensure_ascii=False)
" 2>/dev/null
    check_fixed "Pruning restored (was: $PRUNING_OK)" "contextPruning → cache-ttl/4h"
fi

# 22. Docker
check_start "Docker"
if docker ps >/dev/null 2>&1; then
    SEARXNG=$(docker ps --format '{{.Names}}' | grep -c "searxng" || echo "0")
    N8N=$(docker ps --format '{{.Names}}' | grep -c "n8n" || echo "0")
    if [ "$SEARXNG" != "0" ] && [ "$N8N" != "0" ]; then
        check_ok "searxng, n8n running"
    else
        check_warn "searxng: $SEARXNG, n8n: $N8N"
    fi
else
    check_warn "Docker not running"
fi

# 23. Database freshness
check_start "Database freshness"
if [ -f "$DB_MAIN" ]; then
    DB_TIME=$(file_mtime "$DB_MAIN")
    NOW=$(date +%s)
    DIFF=$(( (NOW - DB_TIME) / 3600 ))
    if [ $DIFF -gt 2 ]; then
        check_warn "Last modified ${DIFF}h ago"
    else
        check_ok "Fresh (${DIFF}h ago)"
    fi
else
    check_fail "DB missing" "main.sqlite not found"
fi

# 24. Token
check_start "Token"
STATUS=$(openclaw status 2>&1)
if echo "$STATUS" | grep -iq "error"; then
    check_fail "Error" "Token error detected"
elif echo "$STATUS" | grep -q "token"; then
    check_ok "OK"
else
    check_warn "Unknown status"
fi

# ==================== DOCTOR AGENT (port 18790) ====================
# DISABLED: Doctor agent replaced by Hank (security agent). Skipping all Doctor checks.
if false; then
DOCTOR_CONFIG="$HOME/.openclaw-doctor/openclaw.json"
DOCTOR_LABEL="com.openclaw.doctor"
DOCTOR_PORT=18790
DOCTOR_PID=""

# D1. Doctor process
check_start "Doctor process"
if service_has "$DOCTOR_LABEL"; then
    DOCTOR_PID=$(service_get_pid "$DOCTOR_LABEL")
    if [ "$DOCTOR_PID" != "-" ] && [ -n "$DOCTOR_PID" ] && [ "$DOCTOR_PID" != "0" ]; then
        check_ok "PID $DOCTOR_PID"
    else
        restart_gateway_service "$DOCTOR_LABEL" >/dev/null 2>&1
        sleep 3
        DOCTOR_PID=$(service_get_pid "$DOCTOR_LABEL")
        if [ "$DOCTOR_PID" != "-" ] && [ -n "$DOCTOR_PID" ] && [ "$DOCTOR_PID" != "0" ]; then
            check_fixed "Restarted PID $DOCTOR_PID" "Doctor was not running"
        else
            check_fail "Won't start" "Doctor service failed"
        fi
    fi
else
    check_fail "Not installed" "Doctor service missing"
fi

# D2. Doctor Telegram enabled + allowFrom
check_start "Doctor TG auth"
if [ -f "$DOCTOR_CONFIG" ]; then
    DOC_TG=$(python3 -c "
import json
with open('$DOCTOR_CONFIG') as f:
    data = json.load(f)
tg = data.get('channels', {}).get('telegram', {})
problems = []
if not tg.get('enabled', True) == True:
    problems.append('enabled=False')
if tg.get('dmPolicy') != 'allowlist':
    problems.append('dmPolicy!=' + str(tg.get('dmPolicy')))
if '{{OWNER_TELEGRAM_ID}}' not in (tg.get('allowFrom') or []):
    problems.append('allowFrom missing')
# Check accounts too
for name, acc in tg.get('accounts', {}).items():
    if acc.get('dmPolicy') and acc['dmPolicy'] != 'allowlist':
        problems.append(f'acc.{name}.dmPolicy!={acc[\"dmPolicy\"]}')
if problems:
    print('FAIL:' + ';'.join(problems))
else:
    print('OK')
" 2>/dev/null)

    if echo "$DOC_TG" | grep -q "^OK"; then
        check_ok "enabled + allowlist"
    elif echo "$DOC_TG" | grep -q "^FAIL"; then
        python3 -c "
import json
with open('$DOCTOR_CONFIG') as f:
    data = json.load(f)
tg = data['channels']['telegram']
tg['enabled'] = True
tg['dmPolicy'] = 'allowlist'
tg['allowFrom'] = ['{{OWNER_TELEGRAM_ID}}']
for name, acc in tg.get('accounts', {}).items():
    acc['dmPolicy'] = 'allowlist'
    acc['allowFrom'] = ['{{OWNER_TELEGRAM_ID}}']
with open('$DOCTOR_CONFIG', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null
        # Restart doctor to pick up fix
        restart_gateway_service "$DOCTOR_LABEL" >/dev/null 2>&1
        check_fixed "Restored TG auth + restarted" "Doctor TG was broken: ${DOC_TG#FAIL:}"
    else
        check_fail "Can't check" "Python error"
    fi
else
    check_fail "Config missing" "$DOCTOR_CONFIG not found"
fi

# D3. Doctor code freshness
check_start "Doctor code freshness"
if [ -n "$DOCTOR_PID" ] && [ "$DOCTOR_PID" != "-" ]; then
    PROC_START=$(ps -p "$DOCTOR_PID" -o lstart= 2>/dev/null)
    PROC_EPOCH=$(date -j -f "%a %b %d %T %Y" "$PROC_START" "+%s" 2>/dev/null || echo "0")
    OPENCLAW_PKG="/opt/homebrew/lib/node_modules/openclaw/package.json"
    if [ -f "$OPENCLAW_PKG" ]; then
        CODE_EPOCH=$(file_mtime "$OPENCLAW_PKG")
        if [ "$CODE_EPOCH" -gt "$PROC_EPOCH" ]; then
            restart_gateway_service "$DOCTOR_LABEL" >/dev/null 2>&1
            sleep 3
            check_fixed "Restarted (stale code)" "Doctor was running old code after update"
        else
            check_ok "Code matches process"
        fi
    else
        check_ok "Skipped"
    fi
else
    check_ok "Skipped (no PID)"
fi
fi  # end of disabled Doctor block

# ==================== SUMMARY ====================
echo ""
echo "================================"
echo -e "Checked: ${BLUE}$CHECKED${NC} | Fixed: ${BLUE}$FIXED${NC} | Failed: ${RED}$FAILED${NC}"

if [ ${#FIXES[@]} -gt 0 ]; then
    echo -e "${BLUE}🔧 Fixed: $(IFS=', '; echo "${FIXES[*]}")${NC}"
fi

if [ $FAILED -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ FAILURES:${NC}"
    for failure in "${FAILURES[@]}"; do
        echo -e "   ${RED}•${NC} $failure"
    done
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All checks passed!${NC}"
exit 0
