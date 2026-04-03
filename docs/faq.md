# FAQ

## Getting Started

### What LLM providers are supported?
Any provider supported by OpenClaw: Anthropic (Claude), OpenAI (GPT), Google (Gemini), local models via Ollama, and more.

### Do all agents need separate API keys?
No. All agents share the same OpenClaw configuration and API keys.

### Can I use this without Telegram?
Yes. OpenClaw supports Discord, Slack, Signal, WhatsApp, IRC, webchat, and more. Telegram is just one option. However, agent configs include Telegram notification calls — you may want to edit `AGENTS.md` files to match your messaging channel.

### How many agents can I run?
As many as your system handles. Each agent is a lightweight config — it doesn't consume resources when idle.

### Does this work on Linux/Windows?
OpenClaw runs on macOS, Linux, and Windows (via WSL). Some scripts use macOS-specific `sed -i ''` syntax — on Linux, use `sed -i` without the empty quotes.

### The agent configs are in Russian. Can I use this in English?
Yes. Edit `SOUL.md` and `AGENTS.md` in each agent directory to change the language. The architecture and system logic are language-independent. Keep the technical parts (session keys, tool calls) as-is.

## Setup

### The setup script fails
1. Check that OpenClaw is installed: `openclaw --version`
2. Check Node.js version: `node --version` (need v20+)
3. Check permissions: `ls -la ~/.openclaw/agents/`

### I see `{{PLACEHOLDER}}` in agent messages
You have unfilled placeholders. Run the setup wizard:
```bash
bash scripts/setup-wizard.sh
```
Or find them manually:
```bash
grep -rn '{{[A-Z_]*}}' agents/ --include='*.md'
```

### An agent doesn't respond
1. Check gateway: `openclaw status`
2. Check agent config: `ls ~/.openclaw/agents/<name>/agent/`
3. Restart: `openclaw gateway restart`
4. Check logs for errors

### Skills don't load
Skills must be in the agent's skills directory:
```bash
ls ~/.openclaw/agents/producer/agent/skills/
```
If empty, re-run `bash scripts/setup.sh`.

### Telegram notifications don't work
1. Verify your Telegram user ID is set (digits only, get from @userinfobot)
2. Check that your bot token is configured in OpenClaw
3. Make sure you've started a chat with your bot first

### How do I know which `{{PLACEHOLDER}}` to fill?
The setup wizard (`scripts/setup-wizard.sh`) handles the most important ones. For the full list, see `.env.example` and run:
```bash
grep -rn '{{[A-Z_]*}}' . --include='*.md' | grep -v node_modules | sort -u -t: -k3
```

## Customization

### Can I change agent names?
Yes. Edit `SOUL.md`, `IDENTITY.md`, and `AGENTS.md` in the agent's directory. The session key in `TOOLS.md` must match the OpenClaw agent name.

### Can I add agents from different shows?
Absolutely. The Breaking Bad theme is cosmetic. Agent behavior is defined by the config files, not the character names. See [examples/add-new-agent.md](../examples/add-new-agent.md).

### Can I remove agents I don't need?
Yes. Remove the agent directory and update `references/team-constitution.md` to remove references. The minimum viable team is Heisenberg (main) + one specialist.

### How do I share skills between agents?
Place skills in a shared directory and configure each agent to reference it, or copy skills to each agent's skills directory. See [skills/README.md](../skills/README.md) for the full skills index.

### What is the Board-First Protocol?
It's how agents coordinate. Instead of relying only on messages (which can timeout), the coordinator writes tasks to a file (`references/team-board.md`). Agents read this file to know their assignments. This survives crashes and session losses.

### Where do task results go?
Results are saved in `projects/<task-name>/` — briefing, intermediate files, and final output are all kept. Nothing is deleted.

## Costs

### How much does this cost to run?
Depends on your LLM usage. Idle agents cost nothing. Active usage depends on your provider's pricing and how many tasks you run. A typical task uses 1-3 API calls per agent involved.

### Can I use free/local models?
Yes. Configure Ollama or any local model provider in OpenClaw. Some skills may work better with larger models (Opus/GPT-4 for complex code, Sonnet/GPT-3.5 for simpler tasks).

## Architecture

### What happens if an agent crashes?
Each agent has a `BOOTSTRAP.md` with recovery instructions. The system uses file-based state (team board), so no work is lost. Restart the gateway and the agent picks up where it left off.

### Can agents work in parallel?
Yes. Saul (coordinator) can assign tasks to multiple agents simultaneously. Each agent runs in its own session.

### What are the 7 files in each agent directory?
| File | Purpose |
|------|---------|
| `AGENTS.md` | Role, responsibilities, delegation rules |
| `SOUL.md` | Personality, tone, communication style |
| `IDENTITY.md` | Name, boundaries, self-awareness |
| `TOOLS.md` | Available tools and API methods |
| `MEMORY.md` | Persistent knowledge and context |
| `BOOTSTRAP.md` | Recovery instructions after restart |
| `HEARTBEAT.md` | Periodic/scheduled tasks |
