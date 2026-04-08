# Deploying the Heisenberg Team

## Overview

What you'll build: **8 specialized AI agents** that communicate via `sessions_send`, each with its own Telegram bot, workspace, and memory.

| Property | Value |
|----------|-------|
| Agents | 8 (Heisenberg, Saul, Walter, Jesse, Skyler, Hank, Gus, Twins) |
| Communication | `sessions_send` (real-time ping-pong) |
| Setup time | ~30-45 minutes for full team |
| Minimum setup | ~10 minutes (Heisenberg only) |

All agents run inside **one OpenClaw gateway** as separate agent sessions. Each agent has its own workspace directory, memory, crons, and personality — but they share a single gateway process.

---

## Prerequisites

- **Node.js 18+** — `node --version`
- **npm** — `npm --version`
- **OpenClaw** — `npm install -g openclaw`
- **Telegram account** — to receive messages from agents
- **Claude API key** (or other LLM provider key)
- **OpenAI API key** — for vector memory embeddings (text-embedding-3-small)
- **A machine that stays online** — Mac, Linux server, or VPS

Verify OpenClaw is installed:
```bash
openclaw --version
```

---

## Step 1: Create Telegram Bots (5 min)

1. Open **[@BotFather](https://t.me/BotFather)** in Telegram
2. Create 8 bots (one per agent):

```
/newbot → Name: "Heisenberg"       → Username: heisenberg_yourname_bot
/newbot → Name: "Saul Goodman"     → Username: saul_yourname_bot
/newbot → Name: "Walter White"     → Username: walter_yourname_bot
/newbot → Name: "Jesse Pinkman"    → Username: jesse_yourname_bot
/newbot → Name: "Skyler White"     → Username: skyler_yourname_bot
/newbot → Name: "Hank Schrader"    → Username: hank_yourname_bot
/newbot → Name: "Gus Fring"        → Username: gus_yourname_bot
/newbot → Name: "The Cousins"      → Username: twins_yourname_bot
```

3. **Save each bot token** — BotFather gives you a token like `7123456789:AAHxxx...`
4. Find your **Telegram user ID** — message [@userinfobot](https://t.me/userinfobot), it replies with your numeric ID

> 💡 You don't need to create all 8 bots at once. Start with Heisenberg only.

---

## Step 2: Prepare Workspaces (5 min)

Run the automated deploy script:

```bash
cd ~/Desktop/heisenberg-team
bash scripts/deploy-team.sh
```

This creates `~/openclaw-agents/<agent>/` for each agent with the full directory structure.

**Or manually** for a single agent:

```bash
AGENT=heisenberg
mkdir -p ~/openclaw-agents/$AGENT/{memory/core,memory/decisions,memory/archive,references,scripts}

# Copy agent files
cp agents/$AGENT/*.md ~/openclaw-agents/$AGENT/

# Copy shared references
cp references/team-constitution.md ~/openclaw-agents/$AGENT/references/

# Copy config example
cp configs/$AGENT.openclaw.json.example ~/openclaw-agents/$AGENT/openclaw.json.example
```

Each workspace gets:
- `AGENTS.md` — routing rules and team map
- `SOUL.md` — agent personality
- `IDENTITY.md` — who this agent is
- `TOOLS.md` — tool configuration
- `MEMORY.md` — persistent memory
- `BOOTSTRAP.md` — startup sequence
- `HEARTBEAT.md` — heartbeat rules
- `references/team-constitution.md` — shared team protocol

---

## Step 3: Configure Each Agent (10 min)

For each agent, create its OpenClaw config:

```bash
AGENT=heisenberg

# Create config directory
mkdir -p ~/.openclaw/agents/$AGENT

# Prepare a local generated config first
mkdir -p configs/generated
cp configs/$AGENT.openclaw.json.example configs/generated/$AGENT.openclaw.json

# Copy the generated config into OpenClaw's runtime location
cp configs/generated/$AGENT.openclaw.json ~/.openclaw/agents/$AGENT/openclaw.json
```

Then **edit the generated config** and replace placeholders:

| Placeholder | Replace with |
|-------------|-------------|
| `{{TELEGRAM_BOT_TOKEN}}` | Bot token from BotFather (e.g. `7123456789:AAHxxx...`) |
| `{{OWNER_TELEGRAM_ID}}` | Your numeric Telegram ID (e.g. `123456789`) |
| `{{ANTHROPIC_API_KEY}}` | Your Claude API key (`sk-ant-...`) |
| `{{OPENAI_API_KEY}}` | Your OpenAI API key (`sk-...`) for embeddings |

**Minimum config** (Heisenberg only, no remote agents needed initially):

```json
{
  "version": 1,
  "name": "Heisenberg",
  "model": { "default": "anthropic/claude-opus-4-5" },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true,
        "config": {
          "botToken": "YOUR_BOT_TOKEN_HERE",
          "authorizedSenders": ["YOUR_TELEGRAM_ID_HERE"]
        }
      }
    }
  },
  "workspace": { "path": "~/openclaw-agents/heisenberg" }
}
```

---

## Step 4: Start Agents (5 min)

### Start the gateway:

```bash
openclaw gateway start
```

One gateway runs all agents. No need to start each separately.

### Verify it's running:

```bash
openclaw status
```

> ✅ All agents share one gateway. No need to run multiple processes or manage ports.

---

## Step 5: Verify Communication (5 min)

1. **Message Heisenberg** via Telegram: `"Hello, are you there?"`
2. Heisenberg should respond within a few seconds
3. **Test delegation**: `"Test delegation to Walter"`
4. Heisenberg should use `sessions_send` to reach Walter
5. Walter should respond back through Heisenberg

If Walter isn't running yet, Heisenberg will note the agent is unavailable and handle the task itself.

**Verify agent-to-agent communication directly:**

```bash
# In Heisenberg's workspace, test sessions_send
cd ~/openclaw-agents/heisenberg
openclaw eval 'sessions_send(sessionKey="agent:teamlead:main", message="ping", timeoutSeconds=10)'
```

---

## Step 6: Set Up Crons (optional)

Add cron jobs for automated tasks. Edit with `crontab -e`:

```cron
# Heisenberg heartbeat every 30 min
*/30 * * * * cd ~/openclaw-agents/heisenberg && openclaw cron heartbeat

# Self-heal watchdog every 2 hours
0 */2 * * * bash ~/openclaw-agents/heisenberg/scripts/self-heal.sh

# Night cleanup at 3 AM
0 3 * * * bash ~/openclaw-agents/heisenberg/scripts/night-cleanup.sh

# Agent health check every hour
0 * * * * bash ~/openclaw-agents/heisenberg/scripts/agent-health-check.sh
```

> 💡 Use `anthropic/claude-sonnet-4-5` (not opus) for all cron-triggered agent turns to save costs.

---

## Agent Communication

Agents communicate via `sessions_send` — synchronous ping-pong calls:

```
sessions_send(
  sessionKey="agent:teamlead:main",
  message="Implement feature X in project Y",
  timeoutSeconds=120
)
```

### Session keys by agent:

| Agent | Session Key |
|-------|-------------|
| Heisenberg | `agent:main:main` |
| Saul | `agent:producer:main` |
| Walter | `agent:teamlead:main` |
| Jesse | `agent:marketing-funnel:main` |
| Skyler | `agent:skyler:main` |
| Hank | `agent:hank:main` |
| Gus | `agent:kaizen:main` |
| Twins | `agent:researcher:main` |

### Board-First Protocol

Tasks flow through `references/team-board.md`:

1. Heisenberg writes task to board
2. Sends brief via `sessions_send`
3. Agent picks up task, marks `[ВЗЯЛ]`
4. Agent completes, marks `[ГОТОВО]`
5. Agent replies via `sessions_send`

### Anti-Silence Rule

No agent should be silent for more than **60 seconds** on an active task:
- Delegated → "Передал, слежу" (Delegated, watching)
- 60s no response → "Думает" (Thinking)
- 120s no response → Take the task back, handle directly

---

## Architecture Diagram

```
You (Telegram)
      │
      ▼
Heisenberg Bot ──────────── delegates via sessions_send ──────────────────────────────────┐
(Boss, Opus model)                                                                         │
      │                                                                                    │
      ├──► Saul (Producer)          agent:producer:main         Content pipeline, ОТК     │
      ├──► Walter (Tech Lead)       agent:teamlead:main         Code, files, complex tasks│
      ├──► Jesse (Marketing)        agent:marketing-funnel:main Funnels, CTR, analytics   │
      ├──► Skyler (Finance)         agent:skyler:main           Budgets, reports           │
      ├──► Hank (Security)          agent:hank:main             Audits, QA, monitoring     │
      ├──► Gus (Kaizen)             agent:kaizen:main           Goals, habits, Obsidian    │
      └──► Twins (Research)         agent:researcher:main       Web search, monitoring     │
                                                                                           │
All agents share one gateway — each has own workspace + memory + crons ◄────────────────┘
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Agent not responding | `openclaw status` — check gateway is running |
| `sessions_send` fails | Verify agent is configured in `openclaw.json` agents section |
| Agent not listed | Check agent config in `~/.openclaw/agents/<agent>/` |
| Memory not working | `openclaw doctor` — checks SQLite WAL mode |
| Bot not receiving messages | Verify `authorizedSenders` has your numeric Telegram ID |
| Config not found | Check `~/.openclaw/agents/<agent>/openclaw.json` exists |
| Placeholder not replaced | `grep -r '{{' ~/openclaw-agents/<agent>/` |
| Agent uses wrong model | Check `model.default` in config — crons must use sonnet |

### Logs

```bash
# View gateway logs
openclaw gateway logs

# Tail live logs
openclaw gateway logs --follow
```

### Reset an agent session

```bash
# Kill the agent's session (gateway stays running)
openclaw kill agent:main:main

# Or restart the whole gateway if needed
openclaw gateway restart
```

---

## Starting Small

**Don't deploy all 8 at once!** Recommended deployment order:

### Phase 1: Core (Day 1)
1. **Heisenberg** — required, the hub everything routes through
2. **Walter** — most useful immediately, handles code and file tasks

### Phase 2: Pipeline (Day 2-3)
3. **Saul** — coordinates content delivery, ОТК
4. **Gus** — goals and habits tracking

### Phase 3: Full Team (Week 1)
5. **Jesse** — marketing funnels and analytics
6. **Hank** — security audits and QA
7. **Skyler** — financial tracking
8. **Twins** — research and monitoring

Each phase is independently useful. Only add an agent when you have a specific need for it.

---

## Security Notes

- **Never commit** bot tokens or API keys to git
- Use `configs/*.json.example` files with `{{PLACEHOLDERS}}` for the repo
- Real configs live in `~/.openclaw/agents/<agent>/openclaw.json` (outside repo)
- Set `authorizedSenders` to only your Telegram ID — blocks unauthorized access
- Each agent only needs to know about the other agents it actually delegates to

---

*See also: [Architecture](architecture.md) · [Agent Roles](agent-roles.md) · [FAQ](faq.md)*
