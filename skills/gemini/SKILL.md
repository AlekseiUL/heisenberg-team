---
name: gemini
description: "Gemini CLI for one-shot Q&A, summaries, and generation. Use when user mentions 'gemini', 'ask gemini', 'gemini cli', or needs a quick answer from Google's model."
---

# Gemini CLI Skill

Google Gemini CLI для быстрых вопросов, саммари и генерации контента.

## Установка

```bash
npm install -g @google/generative-ai-cli
```

Версия: `0.26.0`

---

## Основные команды

### One-shot запрос

```bash
gemini -p "Ваш вопрос"
```

Пример:
```bash
gemini -p "Суммаризируй этот текст: $(cat file.txt)"
```

### Интерактивный режим

```bash
gemini
```

Или с начальным промптом:
```bash
gemini -i "Помоги мне написать..."
```

### Выбор модели

```bash
gemini -m gemini-2.0-flash-exp -p "Вопрос"
```

Доступные модели:
- `gemini-2.0-flash-exp` (по умолчанию, быстрая)
- `gemini-1.5-pro` (более мощная)
- `gemini-1.5-flash` (баланс)

### YOLO mode (автоподтверждение)

```bash
gemini -y -p "Создай файл test.txt"
```

⚠️ **Осторожно!** Автоматически выполняет все действия без подтверждения.

---

## Работа с файлами

### Чтение stdin

```bash
cat file.txt | gemini -p "Суммаризируй"
```

### Анализ кода

```bash
gemini -p "Объясни этот код:" < script.py
```

---

## MCP серверы

Gemini CLI поддерживает MCP (Model Context Protocol) для расширений.

```bash
gemini mcp list
gemini mcp install <server-name>
```

---

## Skills & Extensions

### Список доступных

```bash
gemini skills list
gemini extensions list
```

### Использование конкретных extensions

```bash
gemini -e extension1,extension2 -p "Запрос"
```

---

## Сессии (Resume)

### Список сессий

```bash
gemini --list-sessions
```

### Возобновить последнюю

```bash
gemini -r latest
```

### Возобновить конкретную (по индексу)

```bash
gemini -r 5
```

### Удалить сессию

```bash
gemini --delete-session 5
```

---

## Примеры использования

### 1. Быстрый ответ

```bash
gemini -p "Что такое Kaizen?"
```

### 2. Суммаризация файла

```bash
gemini -p "Кратко перескажи:" < ~/Desktop/document.txt
```

### 3. Генерация кода

```bash
gemini -p "Напиши bash скрипт для резервного копирования папки"
```

### 4. Анализ логов

```bash
tail -100 /var/log/system.log | gemini -p "Найди ошибки в этих логах"
```

### 5. Интерактивная работа

```bash
gemini -i "Я работаю над проектом автоматизации. Помоги мне..."
```

---

## Для Кайдзена 🎯

Кайдзен может использовать Gemini CLI для:

1. **Анализ прогресса по целям**
   ```bash
   cat ~/.openclaw/workspace-kaizen/ЦЕЛИ.md | gemini -p "Оцени прогресс и предложи следующие шаги"
   ```

2. **Генерация мотивационных сообщений**
   ```bash
   gemini -p "Напиши мотивирующее сообщение для человека, который хочет улучшаться на 1% каждый день"
   ```

3. **Суммаризация дня**
   ```bash
   cat {{WORKSPACE_PATH}}obsidian/Дневник/$(date +%Y-%m-%d).md | gemini -p "Подведи итоги дня и выдели ключевые достижения"
   ```

4. **Разбивка большой цели**
   ```bash
   gemini -p "Разбей цель '$GOAL_NAME' на маленькие недельные шаги"
   ```

---

## API Key

Gemini CLI требует API ключ Google AI Studio.

**Получить ключ:** https://aistudio.google.com/app/apikey

**Настройка:**
```bash
export GOOGLE_AI_API_KEY="your-api-key"
```

Или добавить в `~/.zshrc`:
```bash
echo 'export GOOGLE_AI_API_KEY="your-key"' >> ~/.zshrc
```

---

## Лимиты (бесплатный tier)

- **1,500 запросов/день** для `gemini-2.0-flash-exp`
- **50 запросов/день** для `gemini-1.5-pro`

Для Кайдзена этого более чем достаточно!

---

## Troubleshooting

### Проверка установки

```bash
gemini --version
```

### Тест API ключа

```bash
gemini -p "Hello!"
```

Если работает → всё ок!

---

*Создано: 2026-02-03*
*Обновлено: 2026-02-03*
