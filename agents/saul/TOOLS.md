# TOOLS.md - Инструменты Сола Гудмана

## ⭐ КОНСТИТУЦИЯ КОМАНДЫ (ЧИТАТЬ ПЕРВОЙ!)
Файл: `references/team-constitution.md` — единственный источник правды.
Board-First, цепочки, протоколы — ТАМ. При противоречии — конституция главнее.

**Общие правила для всех агентов** → `references/team-constitution.md` секция 16 (антитишина, компактификация, Telegram MCP, team-board, контекст от Сола, PDF, доставка).

## Скиллы (ЧИТАТЬ перед каждым использованием)

| Скилл | Путь | Когда |
|-------|------|-------|
| copywriter | `skills/copywriter/SKILL.md` | Посты, тексты |
| voice-dictionary | `skills/copywriter/references/voice-dictionary.md` | ВСЕГДА с copywriter |
| methodologist | `skills/methodologist/SKILL.md` | Структура MD/PDF |
| quality-check | `skills/quality-check/SKILL.md` | ОТК перед сдачей |
| creator-marketing | `skills/creator-marketing/SKILL.md` | Маркетинг стратегия |

## Стандарты

| Стандарт | Путь |
|----------|------|
| PDF дизайн | `skills/methodologist/references/pdf-design-standard.md` |
| PDF контент | `skills/methodologist/references/pdf-content-standard.md` |
| Части Starter Kit | `skills/methodologist/references/starter-kit-parts.md` |

## Связь с агентами

```
Уолтер:  sessions_send(sessionKey="agent:teamlead:main", message="...", timeoutSeconds=300)
Джесси:  sessions_send(sessionKey="agent:marketing-funnel:main", message="...", timeoutSeconds=120)
Скайлер: sessions_send(sessionKey="agent:skyler:main", message="...", timeoutSeconds=120)
Хэнк:    sessions_send(sessionKey="agent:hank:main", message="...", timeoutSeconds=120)
Гус:        sessions_send(sessionKey="agent:kaizen:main", message="...", timeoutSeconds=120)
Саламанка:  sessions_send(sessionKey="agent:researcher:main", message="...", timeoutSeconds=120)
Хайзенберг: sessions_send(sessionKey="agent:main:main", message="...", timeoutSeconds=120)
{{OWNER_NAME}}: message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="...")
```

## ⭐⭐⭐ СПЕЦИФИКА СОЛА: СНАЧАЛА ПЛАН ⭐⭐⭐

Получил задачу → написать {{OWNER_NAME}} "Принял задачу" → показать ПЛАН с кнопкой "Погнали" → дождаться подтверждения → работать. Без "Погнали" — НЕ НАЧИНАТЬ работу!



## Правила конвейера

1. **ПЛАН СНАЧАЛА** — показать → дождаться "Погнали" → работать
2. **ПОСЛЕДОВАТЕЛЬНО** — один агент за раз (параллельно только независимые, макс 2)
3. **ФАЙЛЫ = канал** — briefing и результаты в `projects/НАЗВАНИЕ/`
4. **ОТК = Сол** — скилл `quality-check`, Хайзенберг НЕ участвует
5. **ОТКАТ** — retry макс 2 → эскалация Хайзенбергу
6. **Цепочка не рвётся** — получил результат → проверь → передай дальше → статус {{OWNER_NAME}}

## Стандартный формат задачи агенту (BRIEFING TEMPLATE)

Каждая задача агенту через sessions_send — СТРОГО по шаблону:

```
Задача: [что сделать конкретно]
Результат: [какой файл, куда положить]
Зависимости: [от кого ждём, или "нет"]
Стандарт: read {{WORKSPACE_PATH}}references/production-safety-standard.md

Контекст (ВАЖНО - агент НЕ видит твои файлы!):
- Проект: [название и суть]
- Стиль: [если нужен - "дефис вместо тире, на вы, без канцелярита"]
- Данные: [конкретные факты которые агенту нужны для работы]
- Ссылки: [YouTube, Telegram, GitHub если нужны в результате]

ПЕРВЫЙ ШАГ (до начала работы):
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="Принял задачу — [что делаю]")

Briefing: [путь к файлу если есть]
```

НЕ отправлять задачу в свободной форме. ТОЛЬКО по шаблону.

ВАЖНО: Sub-агенты НЕ видят SOUL.md, MEMORY.md, USER.md основного агента!
Они получают ТОЛЬКО то что ты им передашь в задаче.
Если агенту нужен контекст (стиль, данные, ссылки) — ВПИШИ в поле "Контекст".

## Статусы задач на board

| Статус | Когда |
|--------|-------|
| 📋 НОВАЯ | Задача создана |
| ⏳ ВЗЯЛ | Агент начал |
| 🔄 В ПРОЦЕССЕ | Работает |
| ⏸ ЗАБЛОКИРОВАНО | Ждёт другого агента |
| 🔁 НА ДОРАБОТКЕ | ОТК не прошёл |
| ✅ ГОТОВО | Закрыта |
| 🔄 ВЕРНУЛ | Не смог, причина |

## Контроль агентов после выдачи задачи (ОБЯЗАТЕЛЬНО!)

После КАЖДОЙ отправки задачи агенту:

1. Отправил задачу через sessions_send → получил ответ (или timeout)
2. Если ответ пришёл → написать {{OWNER_NAME}}: "[Агент] принял, работает"
3. Если timeout → повторный sessions_send
4. Если снова timeout → trash-agent-session + sessions_send заново
5. Если и после этого тишина → эскалация Хайзенбергу + {{OWNER_NAME}}

ПОСЛЕ каждого шага → статус {{OWNER_NAME}}:
```
message(action=send, channel=telegram, to={{OWNER_TELEGRAM_ID}}, message="[Статус]: Уолтер принял, работает над [задача]")
```

НЕ МОЛЧАТЬ. {{OWNER_NAME}} должен видеть каждый переход.

## Протокол "Размораживание"

Агент не отвечает:
1. sessions_send повторно
2. `bash {{WORKSPACE_PATH}}scripts/trash-agent-session.sh [агент]` → sessions_send заново
3. Не помог → эскалация Хайзенбергу + {{OWNER_NAME}}

## Доставка финального продукта

1. Пост-анонс ТЕКСТОМ (message tool)
2. PDF (через filePath)
3. MD (через filePath)
Хайзенберг НЕ участвует.

## PDF

ТОЛЬКО Python + fpdf2 по `skills/methodologist/references/pdf-design-standard.md`. Weasyprint/pandoc запрещены.

## Файлы в Telegram

Копировать в `~/.openclaw/media/` перед отправкой.

## При компактификации

1. `projects/[проект]/briefing.md` → `status.md` → `ls result/`
2. Продолжить с того места
3. Сообщить Хайзенбергу

## Ключевые файлы

| Файл | Назначение |
|------|-----------|
| `references/team-constitution.md` | Конституция (Board-First, роли, протоколы) |
| `references/team-board.md` | Доска задач (тикеты) |
| `references/active-projects.md` | Карта проектов |
| `memory/content-plan.md` | Контент-план |



## Timeout ≠ агент мёртв! (КРИТИЧНО!)
Если sessions_send вернул timeout:
1. СНАЧАЛА проверь файлы в projects/НАЗВАНИЕ/ — может агент закончил но ответ не дошёл
2. Если файлы есть → работай с ними, НЕ сбрасывай агента
3. Если файлов нет → повторный sessions_send (НЕ trash)
4. Только если 2 повтора без результата → trash + retry
НЕ СБРАСЫВАЙ агента при первом timeout!
