# Шпаргалка для агента - Agent Doctor

> Быстрая справка как использовать скилл самодиагностики

---

## 🎯 Когда запускать

### Триггеры от пользователя:
- "продиагностируй себя"
- "самодиагностика"
- "проверь систему"
- "что с тобой не так"
- "health check"
- "self-check"

### Автоматически запускать когда:
- После обновления OpenClaw
- Пользователь жалуется на память ("не помнишь", "забыл")
- Странное поведение (ошибки, лаги)
- По запросу в начале дня/недели

---

## 📋 Алгоритм работы

### 1. Объяви начало
```
🏥 Запускаю полную диагностику...
```

### 2. Выполни проверки (7 блоков)

**🧠 Память:**
```bash
# 1. SQLite база
ls -lh ~/.openclaw/memory/*.sqlite

# 2. WAL mode (КРИТИЧНО!)
sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode;"
# Ожидаем: wal (НЕ delete!)

# 3. Количество чанков
sqlite3 ~/.openclaw/memory/main.sqlite "SELECT source, COUNT(*) FROM memory_chunks GROUP BY source;"

# 4. memorySearch включен?
jq '.memorySearch.enabled' ~/.openclaw/openclaw.json

# 5. Embedding провайдер
jq '.memorySearch.embeddingProvider' ~/.openclaw/openclaw.json

# 6. Тестовый поиск
memory_search("test query")

# 7. MEMORY.md
ls -lh memory/MEMORY.md
wc -l memory/MEMORY.md

# 8. Структура
ls -la memory/ | grep "^d"

# 9. Последний daily note
ls -t memory/202*.md 2>/dev/null | head -1
```

**⏰ Кроны:**
```bash
openclaw cron list --json
```
Проверить: enabled, lastRun, failureCount, lastError

**⚙️ Конфиг:**
```bash
jq empty ~/.openclaw/openclaw.json  # валидность
jq '.defaultModel' ~/.openclaw/openclaw.json
jq '.memorySearch' ~/.openclaw/openclaw.json
jq '.plugins[] | select(.name=="memory-core")' ~/.openclaw/openclaw.json
```

**📁 Файлы:**
```bash
ls -lh SOUL.md IDENTITY.md AGENTS.md HEARTBEAT.md USER.md
ls -d skills/*/ | wc -l
```

**🔧 Gateway:**
```bash
openclaw status
tail -100 ~/.openclaw/logs/gateway.log | grep -i "error" | tail -5
```

**💾 Система:**
```bash
uname -s -r -m
node --version  # >= v20
python3 --version  # >= 3.11
df -h ~ | tail -1
openclaw --version
```

**🛡️ Безопасность:**
```bash
jq '.gateway.bind' ~/.openclaw/openclaw.json  # НЕ 0.0.0.0!
jq '.gateway.authMode' ~/.openclaw/openclaw.json
grep -r "sk-" memory/ 2>/dev/null | wc -l  # должно быть 0
```

### 3. Сформируй отчет

**Формат:**
```
🏥 ДИАГНОСТИКА АГЕНТА - [дата время]

🧠 Память: [✅ OK / ⚠️ N проблем / ❌ Не работает]
⏰ Кроны: [статус]
⚙️ Конфиг: [статус]
📁 Файлы: [статус]
🔧 Gateway: [статус]
💾 Система: [статус]
🛡️ Безопасность: [статус]

━━━━━━━━━━━━━━━━━━━

[Если проблемы:]

📋 ДЕТАЛИ ПРОБЛЕМ:

1. [⚠️/❌] [Название]
   📝 Что не так: [описание]
   💡 Решение: [команда]
   ⚡ Риск: [низкий/средний/высокий]

━━━━━━━━━━━━━━━━━━━

Исправить проблемы? (да/нет)

[Если все OK:]

✅ Все системы работают нормально!
```

### 4. Предложи фиксы

**Если пользователь сказал "да":**
1. Спросить какие проблемы (номера или "все")
2. Для каждого фикса:
   - Объяснить что будет сделано
   - Предупредить о рисках
   - Дождаться "ок"
   - Выполнить
   - Проверить результат
   - Отчитаться

---

## 🔴 Критичные проблемы (чинить СРАЗУ!)

### P-001: WAL mode = delete
**Симптом:** Агент не видит новые записи

**Фикс:**
```bash
sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode=WAL;"
```
**После:** Перезапустить gateway

---

### P-014: memory-core отключен
**Симптом:** Память не работает после обновления

**Фикс:**
```bash
jq '.plugins = [.plugins[] | if .name == "memory-core" then .enabled = true else . end]' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```
**После:** Перезапустить gateway

---

### P-026: bind = 0.0.0.0
**Симптом:** ОПАСНО! Gateway доступен из интернета

**Фикс:**
```bash
jq '.gateway.bind = "127.0.0.1"' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```
**После:** Перезапустить gateway

---

## 🟡 Частые проблемы

### Нет embedding провайдера
```bash
openclaw auth add openai
# или
openclaw auth add gemini
```

### memorySearch отключен
```bash
jq '.memorySearch.enabled = true' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```

### Диск заполнен
```bash
rm -rf ~/.openclaw/logs/*.log.old
rm -rf ~/.openclaw/cache/*
```

---

## 🛡️ Правила безопасности

### НИКОГДА не делай:
- ❌ Не менять конфиг без подтверждения
- ❌ Не удалять файлы безвозвратно
- ❌ Не показывать API ключи пользователю
- ❌ Не применять фиксы без объяснения рисков

### ВСЕГДА делай:
- ✅ Объясняй что будет сделано
- ✅ Оценивай риск (низкий/средний/высокий)
- ✅ Жди явного "ок" перед фиксом
- ✅ Проверяй результат после фикса
- ✅ Предлагай перезапустить gateway если нужно

---

## 💬 Стиль общения

**НЕ говори:**
- ❌ "Отличный вопрос!"
- ❌ "Я буду рад помочь"
- ❌ "К сожалению обнаружены проблемы"

**Говори:**
- ✅ Коротко и по делу
- ✅ Конкретные команды, не абстракции
- ✅ Как человек, не как бот
- ✅ Можно использовать дефис (-) вместо тире (—)

---

## 📊 Примеры

### Пример 1: Все ОК
```
🏥 ДИАГНОСТИКА АГЕНТА - 2026-03-06 14:30

🧠 Память: ✅ OK
⏰ Кроны: ✅ OK
⚙️ Конфиг: ✅ OK
📁 Файлы: ✅ OK
🔧 Gateway: ✅ OK
💾 Система: ✅ OK
🛡️ Безопасность: ✅ OK

━━━━━━━━━━━━━━━━━━━

✅ Все системы работают нормально!
```

### Пример 2: Критичная проблема
```
🏥 ДИАГНОСТИКА АГЕНТА - 2026-03-06 14:30

🧠 Память: ❌ Не работает
...

━━━━━━━━━━━━━━━━━━━

📋 ДЕТАЛИ ПРОБЛЕМ:

1. ❌ WAL mode отключен
   📝 Что не так: SQLite использует journal_mode=delete вместо WAL
   💡 Решение: sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode=WAL;"
   ⚡ Риск: низкий

━━━━━━━━━━━━━━━━━━━

Исправить? (да/нет)
```

### Пример 3: Несколько проблем
```
Пользователь: исправь 1 и 3

Ты:
Применяю фиксы #1 и #3

Фикс #1: Включение WAL mode
Выполняю: sqlite3 ...
✅ Готово!

Фикс #3: Очистка диска
Выполняю: rm -rf ~/.openclaw/logs/*.log.old
✅ Освобождено 500MB

Все исправлено! Перезапусти gateway:
launchctl kickstart -k gui/$(id -u)/com.openclaw.gateway
```

---

## 🔍 Отладка скилла

Если что-то пошло не так:

1. Проверь что SKILL.md существует и читается
2. Проверь логи последних tool calls
3. Проверь доступ к SQLite базе
4. Проверь что openclaw CLI работает

**Ошибки в логи, НЕ пользователю!**

---

## 📚 Дополнительные ресурсы

- PROBLEMS_DATABASE.md - 28 проблем с решениями
- EXAMPLES.md - 10 сценариев использования
- Поиск по памяти - `memory_search("agent doctor")`

---

**Версия:** 1.0.0  
**Последнее обновление:** 2026-03-06
