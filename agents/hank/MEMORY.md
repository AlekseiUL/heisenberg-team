# MEMORY.md — Память Хэнка Шрейдера 🔫

## Инфраструктура под защитой

### Telegram боты (6 шт)
- main (@{{TELEGRAM_CHANNEL}}_bot) — Хайзенберг
- kaizen — Гус Фринг
- teamlead ({{BOT_TEAMLEAD}}) — Уолтер Уайт
- marketing-funnel — Джесси Пинкман
- producer ({{BOT_SAUL}}) — Сол Гудман

### Auth-профили (5 шт)
- anthropic:default (Claude Max ${{SUBSCRIPTION_COST}}/мес)
- anthropic:manual
- openai:default
- deepseek:default
- google-gemini-cli:{{GEMINI_EMAIL}}

### Docker (4 контейнера)
- searxng (127.0.0.1:8888)
- n8n-local (127.0.0.1:5678)
- n8n-postgres-backup
- n8n-postgres-local

### LaunchAgents

> Compare against your known baseline of LaunchAgents. Document your count on first audit.
- ai.openclaw.gateway
- ai.openclaw.system-health
- com.{{OWNER_USERNAME}}.backup
- com.{{OWNER_USERNAME}}.daemon
- com.{{OWNER_USERNAME}}.monitor
- com.{{OWNER_USERNAME}}.memory-decay
- com.google.GoogleUpdater.wake
- com.google.keystone.agent
- com.google.keystone.xpcservice
- com.{{OWNER_USERNAME}}.gateway
- com.{{OWNER_USERNAME}}.gateway-alt
- com.openclaw.watchdog
- com.whisper.server
- com.{{OWNER_USERNAME}}.gateway-backup
- com.telegram-mcp.server (MCP для чтения Telegram, localhost:3000, добавлен 2026-03-16)
- com.openclaw.file-hook-watcher (file-hook-watcher.sh, добавлен {{DATE_ADDED}}, HOOKS-TEST)

### Чувствительные файлы
- `~/.openclaw/openclaw.json` — chmod 600 ✅
- `~/.openclaw/.env` — chmod 600 ✅

### Известные файлы с паттернами токенов (разрешённые)
См. AGENTS.md → секция "Разрешённые файлы"

## Известные исключения (KNOWN_EXCEPTION)

### main (Хайзенберг) — gateway не в deny
- **Статус:** KNOWN_EXCEPTION ✅
- **Подтверждено:** {{OWNER_NAME}} 2026-03-15 + повторно 2026-03-26
- **Причина:** main — оркестратор команды, единственный кто может делать `config.patch` и `update.run` через gateway
- **Действие:** не алертить, не поднимать вопрос

## Аудиты
(будет заполняться автоматически)

*Создано: 2026-03-10*
