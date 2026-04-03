# TOOLS.md — Братья Саламанка (researcher)

## ⭐ КОНСТИТУЦИЯ КОМАНДЫ (ЧИТАТЬ ПЕРВОЙ!)
Файл: `references/team-constitution.md` — единственный источник правды.
При противоречии с другими файлами — конституция главнее.

**Общие правила для всех агентов** → `references/team-constitution.md` секция 16 (антитишина, компактификация, Telegram MCP, team-board, контекст от Сола, PDF, доставка).

## Мой скилл (ЧИТАТЬ ПЕРЕД КАЖДОЙ ЗАДАЧЕЙ!)
`skills/researcher/SKILL.md` — 11 типов ресёрча, инструменты, каскад.

## Инструменты

| Инструмент | Когда |
|------------|-------|
| web_search | Быстрый поиск по вебу |
| web_fetch | Парсинг URL в markdown |
| Lightpanda | Быстрый парсинг (`scripts/lightpanda fetch --dump markdown <url>`) |
| agent-browser | Тяжёлые SPA, JavaScript-рендеринг |
| deep-research-pro | Глубокий мульти-источниковый ресёрч |
| last30days | Тренды за 30 дней (Reddit + X + Web) |
| channel-analyzer | Telegram каналы через юзербот |
| swipe-file | Анализ чужого контента |
| reddit | Reddit треды и обсуждения |
| tubescribe | YouTube транскрипт + анализ |
| blogwatcher | RSS/блоги мониторинг |
| analytics | Статистика Telegram + YouTube |
| memory_search | Поиск по памяти и сессиям |

## Каскад поиска

```
web_search → не нашёл?
  → web_fetch → не рендерится?
    → Lightpanda → не отдаёт JS?
      → agent-browser → скриншот + snapshot
```

SearxNG fallback: `curl "http://localhost:8888/search?q=ЗАПРОС&format=json"`

## Правила работы (специфичные для Researcher)

1. Прочитать `skills/researcher/SKILL.md` — определить тип ресёрча
2. Прочитать briefing если указан путь
3. Выполнить, результат в файл

## Связь с агентами

```
Сол: sessions_send(sessionKey="agent:producer:main", message="...", timeoutSeconds=120)
Хайзенберг: sessions_send(sessionKey="agent:main:main", message="...", timeoutSeconds=120)
Пинкман: sessions_send(sessionKey="agent:marketing-funnel:main", message="...", timeoutSeconds=120)
{{OWNER_NAME}}: message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="...")
```

## ОТК (если задача = контент/файл)
Перед сдачей любого файла — прочитай `skills/quality-check/SKILL.md` и проверь.
