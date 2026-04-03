# 🏥 OpenClaw Agent Doctor

> Self-diagnostic toolkit for OpenClaw AI agents. Find and fix problems before they find you.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-compatible-green.svg)](https://github.com/openclaw/openclaw)

---

## ⚡ Quick Start

```bash
# 1. Clone into your OpenClaw workspace
cd ~/path/to/your/workspace/skills
git clone https://github.com/YOUR-USERNAME/agent-doctor.git

# 2. Restart gateway (optional)
openclaw gateway restart

# 3. Tell your agent:
"продиагностируй себя"  # Russian: "diagnose yourself"
# or
"self-check"
```

That's it! Your agent will run comprehensive diagnostics and report findings.

---

## 🔍 What It Checks

### 🧠 Memory
- **SQLite database** - existence, size, WAL mode (critical!)
- **memorySearch config** - enabled, embedding provider, API keys
- **Memory files** - MEMORY.md, daily notes, folder structure
- **Test query** - verify search actually works

**Why it matters:** Wrong settings (especially WAL mode) can make your agent "forget" recent conversations.

### ⏰ Cron Jobs
- **Status** - which crons are enabled/disabled
- **Last runs** - when each cron executed last
- **Failures** - errors, failureCount, why they failed

**Why it matters:** Silent cron failures = broken automation.

### ⚙️ Configuration
- **JSON validity** - parse openclaw.json without errors
- **Models** - defaultModel configured, provider available
- **Plugins** - memory-core enabled (often breaks after updates!)
- **Auth** - API keys for OpenAI/Gemini/Anthropic

**Why it matters:** Broken config = agent won't start.

### 📁 Agent Files
- **Core files** - SOUL.md, IDENTITY.md, USER.md, etc.
- **Skills** - count, readability, no permission issues

**Why it matters:** Missing files = agent without context or personality.

### 🔧 Gateway
- **Status** - running or stopped
- **Uptime** - how long without restart
- **Logs** - last 5 errors from gateway.log
- **Port** - is it available or blocked

**Why it matters:** Dead gateway = no agent.

### 💾 System
- **Node.js** - version >= 20.0.0 required
- **Python** - version >= 3.11 recommended
- **Disk space** - minimum 1GB free
- **OpenClaw version** - is it up-to-date?

**Why it matters:** Old versions = bugs, missing features, incompatibilities.

### 🛡️ Security
- **Gateway bind** - localhost only? (0.0.0.0 = DANGER!)
- **Auth mode** - token protection enabled?
- **API keys** - not leaked in memory files?

**Why it matters:** Public gateway = anyone can access your agent and data.

---

## 📦 Installation

### Option 1: Git Clone (recommended)

```bash
cd ~/path/to/your/workspace/skills
git clone https://github.com/YOUR-USERNAME/agent-doctor.git
```

### Option 2: Manual Download

```bash
mkdir -p ~/path/to/your/workspace/skills/agent-doctor
cd ~/path/to/your/workspace/skills/agent-doctor

# Download SKILL-public.md (public version without personal data)
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/agent-doctor/main/SKILL-public.md
mv SKILL-public.md SKILL.md
```

### Option 3: One-liner

```bash
mkdir -p ~/path/to/your/workspace/skills/agent-doctor && \
cd ~/path/to/your/workspace/skills/agent-doctor && \
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/agent-doctor/main/SKILL-public.md && \
mv SKILL-public.md SKILL.md && \
echo "✅ Installed!"
```

**Verify:**
```bash
ls ~/path/to/your/workspace/skills/agent-doctor/SKILL.md
openclaw gateway restart  # optional
```

---

## 💡 Usage Examples

### Basic Diagnostic

**Russian:**
```
Вы: продиагностируй себя

Агент: 🏥 ДИАГНОСТИКА АГЕНТА - 2026-03-06 14:30

🧠 Память: ✅ OK
⏰ Кроны: ⚠️ 1 отключен
⚙️ Конфиг: ✅ OK
📁 Файлы: ✅ OK
🔧 Gateway: ✅ OK
💾 Система: ✅ OK
🛡️ Безопасность: ✅ OK

━━━━━━━━━━━━━━━━━━━

📋 ДЕТАЛИ ПРОБЛЕМ:

1. ⚠️ Крон watchdog-v2 отключен
   📝 Что не так: enabled = false
   💡 Решение: openclaw cron enable watchdog-v2
   ⚡ Риск: низкий

━━━━━━━━━━━━━━━━━━━

Исправить? (да/нет)
```

**English:**
```
You: self-check

Agent: 🏥 AGENT DIAGNOSTIC - 2026-03-06 14:30

🧠 Memory: ✅ OK
⏰ Crons: ⚠️ 1 disabled
⚙️ Config: ✅ OK
📁 Files: ✅ OK
🔧 Gateway: ✅ OK
💾 System: ✅ OK
🛡️ Security: ✅ OK

━━━━━━━━━━━━━━━━━━━

📋 ISSUES:

1. ⚠️ Cron watchdog-v2 disabled
   📝 Problem: enabled = false
   💡 Solution: openclaw cron enable watchdog-v2
   ⚡ Risk: low

━━━━━━━━━━━━━━━━━━━

Fix issues? (yes/no)
```

### Automated Daily Check

Set up a cron to check health every morning:

```bash
openclaw cron add daily-health-check \
  --schedule "0 8 * * *" \
  --model "anthropic/claude-sonnet-4-6" \
  --isolated \
  --payload '{
    "kind": "agentTurn",
    "message": "Run agent-doctor diagnostic. If you find critical issues (WAL mode, memory-core disabled, bind=0.0.0.0), send alert. If everything OK, stay silent."
  }'
```

### Bash Script (No Agent Required)

For CI/CD or quick terminal checks:

```bash
bash skills/agent-doctor/auto-diagnostic.sh
```

Output:
```
🏥 AGENT DOCTOR - Auto-diagnostic
================================

🧠 MEMORY
--------
Check: SQLite database exists... ✅ OK
Check: WAL mode enabled... ✅ OK
Check: Records in database... ✅ OK
...

💾 SYSTEM
---------
Check: Node.js version >= 20... ✅ OK
...

================================
✅ All checks passed!
```

Exit codes:
- `0` = all good
- `1` = issues found

---

## 📊 Sample Report

Example output after update broke memory-core:

```
🏥 ДИАГНОСТИКА АГЕНТА - 2026-03-06 14:30

🧠 Память: ❌ 2 проблемы
⏰ Кроны: ✅ OK
⚙️ Конфиг: ⚠️ Неполный
📁 Файлы: ✅ OK
🔧 Gateway: ✅ OK
💾 Система: ✅ OK
🛡️ Безопасность: ✅ OK

━━━━━━━━━━━━━━━━━━━

📋 ДЕТАЛИ ПРОБЛЕМ:

1. ❌ WAL mode отключен
   📝 Что не так: SQLite использует journal_mode=delete
   💡 Решение: sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode=WAL;"
   ⚡ Риск: низкий
   
   Симптомы:
   - Агент не видит новые записи
   - memory_search находит только старое
   - "Забывает" недавние разговоры

2. ❌ memory-core плагин отключен
   📝 Что не так: Плагин отключился после обновления OpenClaw
   💡 Решение: jq '.plugins = [.plugins[] | if .name == "memory-core" then .enabled = true else . end]' ...
   ⚡ Риск: средний (изменяет конфиг)
   
   Симптомы:
   - Память не работает вообще
   - memorySearch всегда пустой

━━━━━━━━━━━━━━━━━━━

Исправить проблемы? (да/нет)
```

---

## 🛡️ Safety

**Agent Doctor is read-only by design:**

- ✅ Only **reads** configuration and system state
- ✅ Never applies fixes without your **explicit confirmation**
- ✅ Shows **risk level** for each fix (low/medium/high)
- ✅ Explains **what will change** and **why**
- ✅ No `rm -rf`, no destructive operations, no blind automation

**You're always in control.**

---

## 🤝 Contributing

Found a bug? Have an idea? PRs welcome!

**What we'd love:**
- New diagnostic checks
- Solutions for common problems
- Better documentation
- Usage examples
- Translations

**Development:**

```bash
git clone https://github.com/YOUR-USERNAME/agent-doctor.git
cd agent-doctor

# Edit SKILL-public.md (public version)
# Edit PROBLEMS_DATABASE.md (add new issues)
# Edit EXAMPLES.md (add scenarios)

# Test
openclaw gateway restart
# Tell agent: "продиагностируй себя"
```

**Commit guidelines:**
- Use conventional commits: `feat:`, `fix:`, `docs:`
- Keep changes focused (one check per PR)
- Update CHANGELOG.md

---

## 📄 License

MIT License - use freely, modify, distribute.

See [LICENSE](LICENSE) for full text.

---

## 🔗 Links

- [OpenClaw](https://github.com/openclaw/openclaw) - Main project
- [Documentation](https://docs.openclaw.io) - Official docs
- [Community](https://reddit.com/r/OpenClaw) - Reddit community

---

**Version:** 1.0.0  
**Date:** 2026-03-06

🏥 **Healthy agent = productive agent!**
