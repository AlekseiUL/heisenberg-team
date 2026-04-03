---
name: excalidraw
description: "Создание схем и диаграмм в Excalidraw для Obsidian. Use when user says 'сделай схему', 'нарисуй диаграмму', 'excalidraw', 'схема в obsidian', 'визуализация'."
---

# Excalidraw Skill — Создание схем для Obsidian

**Триггеры:** "сделай схему", "нарисуй диаграмму", "excalidraw", "схема в obsidian", "визуализация"

---

## Важно! Формат Excalidraw в Obsidian

Obsidian Excalidraw плагин использует **сжатый формат** `compressed-json` (LZ-string).
Обычный JSON в code block **НЕ РАБОТАЕТ** — схема откроется как текст!

---

## Как создавать схему

### Шаг 1: Использовать генератор

Запустить скрипт `scripts/gen_excalidraw_v2.js` как шаблон или создать новый:

```bash
node scripts/gen_excalidraw_v2.js > "obsidian/Название.excalidraw.md"
```

### Шаг 2: Структура файла

```markdown
---
excalidraw-plugin: parsed
tags: [excalidraw, тема]
---

# Excalidraw Data

## Text Elements
Текст блока 1 ^id1

Текст блока 2 ^id2

%%
## Drawing
\`\`\`compressed-json
[сжатый JSON через lz-string]
\`\`\`
%%
```

### Шаг 3: Привязка текста к блокам (КРИТИЧНО!)

**Текст ОБЯЗАТЕЛЬНО должен быть привязан к контейнеру!**

На прямоугольнике:
```json
{
  "type": "rectangle",
  "id": "box1",
  "boundElements": [{ "type": "text", "id": "box1-text" }]
}
```

На тексте:
```json
{
  "type": "text",
  "id": "box1-text",
  "containerId": "box1"
}
```

**Без этой связи текст НЕ отображается внутри блоков!**

---

## Скрипт-генератор

Путь: `scripts/gen_excalidraw_v2.js`

Использует:
- `lz-string` для сжатия (npm install lz-string)
- Helper функции для создания блоков с привязанным текстом

### Основные функции:

```javascript
// Блок с текстом внутри
createBox(id, x, y, width, height, strokeColor, bgColor, text, fontSize)

// Отдельный текст (заголовки)
createText(id, x, y, text, fontSize, color)

// Стрелка
createArrow(id, x, y, dx, dy, color)
```

---

## Стиль схем для {{OWNER_NAME}}

### Цвета фона
- Чёрный фон: `#000000`
- Тёмно-серый блок: `#111827`
- Очень тёмный: `#0f0f23`

### Цвета акцентов
- Зелёный (успех, поток): `#22c55e` / bg `#14532d`
- Оранжевый (warning, Gateway): `#f97316` / bg `#7c2d12`
- Фиолетовый (API, premium): `#a855f7` / bg `#581c87`
- Синий (user, channels): `#3b82f6` / bg `#1e3a8a`
- Индиго (агент): `#4338ca` / bg `#312e81`
- Серый (контейнеры): `#374151` / bg `#111827`

### Шрифты
- Заголовок: 24-28px
- Секции: 20px
- Блоки: 13-14px
- Подписи стрелок: 12px

### Язык
- Всё на русском
- Понятные описания
- Эмодзи для визуальных якорей (🦀 👤 ⚡ 🤖 📁 🔑)

---

## Чеклист перед созданием

1. ✅ Установлен lz-string: `npm install lz-string`
2. ✅ Используется gen_excalidraw_v2.js или аналог
3. ✅ Текст привязан через containerId + boundElements
4. ✅ Файл имеет расширение `.excalidraw.md`
5. ✅ Frontmatter: `excalidraw-plugin: parsed`
6. ✅ Секция `## Text Elements` с `^id` для каждого текста
7. ✅ Секция `## Drawing` с `compressed-json`

---

## Открытие в Obsidian

```bash
open "obsidian://open?vault=obsidian&file=Название.excalidraw"
```

Если открывается как текст:
- Правый клик → "Open as Excalidraw drawing"
- Или кнопка переключения режима в углу

---

## Примеры рабочих схем

- `obsidian/{{AGENT_NICKNAME}} - Полная архитектура.excalidraw.md` — архитектура системы
- `obsidian/Агенты OpenClaw.excalidraw.md` — агентская система

---

*Создано: 2026-02-03*
