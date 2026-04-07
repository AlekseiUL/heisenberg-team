# 🧪 Heisenberg Team

> ⚠️ **Перед началом:** Замените `YOUR_USERNAME` на ваш GitHub username в командах клонирования.

**Мультиагентная система из 8 AI-агентов, работающих как команда.** Построена на [OpenClaw](https://github.com/openclaw/openclaw). Вдохновлена Breaking Bad.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/Built%20with-OpenClaw-blue)](https://github.com/openclaw/openclaw)
[![Agents](https://img.shields.io/badge/Agents-8-green)]()
[![Skills](https://img.shields.io/badge/Skills-33-orange)]()

---

## Оглавление

- [Что это?](#что-это)
- [Зачем?](#зачем)
- [Чем отличается?](#чем-отличается)
- [Архитектура](#архитектура)
- [Агенты](#агенты)
- [Быстрый старт](#быстрый-старт)
- [Скиллы (33)](#скиллы-33)
- [Структура проекта](#структура-проекта)
- [Примеры](#примеры)
- [Документация](#документация)
- [Вклад](#вклад)
- [Лицензия](#лицензия)

---

## Что это?

Готовый шаблон для запуска **команды AI-агентов**, которые общаются между собой, делегируют задачи и доставляют результат. У каждого агента - своя роль, характер и набор скиллов.

Это не фреймворк. Это **рабочая система**, которую можно клонировать, настроить и запустить.

## Зачем?

- **Один координатор, семь специалистов.** Продуктовые задачи обычно начинаются с Сола (`producer`), дальше он маршрутизирует к нужному агенту. Хайзенберг (`main`) подключается для стратегии и эскалаций.
- **33 скилла.** Генерация PDF, исследования, маркетинг, аудиты безопасности, финансовый учёт, код-ревью — из коробки.
- **Board-First протокол.** Задачи переживают краши. Файловое состояние, не память. Никакая работа не теряется.
- **Самоисцеление.** Health checks, watchdogs, автоматическая очистка сессий. Система мониторит себя сама.
- **Ваши данные остаются вашими.** Все личные данные используют формат `{{PLACEHOLDER}}`. Мастер настройки заполняет их за 5 минут.

## Чем отличается?

| Особенность | Heisenberg Team | AutoGPT | CrewAI | MetaGPT |
|-------------|----------------|---------|--------|---------|
| Настройка | Мастер 5 минут | Ручной YAML | Код на Python | Код на Python |
| Восстановление после краша | Файловый board переживает перезапуски | В памяти, теряется при крахе | В памяти | В памяти |
| Координация агентов | Board-First протокол + sessions_send | Общая память | Последовательно/иерархически | На основе SOP |
| Самоисцеление | Встроено (на основе cron) | Нет | Нет | Нет |
| Библиотека скиллов | 34 готовых | Экосистема плагинов | Пишите сами | Пишите сами |
| Личность | Постоянный SOUL.md для каждого агента | Общая | Описание роли | Описание роли |
| Память | SQLite + векторный поиск + файлы | Vector DB | Только краткосрочная | Общая память |
| Мониторинг | Heartbeat + health checks | Только логи | Только логи | Только логи |
| Мультиплатформенность | macOS + Linux + WSL | Docker | Python | Python |

## Архитектура

```mermaid
graph TB
    User["👤 You (Telegram)"]
    
    subgraph team["🧪 Heisenberg Team"]
        HB["🧪 Heisenberg<br/>Boss & Escalation<br/><i>Opus</i>"]
        
        subgraph specialists["Specialists"]
            Saul["💼 Saul Goodman<br/>Producer<br/><i>Sonnet</i>"]
            Walter["👨‍🔬 Walter White<br/>Tech Lead<br/><i>Sonnet</i>"]
            Jesse["🎯 Jesse Pinkman<br/>Marketing<br/><i>Sonnet</i>"]
            Skyler["💰 Skyler White<br/>Finance<br/><i>Sonnet</i>"]
            Hank["🔫 Hank Schrader<br/>Security<br/><i>Sonnet</i>"]
            Gus["🎯 Gus Fring<br/>Kaizen/Goals<br/><i>Sonnet</i>"]
            Twins["👥 Salamanca Twins<br/>Research<br/><i>Sonnet</i>"]
        end
        
        Board["📋 Team Board<br/><i>File-based state</i>"]
        Memory["🧠 Memory<br/><i>SQLite + Vectors</i>"]
        Skills["⚡ 33 Skills<br/><i>PDF, XLSX, Research...</i>"]
    end
    
    User -->|"message"| HB
    HB -->|"sessions_send"| Saul
    HB -->|"sessions_send"| Walter
    HB -->|"sessions_send"| Jesse
    HB -->|"sessions_send"| Skyler
    HB -->|"sessions_send"| Hank
    HB -->|"sessions_send"| Gus
    HB -->|"sessions_send"| Twins
    Saul -->|"coordinate"| Board
    Walter --> Skills
    Jesse --> Skills
    Skyler --> Skills
    HB --> Memory
    Saul --> Memory
    
    style HB fill:#ff6b35,stroke:#333,color:#fff
    style Saul fill:#4ecdc4,stroke:#333,color:#fff
    style Walter fill:#45b7d1,stroke:#333,color:#fff
    style Jesse fill:#96ceb4,stroke:#333,color:#fff
    style Skyler fill:#dda0dd,stroke:#333,color:#fff
    style Hank fill:#ff6b6b,stroke:#333,color:#fff
    style Gus fill:#ffd93d,stroke:#333,color:#000
    style Twins fill:#6c5ce7,stroke:#333,color:#fff
    style Board fill:#2d3436,stroke:#333,color:#fff
    style Memory fill:#2d3436,stroke:#333,color:#fff
    style Skills fill:#2d3436,stroke:#333,color:#fff
```
## Агенты

| Агент | Персонаж | Роль | Ключевые скиллы |
|-------|----------|------|-----------------|
| **Heisenberg** | Уолтер Уайт | Босс, стратегия и эскалации | Делегирование, эскалации |
| **Saul** | Сол Гудман | Координатор | Пайплайн, брифинги |
| **Walter** | Уолтер Уайт (лаб.) | Тимлид | Код, PDF, GitHub |
| **Jesse** | Джесси Пинкман | Маркетинг | Воронки, кампании |
| **Skyler** | Скайлер Уайт | Админ/Финансы | DOCX, XLSX, договоры |
| **Hank** | Хэнк Шрейдер | Безопасность/QA | Аудиты, мониторинг |
| **Gus** | Гус Фринг | Кайдзен | Кроны, самоулучшение |
| **Twins** | Братья Саламанка | Ресёрч | Глубокий ресёрч |

## Требования

- [Node.js](https://nodejs.org/) v18+
- [OpenClaw](https://github.com/openclaw/openclaw) (`npm install -g openclaw`)
- API-ключ хотя бы одного LLM-провайдера (Anthropic, OpenAI, Google, DeepSeek)
- Telegram-бот токен (опционально, для уведомлений через [@BotFather](https://t.me/BotFather))

### Системные требования

| | Минимум | Рекомендовано |
|---|---------|-----------------|
| RAM | 2 GB | 4 GB (8 агентов) |
| Диск | 500 MB | 2 GB (с логами/памятью) |
| ОС | macOS 11+, Ubuntu 20.04+, Windows 11 (WSL2) | macOS 13+ или Ubuntu 22.04+ |
| Node.js | 18.x | 20.x+ |
| Сеть | Необходима (вызовы LLM API) | Широкополосный доступ |

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

## Скиллы (33)

Команда использует библиотеку из 33 скиллов:

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
├── skills/          # 33 общих скилла
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
- [Поддерживаемые провайдеры](SETUP.md#supported-llm-providers) - Anthropic, OpenAI, Google, DeepSeek, Ollama
- [Онбординг агентов](docs/agent-onboarding.md) - настройка при первом запуске
- [Архитектура](docs/architecture.md)
- [Роли агентов](docs/agent-roles.md)
- [Установка на Linux](docs/linux-setup.md)
- [FAQ](docs/faq.md)

## Лицензия

[MIT](LICENSE)

---

*Построено на [OpenClaw](https://github.com/openclaw/openclaw) - open-source платформе для AI-агентов.*
