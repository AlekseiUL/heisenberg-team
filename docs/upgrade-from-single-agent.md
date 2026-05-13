# Upgrade from Single Agent to Full Team

Already running OpenClaw with a single agent? This guide helps you deploy the full Heisenberg Team alongside your existing setup.

## Overview

```
BEFORE:                          AFTER:
┌──────────────┐                ┌──────────────┐
│  Your Agent  │                │  Heisenberg  │ ← Boss (your main contact)
│  (OpenClaw)  │                │              │
│  Port 3120   │                │  Port 3120   │
└──────────────┘                └──────┬───────┘
                                      │ delegates to
                          ┌───────────┼───────────┐
                          │           │           │
                     ┌────┴───┐ ┌────┴───┐ ┌────┴───┐
                     │  Saul  │ │ Walter │ │ Jesse  │ ...
                     │  3121  │ │  3122  │ │  3123  │
                     └────────┘ └────────┘ └────────┘
```

## Step 1: Clone the Repository

```bash
cd ~/Desktop  # or wherever you keep projects
git clone https://github.com/AlekseiUL/heisenberg-team.git
cd heisenberg-team
```

## Step 2: Run Setup Wizard

```bash
bash scripts/setup-wizard.sh
```

The wizard will:
- Ask for your name, timezone, preferences
- Let you choose your LLM provider
- Configure API keys
- Replace all `{{PLACEHOLDER}}` values

## Step 3: Decide What to Keep

### Option A: Replace your current agent with Heisenberg
Your existing agent becomes Heisenberg. Copy the workspace files:

```bash
# Back up your current workspace
cp -r ~/your-current-workspace ~/your-current-workspace.backup

# Copy Heisenberg agent files into your workspace
cp agents/heisenberg/AGENTS.md ~/your-current-workspace/
cp agents/heisenberg/SOUL.md ~/your-current-workspace/
cp agents/heisenberg/IDENTITY.md ~/your-current-workspace/
cp agents/heisenberg/BOOTSTRAP.md ~/your-current-workspace/
cp agents/heisenberg/HEARTBEAT.md ~/your-current-workspace/
cp agents/heisenberg/TOOLS.md ~/your-current-workspace/
cp agents/heisenberg/MEMORY.md ~/your-current-workspace/
mkdir -p ~/your-current-workspace/references/
cp references/team-constitution.md ~/your-current-workspace/references/
cp references/team-board.md.example ~/your-current-workspace/references/team-board.md
```

Update your existing `~/.openclaw/openclaw.json` - add the `agents.remoteAgents` section from `configs/heisenberg.openclaw.json.example`.

If you want to keep your current install and add only a few team members first, run:

```bash
bash scripts/setup.sh --attach-existing --agents heisenberg,saul,walter
bash scripts/smoke-test.sh --agents heisenberg,saul,walter
```

### Option B: Fresh start with Heisenberg as main agent
```bash
# Prepare a local config from the example
mkdir -p configs/generated
cp configs/heisenberg.openclaw.json.example configs/generated/heisenberg.openclaw.json

# Edit with your API keys
nano configs/generated/heisenberg.openclaw.json

# Install to OpenClaw runtime location
mkdir -p ~/.openclaw/agents/main
cp configs/generated/heisenberg.openclaw.json ~/.openclaw/agents/main/openclaw.json

# Set workspace
# In openclaw.json, set "workspace" to the heisenberg-team/agents/heisenberg/ directory
```

## Step 4: Create Telegram Bots

For each agent you want to deploy, create a bot in @BotFather:

1. Open @BotFather in Telegram
2. Send `/newbot`
3. Name it (e.g., "Walter White Agent")
4. Get the token

You need one bot per agent. Minimum recommended:
- **Heisenberg** (main — can be your existing bot)
- **Saul** (coordinator — handles task pipeline)
- **Walter** (code tasks)

Others can be added later as needed.

## Step 5: Deploy Agents

For each additional agent:

```bash
# Prepare a local generated config
mkdir -p configs/generated
cp configs/saul.openclaw.json.example configs/generated/saul.openclaw.json

# Edit: add your bot token and API keys
nano configs/generated/saul.openclaw.json

# Install into OpenClaw runtime location
mkdir -p ~/.openclaw/agents/producer
cp configs/generated/saul.openclaw.json ~/.openclaw/agents/producer/openclaw.json
```

Then start the shared gateway once:
```bash
openclaw gateway start
```

Or use the deploy script:
```bash
bash scripts/deploy-team.sh
```

See [deploy-agents.md](deploy-agents.md) for detailed multi-agent setup.

## Step 6: Test Communication

Send a message to Heisenberg:
```
Hey, check if Saul is online
```

Heisenberg should use `sessions_send` to ping Saul and report back.

## Step 7: Migrate Your Data

Your existing memory, lessons, and preferences can be kept:
- Copy `memory/` files from your old workspace to Heisenberg's workspace
- Update MEMORY.md to remove placeholders
- Your SQLite memory database stays in `~/.openclaw/memory/` — it's shared

## What Changes for You?

| Before | After |
|--------|-------|
| One bot, one agent | One main bot + specialist bots |
| You manage everything | Heisenberg delegates automatically |
| Direct tool calls | Agents coordinate via Board |
| No backup if agent fails | Self-heal + heartbeat monitoring |

## FAQ

### Can I keep my agent's personality?
Yes. Edit `SOUL.md` and `IDENTITY.md` in your workspace. The Breaking Bad characters are the default product flavor, but visible names can be customized in generated configs if you want.

### Do I need all 8 agents?
No. Start with Heisenberg + 1-2 specialists. Add more when you need them.

### What if I use Claude Max, not API?
The setup wizard handles this. Select "Anthropic" and enter "max" when asked for the API key.

### Can agents run on different machines?
Yes — agents communicate via `sessions_send` which works across OpenClaw instances. See [deploy-agents.md](deploy-agents.md).

### How much does it cost?
- Claude Max: $100-200/month (covers everything)
- API: varies by usage (~$20-50/month typical for light use)
- Embeddings: ~$0.02/month (negligible)
- Hosting: free if local, $5-20/month for VPS
