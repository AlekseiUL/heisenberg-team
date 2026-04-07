# Agent Config Examples

This directory contains **example OpenClaw configuration files** for each agent on the Heisenberg Team.

## How to Use

1. Copy the example for your agent:
   ```bash
   cp configs/heisenberg.openclaw.json.example ~/.openclaw/agents/main/openclaw.json
   ```

2. Replace all `{{PLACEHOLDERS}}` with real values:

   | Placeholder | What to put there |
   |-------------|------------------|
   | `{{TELEGRAM_BOT_TOKEN}}` | Token from @BotFather (e.g. `7123456789:AAHxxx...`) |
   | `{{OWNER_TELEGRAM_ID}}` | Your numeric Telegram ID (get it from @userinfobot) |
   | `{{ANTHROPIC_API_KEY}}` | Claude API key (`sk-ant-...`) |
   | `{{OPENAI_API_KEY}}` | OpenAI API key (`sk-...`) for vector memory embeddings |

3. Verify no placeholders remain:
   ```bash
   grep -n '{{' ~/.openclaw/agents/main/openclaw.json
   ```
   Should return nothing.

## Thresholds

All numeric thresholds (timeouts, retries, context limits) are centralized in:
- `configs/thresholds.yaml` — see this file for all magic numbers

## Files

| File | Agent | Model |
|------|-------|-------|
| `heisenberg.openclaw.json.example` | Heisenberg (Boss) | `MAIN_MODEL` |
| `saul.openclaw.json.example` | Saul Goodman (Producer) | `COORDINATOR_MODEL` |
| `walter.openclaw.json.example` | Walter White (Tech Lead) | `TECH_MODEL` |
| `jesse.openclaw.json.example` | Jesse Pinkman (Marketing) | `WORKER_MODEL` |
| `skyler.openclaw.json.example` | Skyler White (Finance) | `WORKER_MODEL` |
| `hank.openclaw.json.example` | Hank Schrader (Security) | `WORKER_MODEL` |
| `gus.openclaw.json.example` | Gus Fring (Kaizen) | `WORKER_MODEL` |
| `twins.openclaw.json.example` | The Cousins (Research) | `WORKER_MODEL` |
| `thresholds.yaml` | All agents | Centralized thresholds |

## Design Notes

- **Model values come from `.env`** — set `MAIN_MODEL` / `COORDINATOR_MODEL` / `TECH_MODEL` / `WORKER_MODEL` for your provider and budget
- **Agent IDs in `~/.openclaw/agents/` use OpenClaw IDs** (`main`, `producer`, `teamlead`, ...) while repo folders use character names (`heisenberg`, `saul`, `walter`, ...)
- **remoteAgents** — each agent knows about all *other* agents (not itself)
- **Memory** — all agents use local SQLite with OpenAI embeddings for vector search
- **Heartbeat** — enabled for all agents, 30 min interval

## Security

⚠️ **Never commit real configs to git.**

The `.example` files in this directory use `{{PLACEHOLDERS}}` and are safe to commit.
Real configs with tokens/keys go in `~/.openclaw/agents/<agent>/openclaw.json` — outside this repo.

The `.gitignore` in the repo root should already exclude `*.json` in `configs/` except `*.example` files.
