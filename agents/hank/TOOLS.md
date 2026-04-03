# TOOLS.md — Инструменты Хэнка

## ⭐ КОНСТИТУЦИЯ КОМАНДЫ (ЧИТАТЬ ПЕРВОЙ!)
Файл: `references/team-constitution.md` — единственный источник правды.
Все правила, цепочки, протоколы — ТАМ. При противоречии с другими файлами — конституция главнее.

**Общие правила для всех агентов** → `references/team-constitution.md` секция 16 (антитишина, компактификация, Telegram MCP, team-board, контекст от Сола, PDF, доставка).

## Связь с командой

| Агент | Вызов |
|-------|-------|
| Хайзенберг (босс) | `sessions_send(sessionKey="agent:main:main", message="...", timeoutSeconds=120)` |
| Сол (координатор) | `sessions_send(sessionKey="agent:producer:main", message="...", timeoutSeconds=120)` |

**CRITICAL/ALERT:** пиши {{OWNER_NAME}} напрямую через message tool + board. SessionKeys — для координации с командой.


## Основные команды

| Задача | Команда |
|--------|---------|
| Security audit | `openclaw security audit --deep` |
| Порты | `lsof -iTCP -sTCP:LISTEN -P -n` |
| Docker | `docker ps --format "{{.Names}} {{.Ports}}"` |
| Permissions | `stat -f "%Lp %N" [файл]` |
| Config hash | `md5 -q ~/.openclaw/openclaw.json` |
| Git status | `cd {{WORKSPACE_PATH}} && git status --short` |
| SQLite WAL | `sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode;"` |
| Tailscale | `/Applications/Tailscale.app/Contents/MacOS/Tailscale status` |
| Bot check | `curl -s "https://api.telegram.org/bot[TOKEN]/getMe"` |
| LaunchAgents | `ls ~/Library/LaunchAgents/*.plist` |

## Отправка алертов

```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="🚨 [текст алерта]")
```

## Логирование

Записывай результаты аудитов в `memory/audit-log.md` (append).
Формат: `## YYYY-MM-DD HH:MM — [тип аудита]`


