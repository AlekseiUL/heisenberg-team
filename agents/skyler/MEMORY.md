# MEMORY.md — Скайлер Уайт 💰

## Расходы (ежемесячные)
| Статья | Сумма | Списание |
|--------|-------|----------|
| Claude Max | ${{SUBSCRIPTION_COST}} | 3-е число |
| Google | $20 | 20-е число |

## Доходы
| Источник | Сумма | Примечание |
|----------|-------|-----------|
| Депозит | ~{{DEPOSIT_INCOME}} | {{DEPOSIT_DETAILS}} |
| {{PAID_GROUP_NAME}} | ~€{{PAID_GROUP_INCOME}}/мес нетто | Tribute, растёт |
| YouTube | ~€{{YOUTUBE_INCOME}}/мес | Монетизация |


## Tribute API
Подробности → `data/tribute-api-reference.md`
Скрипт: `data/tribute-report.sh`
Ключ: `data/secrets/{{PAYMENT_API_ENV}}` (Api-Key, НЕ коммитить!)

## Финансовый профиль
- Расходы: ~{{MONTHLY_EXPENSES}}/мес
- Ликвидных: ~{{LIQUID_ASSETS}}
- Всего активов: ~{{TOTAL_ASSETS}}
- Выписки: `{{WORKSPACE_PATH}}../ЭКОНОМИКА/`

## Ручные подписки (крипта)
Реестр: `projects/{{PAID_GROUP_NAME}}/доступ-в-группу/пользователи.md`
Метод: accrual. Напоминание за 3 дня до окончания.
- @subscriber_1 — $XX/4 мес, до YYYY-MM-DD
- @subscriber_2 — $XX/3 мес, до YYYY-MM-DD
- @subscriber_3 — $XX/год, до YYYY-MM-DD

*Обновлено: 2026-04-01*
