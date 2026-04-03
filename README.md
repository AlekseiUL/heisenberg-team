# 🧪 Heisenberg Team

**A multi-agent system with 8 AI agents working as a team.** Built on [OpenClaw](https://github.com/openclaw/openclaw). Inspired by Breaking Bad.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/Built%20with-OpenClaw-blue)](https://github.com/openclaw/openclaw)
[![Agents](https://img.shields.io/badge/Agents-8-green)]()
[![Skills](https://img.shields.io/badge/Skills-34-orange)]()

---

## Requirements

- [Node.js](https://nodejs.org/) v18+
- [OpenClaw](https://github.com/openclaw/openclaw) (`npm install -g openclaw`)
- API key for at least one LLM provider (Anthropic, OpenAI, Google)
- Telegram bot token (optional, for notifications via [@BotFather](https://t.me/BotFather))

## What is this?

A production-ready template for running a **team of AI agents** that communicate, delegate tasks, and deliver results. Each agent has a defined role, personality, and set of skills.

This is not a framework. This is a **working system** you can clone, configure, and run.

## Why?

- **One boss, seven specialists.** You talk to Heisenberg. He delegates to the right agent. You get results.
- **34 skills.** PDF generation, research, marketing, security audits, financial tracking, code review — out of the box.
- **Board-First protocol.** Tasks survive crashes. File-based state, not memory. No work is lost.
- **Self-healing.** Health checks, watchdogs, automatic session cleanup. The system monitors itself.
- **Your data stays yours.** All personal data uses `{{PLACEHOLDER}}` format. Setup wizard fills them in 5 minutes.

## Architecture

```
User ←→ Heisenberg (Main Agent)
              │
              ├── Saul (Coordinator) ──→ Manages pipeline, assigns tasks
              │     │
              │     ├── Walter (Team Lead) ──→ Code, PDFs, skills, production
              │     ├── Jesse (Marketing) ──→ Funnels, analytics, campaigns
              │     ├── Skyler (Admin) ──→ Documents, finance, contracts
              │     ├── Hank (Security) ──→ Audits, monitoring, QA
              │     ├── Gus (Kaizen) ──→ Crons, optimization, self-healing
              │     └── Twins (Research) ──→ Deep research, competitor analysis
              │
              └── 34 Skills (shared toolkit)
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

# 2. Configure environment
cp .env.example .env
# Edit .env with your LLM API key

# 3. Interactive setup (recommended)
bash scripts/setup-wizard.sh

# 4. Initialize OpenClaw (first time only)
openclaw init

# 5. Run
openclaw gateway start
```

The setup wizard will ask for your name, Telegram ID, and other settings, then configure everything automatically.

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
