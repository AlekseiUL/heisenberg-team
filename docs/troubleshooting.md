# Troubleshooting Guide

This guide covers common problems and their solutions. For quick setup issues, also see [SETUP.md](../SETUP.md#troubleshooting) and [FAQ](faq.md).

## Table of Contents

- [Installation & Setup](#installation--setup)
- [Agent Not Responding](#agent-not-responding)
- [Gateway Issues](#gateway-issues)
- [Telegram & Notifications](#telegram--notifications)
- [Memory & Skills](#memory--skills)
- [Placeholders & Configuration](#placeholders--configuration)
- [Log Files & Diagnostics](#log-files--diagnostics)
- [Performance Issues](#performance-issues)
- [Task Recovery](#task-recovery)
- [Common Error Messages](#common-error-messages)

---

## Installation & Setup

### Setup wizard fails immediately

**Symptoms:** `bash scripts/setup-wizard.sh` exits with an error right away.

**Check Node.js version:**
```bash
node --version
# Must be v18 or higher (v20+ recommended)
```

**Check OpenClaw installation:**
```bash
openclaw --version
# If not found: npm install -g openclaw
```

**Check script permissions:**
```bash
chmod +x scripts/setup-wizard.sh
bash scripts/setup-wizard.sh
```

---

### `openclaw: command not found`

```bash
npm install -g openclaw
# If npm itself is missing, install Node.js first:
# https://nodejs.org/
```

---

### Python dependencies missing (skills not working)

Some skills require Python packages:

```bash
pip install -r requirements.txt
# or: pip3 install -r requirements.txt
```

---

### Node.js dependencies missing

```bash
npm install
```

---

### `.NET SDK missing` (minimax-docx skill)

The DOCX generation skill requires .NET:

```bash
# macOS:
brew install --cask dotnet-sdk

# Ubuntu/Debian:
sudo apt-get install -y dotnet-sdk-8.0
```

---

## Agent Not Responding

### Agent times out or gives no reply

The most common cause is a **heavy (overloaded) session**. Always reset before starting a new task:

```bash
bash scripts/trash-agent-session.sh <agent-name>
sleep 5
```

Then retry the task.

**Agent names:** `main`, `producer`, `teamlead`, `marketing-funnel`, `skyler`, `hank`, `kaizen`, `researcher`

---

### Agent responds but ignores the task

The agent likely has stale context from a previous session. Reset:

```bash
bash scripts/trash-agent-session.sh <agent-name>
sleep 5
```

---

### `sessions_send` returns timeout

1. Reset the target agent session (see above)
2. Check gateway is running: `openclaw status`
3. Increase `timeoutSeconds` to `300` for long-running tasks
4. Check agent config exists: `ls ~/.openclaw/agents/<name>/agent/`

---

### Agent startup errors

```bash
# View agent logs
openclaw logs <agent-name>

# Restart a specific agent
openclaw agent restart <agent-name>

# Restart all agents
openclaw gateway restart
```

---

## Gateway Issues

### Gateway fails to start

```bash
openclaw gateway start

# If it fails, check for existing processes:
openclaw status

# Force restart:
openclaw gateway stop
openclaw gateway start
```

**macOS: port conflict:**
```bash
lsof -i :3000  # replace with the port OpenClaw uses
kill <PID>
openclaw gateway start
```

---

### Gateway starts but agents are inactive

```bash
openclaw status
```

If some agents show as `inactive`:

```bash
# Reinstall agent configs
bash scripts/setup.sh

# Or manually for one agent:
cp configs/walter.openclaw.json.example ~/.openclaw/agents/teamlead/openclaw.json
# Replace placeholders, then:
openclaw agent reload teamlead
```

---

### Gateway crashes after a few minutes

Check `openclaw-watchdog.sh` is running:

```bash
bash scripts/openclaw-watchdog.sh &
```

Or add it to your system's cron:
```cron
*/5 * * * * bash /path/to/heisenberg-team/scripts/openclaw-watchdog.sh
```

---

## Telegram & Notifications

### Bot doesn't respond to messages

1. **Send `/start` to your bot first** — bots can't initiate conversations until you do
2. **Verify `TELEGRAM_BOT_TOKEN`** — check it's correct in your `.env`
3. **Verify `OWNER_TELEGRAM_ID`** — must be a numeric user ID, not a username

Get your Telegram ID:
```
Send /start to @userinfobot
```

**Test the bot token:**
```bash
curl "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
# Should return bot info JSON
```

---

### Notifications arrive but are delayed

Heartbeat interval default is 30 minutes (`configs/thresholds.yaml`). For real-time notifications:
- The DONE.md hook sends notifications in ~10 seconds (requires `fswatch` + webhook setup)
- For direct responses, Heisenberg replies immediately via `sessions_send`

---

### `{{OWNER_TELEGRAM_ID}}` appears in messages

The placeholder was not replaced. Run the setup wizard:
```bash
bash scripts/setup-wizard.sh
```

Or replace manually:
```bash
# macOS:
find agents/ -name "*.md" -exec sed -i '' 's/{{OWNER_TELEGRAM_ID}}/YOUR_ID/g' {} \;
# Linux:
find agents/ -name "*.md" -exec sed -i 's/{{OWNER_TELEGRAM_ID}}/YOUR_ID/g' {} \;
```

---

## Memory & Skills

### Skills don't load

**Check skills are in the right place:**
```bash
ls ~/.openclaw/agents/producer/agent/skills/
```

If the directory is empty, re-run setup:
```bash
bash scripts/setup.sh
```

**Check a skill file exists:**
```bash
ls skills/copywriter/SKILL.md
```

---

### Memory search returns irrelevant results

Vector search may not be configured. Check:

```bash
grep OPENAI_API_KEY .env
```

If `OPENAI_API_KEY` is missing or empty, memory search falls back to keyword (BM25) mode. Add the key and restart the gateway.

---

### Memory database corruption

```bash
# Stop gateway first
openclaw gateway stop

# Run memory hygiene
bash scripts/memory-hygiene.sh

# Restart
openclaw gateway start
```

---

### Agent "forgot" important context

1. Check `agents/<name>/MEMORY.md` — add the fact there permanently
2. Check `agents/<name>/memory/handoff.md` — used for session recovery
3. After context compaction, agents read `BOOTSTRAP.md` to recover — review that file

---

## Placeholders & Configuration

### `{{PLACEHOLDER}}` appears in agent messages or outputs

Find all remaining placeholders:
```bash
grep -rn '{{[A-Z_]*}}' agents/ references/ --include='*.md'
```

Run the setup wizard to replace them:
```bash
bash scripts/setup-wizard.sh
```

Or replace manually (macOS):
```bash
find . -type f -name "*.md" -exec sed -i '' 's/{{OWNER_NAME}}/YourName/g' {} \;
```

---

### Config file missing required fields

Check agent config:
```bash
cat ~/.openclaw/agents/<name>/openclaw.json | python3 -m json.tool
```

Compare with the example:
```bash
diff configs/<name>.openclaw.json.example ~/.openclaw/agents/<name>/openclaw.json
```

---

## Log Files & Diagnostics

### Where are the logs?

| Log type | Location |
|----------|----------|
| Gateway logs | `openclaw logs` (stdout) |
| Agent logs | `openclaw logs <agent-name>` |
| Script output | `scripts/*.log` (if configured) |
| Session digests | `agents/<name>/memory/YYYY-MM-DD.md` |
| Team board | `references/team-board.md` |

### View live logs

```bash
# All agents
openclaw logs --follow

# Specific agent
openclaw logs teamlead --follow
```

### Run health check

```bash
bash scripts/agent-health-check.sh
```

This checks all 8 agents and reports status.

---

## Performance Issues

### Tasks are slow

**Check context size** — heavy sessions slow down agents. Reset before big tasks:
```bash
bash scripts/trash-agent-session.sh <agent-name>
```

**Check model tier** — using Opus for all agents is expensive and slow. Worker agents (Jesse, Skyler, Hank, Gus, Twins) should use Haiku or Flash:
```env
WORKER_MODEL=anthropic/claude-haiku-4-5
CRON_MODEL=google/gemini-2.5-flash
```

**Check parallel agent limit** — default max is 2 parallel agents (`configs/thresholds.yaml`). Increasing this can help throughput but raises costs.

---

### High API costs

1. Set `WORKER_MODEL` to a cheaper model (Haiku, Flash, DeepSeek)
2. Set `CRON_MODEL` to a background-optimized model (Gemini Flash)
3. Enable `OPENAI_API_KEY` for embeddings (not LLM calls) — keyword fallback uses more tokens
4. Review agent heartbeat intervals — more frequent checks = more API calls

---

### Gateway uses too much memory

```bash
# Clean logs and temporary files
bash scripts/night-cleanup.sh

# Rotate logs
bash scripts/rotate-logs.sh

# Run memory hygiene
bash scripts/memory-hygiene.sh
```

---

## Task Recovery

### Task was in progress when gateway crashed

The Board-First protocol ensures no work is lost. On restart:

1. Check the team board:
   ```bash
   cat references/team-board.md
   ```

2. Find tickets with status `ВЗЯЛ` — these were in progress. Re-assign them.

3. Check `projects/<task-name>/briefing.md` — the full task spec is there.

4. Reset the relevant agent session and re-send:
   ```bash
   bash scripts/trash-agent-session.sh <agent>
   sleep 5
   ```

---

### Team board is lost or corrupted

```bash
# Restore from git
git checkout HEAD -- references/team-board.md

# If git doesn't have it, query agents for status:
openclaw status
```

Then manually reconstruct the board based on agent responses.

---

### An agent is stuck and won't complete

1. Wait 7 minutes (protocol default)
2. Escalate to Heisenberg via Telegram
3. Reset the stuck agent:
   ```bash
   bash scripts/trash-agent-session.sh <agent-name>
   ```
4. Re-add the task to the board and brief the agent again

---

## Common Error Messages

### `Error: agent not found: <name>`

The agent config is missing. Check:
```bash
ls ~/.openclaw/agents/
```

Run setup:
```bash
bash scripts/setup.sh
```

---

### `Error: API key invalid`

Double-check your API key in `.env`. The format varies by provider:

| Provider | Key format |
|----------|------------|
| Anthropic | `sk-ant-api03-...` |
| OpenAI | `sk-proj-...` or `sk-...` |
| Google | `AIza...` |

---

### `Error: timeout after 120s`

The agent session is too heavy. Reset and retry:
```bash
bash scripts/trash-agent-session.sh <agent-name>
sleep 5
# retry the task
```

If timeouts persist, increase `timeoutSeconds` in your `sessions_send` call to `300`.

---

### `Error: skill not found`

The skill file is missing or not installed. Check:
```bash
ls skills/<skill-name>/SKILL.md
ls ~/.openclaw/agents/<agent>/agent/skills/
```

Re-run setup:
```bash
bash scripts/setup.sh
```

---

### `Error: model not available`

The model name in your config is incorrect or the provider doesn't support it.

Check available models in `SETUP.md` or run:
```bash
openclaw models list
```

---

## Still Stuck?

1. Check [FAQ](faq.md) for common questions
2. Run the health check: `bash scripts/agent-health-check.sh`
3. Check [GitHub Issues](https://github.com/YaroTanko/heisenberg-team/issues) for known problems
4. Open a new issue with:
   - What you tried
   - The full error message
   - Output of `openclaw status`
   - Node.js version (`node --version`)
   - OS and version
