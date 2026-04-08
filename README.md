# 🧪 Heisenberg Team

**A multi-agent system with 8 AI agents working as a team.** Built on [OpenClaw](https://github.com/openclaw/openclaw). Inspired by Breaking Bad.

Release 2 adds better direct-message behavior, durable-memory rules, and updated OpenClaw operations.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/Built%20with-OpenClaw-blue)](https://github.com/openclaw/openclaw)
[![Agents](https://img.shields.io/badge/Agents-8-green)]()
[![Skills](https://img.shields.io/badge/Skills-34-orange)]()

---

## Table of Contents

- [What is this?](#what-is-this)
- [Why?](#why)
- [How is this different?](#how-is-this-different)
- [Architecture](#architecture)
- [Agents](#agents)
- [Quick Start](#quick-start)
- [Skills (34)](#skills-34)
- [Project Structure](#project-structure)
- [Examples](#examples)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Requirements

- [Node.js](https://nodejs.org/) v18+
- [OpenClaw](https://github.com/openclaw/openclaw) (`npm install -g openclaw`)
- Auth for at least one LLM provider (Anthropic, OpenAI, OpenAI Codex, Google, DeepSeek, or local models)
- Telegram bot token (optional, for notifications via [@BotFather](https://t.me/BotFather))

### System Requirements

| | Minimum | Recommended |
|---|---------|-------------|
| RAM | 2 GB | 4 GB (8 agents) |
| Disk | 500 MB | 2 GB (with logs/memory) |
| OS | macOS 11+, Ubuntu 20.04+, Windows 11 (WSL2) | macOS 13+ or Ubuntu 22.04+ |
| Node.js | 18.x | 20.x+ |
| Network | Required (LLM API calls) | Broadband |

## What is this?

A production-ready template for running a **team of AI agents** that communicate, delegate tasks, and deliver results. Each agent has a defined role, personality, and set of skills.

This is not a framework. This is a **working system** you can clone, configure, and run.

## Why?

- **One boss, seven specialists.** You talk to Heisenberg. He delegates to the right agent. You get results.
- **34 skills.** PDF generation, research, marketing, security audits, financial tracking, code review — out of the box.
- **Board-First protocol.** Tasks survive crashes. File-based state, not memory. No work is lost.
- **Self-healing.** Health checks, watchdogs, automatic session cleanup. The system monitors itself.
- **Your data stays yours.** All personal data uses `{{PLACEHOLDER}}` format. Setup wizard fills them in 5 minutes.

## How is this different?

| Feature | Heisenberg Team | AutoGPT | CrewAI | MetaGPT |
|---------|----------------|---------|--------|---------|
| Setup | 5-min wizard | Manual YAML | Python code | Python code |
| Crash recovery | File-based board survives restarts | In-memory, lost on crash | In-memory | In-memory |
| Agent coordination | Board-First protocol + sessions_send | Shared memory | Sequential/hierarchical | SOP-based |
| Self-healing | Built-in (cron-based) | No | No | No |
| Skills library | 34 ready-to-use | Plugin ecosystem | Build your own | Build your own |
| Personality | Persistent SOUL.md per agent | Generic | Role description | Role description |
| Memory | SQLite + vector search + file-based | Vector DB | Short-term only | Shared memory |
| Monitoring | Heartbeat + health checks | Logs only | Logs only | Logs only |
| Multi-platform | macOS + Linux + WSL | Docker | Python | Python |

## Architecture

```mermaid
graph TB
    User["👤 You (Telegram)"]
    
    subgraph team["🧪 Heisenberg Team"]
        HB["🧪 Heisenberg<br/>Boss & Coordinator<br/><i>Opus</i>"]
        
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
        Skills["⚡ 34 Skills<br/><i>PDF, XLSX, Research...</i>"]
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
## Agents

| Agent | Character | Role | Key Skills |
|-------|-----------|------|------------|
| **Heisenberg** | Walter White | Boss, user-facing | Delegation, delivery |
| **Saul** | Saul Goodman | Coordinator | Pipeline management, briefings |
| **Walter** | Walter White (lab) | Team Lead | Code, PDF, GitHub, skills |
| **Jesse** | Jesse Pinkman | Marketing | Funnels, campaigns, analytics |
| **Skyler** | Skyler White | Admin/Finance | DOCX, XLSX, contracts |
| **Hank** | Hank Schrader | Security/QA | Audits, monitoring |
| **Gus** | Gus Fring | Kaizen | Crons, self-improvement |
| **Twins** | Salamanca Twins | Research | Deep research, web analysis |

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/heisenberg-team.git
cd heisenberg-team

# 2. Optional bootstrap installer
bash scripts/bootstrap-install.sh

# 3. Configure environment
cp .env.example .env
# Edit .env with your LLM API key

# 4. Interactive setup (recommended)
bash scripts/setup-wizard.sh

# 4. Initialize OpenClaw (first time only)
openclaw init

# 5. Run
openclaw gateway start
bash scripts/smoke-test.sh
```

The setup wizard will ask for your name, Telegram ID, and other settings, then configure everything automatically.

The setup wizard now supports:
- selected agents only
- per-agent Telegram bot tokens
- custom display names
- generated configs in `configs/generated/`
- a dedicated team directory root

Need a narrower rollout first?

```bash
# Selected agents only
bash scripts/setup.sh --agents heisenberg,saul,walter
bash scripts/smoke-test.sh --agents heisenberg,saul,walter

# Attach to an existing OpenClaw install
bash scripts/setup.sh --attach-existing --agents heisenberg,walter
```

See [SETUP.md](SETUP.md) for detailed installation guide or [docs/first-task.md](docs/first-task.md) for your first walkthrough.

> **Language note:** Agent personalities and team protocols are in Russian. The architecture works in any language — edit `SOUL.md` and `AGENTS.md` in each agent to change language.

> **Platform note:** Utility scripts in `scripts/` are optimized for macOS but support Linux/WSL. See [Linux Setup](docs/linux-setup.md) for platform-specific instructions.

## Skills (34)

The team shares a library of 34 skills covering:

- **Content:** copywriter, youtube-seo, presentation, pptx-generator
- **Research:** researcher, deep-research-pro, channel-analyzer, reddit
- **Documents:** minimax-pdf, minimax-docx, minimax-xlsx, nano-pdf
- **Development:** coding-agent, cursor-agent, github-publisher
- **Automation:** n8n-workflow-automation, blogwatcher, browser-use
- **Analysis:** analytics, audit-website, business-architect
- **Specialized:** family-doctor, auto-mechanic, dog-kinolog, astrologer, weather

Full list with dependencies in [skills/README.md](skills/README.md).

## Project Structure

```
heisenberg-team/
├── agents/          # 8 agents, each with config files
├── skills/          # 34 shared skills
├── scripts/         # Utility and automation scripts
├── references/      # Team constitution, standards
├── examples/        # Cookbooks and guides
└── docs/            # Architecture, FAQ
```

### 🤖 Deploy Full Team (Optional)

Want all 8 agents working together? See the [Multi-Agent Deployment Guide](docs/deploy-agents.md).

```bash
# Automated workspace setup
bash scripts/deploy-team.sh
```

## Examples

- [Add a new agent](examples/add-new-agent.md)
- [Create a skill](examples/create-skill.md)
- [Configure cron jobs](examples/configure-crons.md)

## Documentation

- [Your First Task](docs/first-task.md) - step-by-step walkthrough
- [Upgrade from Single Agent](docs/upgrade-from-single-agent.md) - migrate from single-agent setup
- [Supported Providers](SETUP.md#supported-llm-providers) - Anthropic, OpenAI, Google, DeepSeek, Ollama
- [Agent Onboarding](docs/agent-onboarding.md) - configure agents on first launch
- [Architecture](docs/architecture.md) - how agents communicate
- [Agent Roles](docs/agent-roles.md) - what each agent does
- [Linux Setup](docs/linux-setup.md) - running on Ubuntu/Debian
- [FAQ](docs/faq.md) - common questions and troubleshooting
- [Skills Index](skills/README.md) - all 34 skills with dependencies

## Contributing

1. Fork the repo
2. Create a branch (`git checkout -b feature/new-agent`)
3. Commit changes (`git commit -m 'Add new agent'`)
4. Push (`git push origin feature/new-agent`)
5. Open a Pull Request

## License

[MIT](LICENSE)

---

## 🇷🇺 Русская версия

Полная документация на русском: [README.ru.md](README.ru.md)

---

*Built with [OpenClaw](https://github.com/openclaw/openclaw) - the open-source AI agent platform.*
