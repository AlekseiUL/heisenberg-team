# 🧪 Heisenberg Team

> ⚠️ **Перед началом:** Замените `YOUR_USERNAME` на ваш GitHub username в командах клонирования.

**Мультиагентная система из 8 AI-агентов, работающих как команда.** Построена на [OpenClaw](https://github.com/openclaw/openclaw). Вдохновлена Breaking Bad.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/Built%20with-OpenClaw-blue)](https://github.com/openclaw/openclaw)
[![Agents](https://img.shields.io/badge/Agents-8-green)]()
[![Skills](https://img.shields.io/badge/Skills-34-orange)]()

---

## Что это?

Готовый шаблон для запуска **команды AI-агентов**, которые общаются между собой, делегируют задачи и доставляют результат. У каждого агента - своя роль, характер и набор скиллов.

Это не фреймворк. Это **рабочая система**, которую можно клонировать, настроить и запустить.

## Архитектура

```
Пользователь ←→ Хайзенберг (Главный агент)
                     │
                     ├── Сол (Координатор) ──→ Управляет пайплайном, раздаёт задачи
                     │     │
                     │     ├── Уолтер (Тимлид) ──→ Код, PDF, скиллы, производство
                     │     ├── Джесси (Маркетинг) ──→ Воронки, аналитика, кампании
                     │     ├── Скайлер (Админ) ──→ Документы, финансы, договоры
                     │     ├── Хэнк (Безопасность) ──→ Аудиты, мониторинг, QA
                     │     ├── Гус (Кайдзен) ──→ Кроны, оптимизация, самоисцеление
                     │     └── Близнецы (Ресёрч) ──→ Глубокий ресёрч, анализ конкурентов
                     │
                     └── 34 Скиллов (общий тулкит)
```

## Агенты

| Агент | Персонаж | Роль | Ключевые скиллы |
|-------|----------|------|-----------------|
| **Heisenberg** | Уолтер Уайт | Босс | Делегирование, доставка |
| **Saul** | Сол Гудман | Координатор | Пайплайн, брифинги |
| **Walter** | Уолтер Уайт (лаб.) | Тимлид | Код, PDF, GitHub |
| **Jesse** | Джесси Пинкман | Маркетинг | Воронки, кампании |
| **Skyler** | Скайлер Уайт | Админ/Финансы | DOCX, XLSX, договоры |
| **Hank** | Хэнк Шрейдер | Безопасность/QA | Аудиты, мониторинг |
| **Gus** | Гус Фринг | Кайдзен | Кроны, самоулучшение |
| **Twins** | Братья Саламанка | Ресёрч | Глубокий ресёрч |

## Быстрый старт

```bash
# 1. Клонировать
git clone https://github.com/YOUR_USERNAME/heisenberg-team.git
cd heisenberg-team

# 2. Настроить
cp .env.example .env
# Отредактируй .env своими значениями

# 3. Установить
bash scripts/setup.sh

# 4. Запустить
openclaw gateway start
```

Подробная инструкция: [SETUP.md](SETUP.md)

## Скиллы (34)

Команда использует библиотеку из 34 скиллов:

- **Контент:** copywriter, youtube-seo, presentation, pptx-generator
- **Ресёрч:** researcher, deep-research-pro, channel-analyzer, reddit
- **Документы:** minimax-pdf, minimax-docx, minimax-xlsx, nano-pdf
- **Разработка:** coding-agent, cursor-agent, github-publisher
- **Автоматизация:** n8n-workflow-automation, blogwatcher, browser-use
- **Аналитика:** analytics, audit-website, business-architect
- **Специализированные:** family-doctor, auto-mechanic, weather и другие

Полный список в [skills/](skills/).

## Структура проекта

```
heisenberg-team/
├── agents/          # 8 агентов, каждый со своими конфигами
├── skills/          # 34 общих скиллов
├── scripts/         # Утилиты
├── references/      # Конституция команды, стандарты
├── examples/        # Кукбуки и гайды
├── docs/            # Архитектура, FAQ
└── assets/          # Картинки для документации
```

## Примеры

- [Добавить нового агента](examples/add-new-agent.md)
- [Создать скилл](examples/create-skill.md)
- [Настроить крон-задачи](examples/configure-crons.md)

## Документация

- [Апгрейд с одного агента](docs/upgrade-from-single-agent.md) - миграция с single-agent setup
- [Поддерживаемые провайдеры](SETUP.md#supported-llm-providers) - Anthropic, OpenAI, Google, Ollama
- [Онбординг агентов](docs/agent-onboarding.md) - настройка при первом запуске
- [Архитектура](docs/architecture.md)
- [Роли агентов](docs/agent-roles.md)
- [Установка на Linux](docs/linux-setup.md)
- [FAQ](docs/faq.md)

## Лицензия

[MIT](LICENSE)

---

*Построено на [OpenClaw](https://github.com/openclaw/openclaw) - open-source платформе для AI-агентов.*
