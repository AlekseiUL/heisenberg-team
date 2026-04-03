# TOOLS.md - Инструменты Джесси Пинкмана

## ⭐ КОНСТИТУЦИЯ КОМАНДЫ (ЧИТАТЬ ПЕРВОЙ!)
Файл: `references/team-constitution.md` — единственный источник правды.
Все правила, цепочки, протоколы — ТАМ. При противоречии с другими файлами — конституция главнее.

**Общие правила для всех агентов** → `references/team-constitution.md` секция 16 (антитишина, компактификация, Telegram MCP, team-board, контекст от Сола, PDF, доставка).

## Связь с командой

| Агент | Вызов |
|-------|-------|
| Сол (координатор) | `sessions_send(sessionKey="agent:producer:main", message="...", timeoutSeconds=120)` |
| Хайзенберг (босс) | `sessions_send(sessionKey="agent:main:main", message="...", timeoutSeconds=120)` |
| Саламанка (ресёрч) | `sessions_send(sessionKey="agent:researcher:main", message="...", timeoutSeconds=120)` |

**После выполнения задачи:** обнови board (ГОТОВО + путь к файлу) И отправь сигнал Солу:
```
sessions_send(sessionKey="agent:producer:main", message="Готово: [что сделал]. Файл: [путь]", timeoutSeconds=120)
```


## 📊 Аналитика (главное оружие)

| Инструмент | Команда |
|-----------|---------|
| Telegram статистика | `python3 skills/analytics/scripts/tg-stats.py --period=7d` |
| YouTube глубокая | `python3 skills/analytics/scripts/yt-deep-stats.py --days=30` |
| Анализ постов канала | `python3 skills/channel-analyzer/scripts/analyze-channel.py --channel "<id>" --days N` |

**Telegram IDs:**
- Канал @{{TELEGRAM_CHANNEL}}: нужен через Telethon
- Платный канал {{PAID_GROUP_NAME}}: `{{PAID_CHANNEL_ID}}`

## 🔍 Ресёрч

- `web_search` - тренды, конкуренты, боли аудитории
- `web_fetch` - парсинг страниц, лендингов конкурентов

### 🌐 Браузеры (два варианта)

**Lightpanda (лёгкий, быстрый) — основной для парсинга:**
```bash
scripts/lightpanda fetch --dump markdown <url>           # страница в markdown
scripts/lightpanda fetch --dump semantic_tree_text <url>  # accessibility tree
```
11x быстрее Chrome, 9x меньше RAM. Для получения текста/данных со страниц, парсинга конкурентов, чтения лендингов.

**browser tool (тяжёлый) — когда Lightpanda не справляется:**
Для тяжёлых SPA, JavaScript-рендеринга, скриншотов. Используй если Lightpanda вернул пустую страницу.

**Порядок:** сначала Lightpanda → если не справился → browser tool / web_fetch.
- `memory_search` - поиск по прошлым обсуждениям с {{OWNER_NAME}}

## ✍️ Контент

- Стиль текста: читай `skills/copywriter/references/voice-dictionary.md`
- Дефис (-) вместо тире (—). ВСЕГДА
- Без канцелярита
- 1-2 эмодзи максимум

## 📁 Мои данные

| Что | Путь | Когда |
|-----|------|-------|
| Конкуренты (база) | `data/competitors.md` | ПЕРЕД любым анализом |
| Конкуренты (анализ марта) | `data/competitors-analysis.md` | Для сравнений |
| Маркетинг-проект | `{{WORKSPACE_PATH}}projects/{{PROJECT_MARKETING}}/` | Основной проект. PROJECT.md = план |
| Аналитика | `{{WORKSPACE_PATH}}projects/{{PROJECT_MARKETING}}/аналитика/` | Отчёты, конкуренты |
| Результаты | `{{WORKSPACE_PATH}}projects/{{PROJECT_MARKETING}}/результаты/` | Воронка, лендинг, ERR |
| FAQ из чата | `{{WORKSPACE_PATH}}projects/{{PROJECT_MARKETING}}/faq-from-chat.md` | FAQ из чата подписчиков |
| Скиллы | `skills/` | Перед выполнением задачи |

## 🎙 Голосовые
- TTS: Edge, {{TTS_VOICE_NAME}}, 1.5x
- tts(text) → message(filePath, asVoice=true)

## ⚠️ Длинные ответы {{OWNER_NAME}}

ВСЕГДА отправлять через `message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}})`.
НЕ отвечать длинным текстом напрямую в чат — сообщение может удалиться/перезатереться.
Если ответ длинный — разбивать на 2-3 сообщения через message tool.

## Production Safety Standard (ОБЯЗАТЕЛЬНО при создании файлов!)
Перед сдачей ЛЮБОГО файла (MD, PDF, HTML) — прочитай и проверь по чеклисту:
```
read {{WORKSPACE_PATH}}references/production-safety-standard.md
```
- Бэкап предложен
- 0 личных данных
- Кросс-платформа
- На "вы"
- Дефис вместо тире
- PDF визуально проверен (таблицы, наложения)
- Откат описан
