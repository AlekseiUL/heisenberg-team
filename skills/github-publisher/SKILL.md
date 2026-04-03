---
name: github-publisher
description: "Публикация проектов на GitHub в едином стиле. README (EN+RU), чеклист, валидация файлов. Используй ВСЕГДА при создании/обновлении GitHub-репозиториев. Triggers: 'github', 'опубликуй', 'создай репо', 'readme', 'выложи на гитхаб'."
---

# GitHub Publisher — Публикация в едином стиле

## Когда использовать
- Создание нового GitHub-репозитория
- Обновление README существующего репо
- Публикация нового проекта/скилла на GitHub

## Стандарт README (обязательный)

Формат: **English first → Russian second → Social links**

```markdown
# Project Name — Short Description

One-liner in English.

## What You Get / Features
- **Feature 1** — description
- **Feature 2** — description

## Requirements
- OpenClaw (2026+)
- Node.js 20+ / Python 3.10+

## Installation
\`\`\`bash
git clone https://github.com/{{OWNER_USERNAME}}/REPO.git
cd REPO
bash install.sh
\`\`\`

## What's Inside / Structure
\`\`\`
project/
  file1.md
  file2.sh
\`\`\`

## How It Works
Step-by-step explanation.

---

# Название — Краткое описание

Однострочник на русском.

## Что получаете
- **Фича 1** — описание
- **Фича 2** — описание

## Требования
- OpenClaw (2026+)
- Node.js 20+ / Python 3.10+

## Установка
\`\`\`bash
git clone https://github.com/{{OWNER_USERNAME}}/REPO.git
cd REPO
bash install.sh
\`\`\`

## Что внутри
\`\`\`
project/
  file1.md
  file2.sh
\`\`\`

## Как работает
Пошаговое объяснение.

---

## Resources | Ресурсы

- 📺 YouTube: [youtube.com/@{{OWNER_USERNAME}}](https://youtube.com/@{{OWNER_USERNAME}})
- 📱 Telegram: [t.me/{{TELEGRAM_CHANNEL}}](https://t.me/{{TELEGRAM_CHANNEL}})
- 🔥 {{PAID_GROUP_NAME}} (Premium): [Подписка](https://t.me/tribute/app?startapp={{TRIBUTE_LINK_ID}})
- 💻 GitHub: [github.com/{{OWNER_USERNAME}}](https://github.com/{{OWNER_USERNAME}})

## License

MIT

---

*Built with real-world experience by {{OWNER_NAME}}.*
*Создано на основе реального опыта {{OWNER_NAME}} {{OWNER_SURNAME}}.*
```

## Чеклист перед публикацией

### Файлы (обязательные)
- [ ] `README.md` — формат EN + RU + соцсети (см. шаблон выше)
- [ ] `LICENSE` — MIT (файл, не только текст в README)
- [ ] `.gitignore` — node_modules, .env, __pycache__, .cookie, *.pyc
- [ ] `install.sh` или `setup.sh` — если есть установка

### README проверки
- [ ] EN секция полная (не обрезанная)
- [ ] RU секция зеркалит EN (те же разделы)
- [ ] Блок Resources/Ресурсы с 4 ссылками (YouTube, Telegram, {{PAID_GROUP_NAME}}, GitHub)
- [ ] Подпись курсивом на двух языках
- [ ] Нет длинных тире (—) - только дефисы (-)
- [ ] Нет канцелярита ("является", "стоит отметить", "безусловно")
- [ ] Команды установки - copy-paste рабочие
- [ ] Структура файлов актуальная (tree output)

### Код проверки
- [ ] Нет захардкоженных путей (/Users/{{OWNER_USERNAME}}/...)
- [ ] Нет API ключей, токенов, паролей
- [ ] Нет .cookie, .env файлов
- [ ] Все скрипты имеют shebang (#!/bin/bash или #!/usr/bin/env python3)
- [ ] Все скрипты исполняемые (chmod +x)
- [ ] Python файлы проходят `python3 -c "import ast; ast.parse(open('file.py').read())"` 
- [ ] Shell скрипты проходят `bash -n script.sh`
- [ ] Нет русских комментариев в коде (только в README)

### Git проверки
- [ ] .gitignore содержит: node_modules, .env, __pycache__, *.pyc, .cookie, .DS_Store
- [ ] Нет больших файлов (>1MB) — если есть, добавить в .gitignore
- [ ] Коммит message на английском: "feat: ...", "fix: ...", "docs: ..."
- [ ] Репозиторий description заполнено (Settings → About)
- [ ] Topics добавлены: openclaw, ai-agent, automation + по теме

### Описание репозитория (GitHub Settings → About)
Формат: `Краткое описание EN. Ключевое слово.`
Пример: `Complete memory and context persistence system for OpenClaw AI agents`

Topics (минимум 5): openclaw, ai-agent, ai, automation, telegram + тема проекта

## Процесс публикации (пошагово)

### 1. Подготовка
```bash
# Создать репо на GitHub (через gh CLI)
gh repo create {{OWNER_USERNAME}}/REPO_NAME --public --description "Description"

# Или если уже есть локально
cd PROJECT_DIR
git init
git remote add origin https://github.com/{{OWNER_USERNAME}}/REPO_NAME.git
```

### 2. Проверка файлов
```bash
# Поиск утечек
grep -rn "sk-ant\|sk-proj\|AAEO\|AAGX\|botToken\|cookie" --include="*.md" --include="*.py" --include="*.sh" --include="*.js" --include="*.json" .

# Поиск хардкодов
grep -rn "/Users/{{OWNER_USERNAME}}\|/home/" --include="*.md" --include="*.py" --include="*.sh" --include="*.js" .

# Синтаксис Python
find . -name "*.py" -exec python3 -c "import ast; ast.parse(open('{}').read()); print('OK: {}')" \;

# Синтаксис Bash
find . -name "*.sh" -exec bash -n {} \; -print
```

### 3. README по шаблону
Применить шаблон из секции "Стандарт README". Заменить плейсхолдеры.

### 4. Коммит и пуш
```bash
git add -A
git commit -m "feat: initial release"
git push -u origin main
```

### 5. GitHub Settings
- Description (About)
- Topics
- Website (если есть)

## Стиль текста

### Английский
- Active voice: "Agent remembers" not "Memory is persisted by agent"
- Short sentences. One idea per line
- No marketing fluff: "revolutionary", "game-changing", "cutting-edge"
- Technical but readable

### Русский
- Зеркало английского (те же разделы, тот же порядок)
- Дефис (-) вместо длинного тире (—). ВСЕГДА
- Без: "стоит отметить", "является", "безусловно", "данный"
- Короткие предложения. Конкретика
- Мат НЕ допустим в README

## Типичные ошибки (не допускать)
1. ❌ Путь `/Users/{{OWNER_USERNAME}}/...` в коде — заменить на `~/` или `$HOME`
2. ❌ `.cookie` в репо — добавить в .gitignore
3. ❌ Только русский README — обязательно EN сверху
4. ❌ Нет блока соцсетей — обязательно Resources/Ресурсы
5. ❌ Нет LICENSE файла — создать MIT
6. ❌ Описание репо пустое — заполнить About + Topics
7. ❌ Длинное тире (—) в русском тексте — только дефис (-)
