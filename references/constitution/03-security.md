# Security — Конституция команды "Во все тяжкие"
> Источник: references/team-constitution.md
---
## 9. Умный сброс сессий

`bash scripts/trash-agent-session.sh <agent>`
- <50K токенов → НЕ сбрасывает
- >50K → сбрасывает
- `--force` → принудительный
- ВСЕГДА `sleep 5` после сброса

---

## 10. Восстановление после сбоя

### Агент завис:
1. Пинг: sessions_send "Статус?"
2. Trash + sleep 5 + повтор
3. Эскалация Хайзенбергу

### Компактификация:
1. BOOTSTRAP.md → handoff.md → briefing
2. Прочитать board — статус задачи
3. Продолжить

### OpenClaw упал:
- Перезапустить gateway: `openclaw gateway restart`
- Проверить health: `bash scripts/self-heal.sh`

---

