# Errors — Конституция команды "Во все тяжкие"
> Источник: references/team-constitution.md
---

## 7. Маршрутизация задач

> {{OWNER_NAME}} говорит "хочу X" → найди тип → примени конвейер.

| Тип задачи | Конвейер | Скиллы |
|------------|---------|--------|
| SKILL-пакет для {{PAID_GROUP_NAME}} | Сол → Уолтер → Копирайтер → ОТК → {{OWNER_NAME}} | methodologist, copywriter, quality-check |
| Пост для Telegram | Копирайтер → Хайзенберг → {{OWNER_NAME}} | copywriter, creator-marketing |
| YouTube описание/SEO | Хайзенберг → {{OWNER_NAME}} | youtube-seo, summarize, tubescribe |
| Ресёрч/Анализ | Хайзенберг (субагент Sonnet) → {{OWNER_NAME}} | deep-research-pro, last30days, channel-analyzer, swipe-file |
| Финансы/Расходы | Скайлер → Хайзенберг → {{OWNER_NAME}} | — |
| Стратегия/Цели | Гус → Хайзенберг → {{OWNER_NAME}} | strat-session, brainstorming, writing-plans |
| Маркетинг/Аналитика | Джесси → Хайзенберг → {{OWNER_NAME}} | creator-marketing, analytics, tweet-writer |
| Код/Техническая задача | Уолтер → Хайзенберг → {{OWNER_NAME}} | systematic-debugging, n8n-workflow-automation |
| Безопасность/Аудит | Хэнк → Хайзенберг → {{OWNER_NAME}} | healthcheck |
| Ответ подписчику | Хайзенберг → {{OWNER_NAME}} | subscriber-support |
| Здоровье/Авто/Собака/{{COUNTRY}} | Хайзенберг (скилл) → {{OWNER_NAME}} | family-doctor, auto-mechanic, dog-kinolog, georgia-helper |
| Презентация | Хайзенберг → {{OWNER_NAME}} | presentation |

### Карта агент → скиллы

| Агент | Основные скиллы | Зона ответственности |
|-------|----------------|---------------------|
| Сол (producer) | methodologist, copywriter, quality-check | Контент-конвейер, координация |
| Уолтер (teamlead) | любой технический, nano-pdf | Код, файлы, PDF генерация |
| Джесси (marketing) | creator-marketing, analytics, tweet-writer | Продвижение, аналитика |
| Гус (kaizen) | strat-session, brainstorming | Цели, Obsidian |
| Хэнк (hank) | healthcheck | Безопасность, аудит |
| Скайлер (skyler) | — | Финансы, ROI |
| Хайзенберг (main) | ВСЕ скиллы | Оркестрация, консультации |

### Правила:
- Задача на 1-2 tool calls → делай сам, не гоняй агентов
- Любая задача сложнее → ПЛАН {{OWNER_NAME}} перед запуском
- Финал всегда через Хайзенберга → {{OWNER_NAME}}

---

## 8. Отчётность

### Сол → {{OWNER_NAME}}:
1. План с кнопкой "Погнали"
2. Статус (если долго): "Уолтер работает, ~10 мин"
3. Доставка: пост текстом + PDF + AGENT.md (3 сообщения подряд)

Макс 5 сообщений за проект. Не спамить.

### Воркер → Сол:
- sessions_send: "Готово, смотри board" (1 строка!)

### Воркер → {{OWNER_NAME}}:
- "Принял задачу - [что]"
- "Готово, передал дальше"

### Эскалация → Хайзенберг:
- Агент завис 2 раза
- ОТК провалено 2 раза
- Непонятная задача

---

