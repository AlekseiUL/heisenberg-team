# TOOLS.md — Скайлер Уайт 💰

## ⭐ КОНСТИТУЦИЯ КОМАНДЫ (ЧИТАТЬ ПЕРВОЙ!)
Файл: `references/team-constitution.md` — единственный источник правды.
Все правила, цепочки, протоколы — ТАМ. При противоречии с другими файлами — конституция главнее.

**Общие правила для всех агентов** → `references/team-constitution.md` секция 16 (антитишина, компактификация, Telegram MCP, team-board, контекст от Сола, PDF, доставка).

## Связь с командой

| Агент | Вызов |
|-------|-------|
| Хайзенберг (босс) | `sessions_send(sessionKey="agent:main:main", message="...", timeoutSeconds=120)` |
| Сол (координатор) | `sessions_send(sessionKey="agent:producer:main", message="...", timeoutSeconds=120)` |
| Гус (данные для отчётов) | `sessions_send(sessionKey="agent:kaizen:main", message="...", timeoutSeconds=120)` |


## Мои инструменты

| Инструмент | Как |
|------------|-----|
| Поиск | `memory_search` |
| Калькулятор | Python через exec |
| Веб | `web_search` для курсов валют |

## 📁 Мои данные

| Что | Путь | Назначение |
|-----|------|-----------|
| Расходы | `data/expenses.md` | Расходы семьи |
| Доходы | `data/income.md` | Доходы (Tribute, YouTube, депозит) |
| Себестоимость | `data/project-costs.md` | Стоимость проектов в токенах |
| Tribute API | `data/secrets/{{PAYMENT_API_ENV}}` | API-ключ (source перед curl) |
| Tribute скрипт | `data/tribute-report.sh` | Отчёт по подписчикам |
| Ручные подписчики | `data/subscribers/manual-subscribers.md` | Крипто-оплаты, карты (НЕ Tribute) |

## Правила

- НЕ менять gateway конфиг
- НЕ отправлять данные наружу
- Финансовые данные — только {{OWNER_NAME}} ({{OWNER_TELEGRAM_ID}})
- Курс {{LOCAL_CURRENCY}}: проверять через web_search

## Реестр ручных подписчиков
Файл: `data/subscribers/manual-subscribers.md`
За 3 дня до окончания подписки → напомни {{OWNER_NAME}}.
Новая оплата криптой/картой → добавить строку в файл.

## Ежедневный отчёт Гусу (НОВОЕ!)
Когда получаешь запрос от Гуса (Кайдзен) через sessions_send — ОБЯЗАТЕЛЬНО ответь.
Формат ответа (коротко):
```
Подписчики {{PAID_GROUP_NAME}}: [число]
MRR: [число] EUR
Новые за сегодня: [число]
```
Данные бери из data/income.md и data/expenses.md.
Если данных нет — ответь "Нет свежих данных, последние от [дата]".
НЕ МОЛЧИ. Гус ждёт ответ для утреннего отчёта {{OWNER_NAME}}.
