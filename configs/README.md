# Agent Config Examples

This directory contains **example OpenClaw configuration files** for each agent on the Heisenberg Team.

## How to Use

1. Copy the example for your agent:
   ```bash
   cp configs/heisenberg.openclaw.json.example ~/.openclaw/agents/heisenberg/openclaw.json
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
   grep -n '{{' ~/.openclaw/agents/heisenberg/openclaw.json
   ```
   Should return nothing.

## Files

| File | Agent | Model |
|------|-------|-------|
| `heisenberg.openclaw.json.example` | Heisenberg (Boss) | claude-opus-4-5 |
| `saul.openclaw.json.example` | Saul Goodman (Producer) | claude-sonnet-4-5 |
| `walter.openclaw.json.example` | Walter White (Tech Lead) | claude-sonnet-4-5 |
| `jesse.openclaw.json.example` | Jesse Pinkman (Marketing) | claude-sonnet-4-5 |
| `skyler.openclaw.json.example` | Skyler White (Finance) | claude-sonnet-4-5 |
| `hank.openclaw.json.example` | Hank Schrader (Security) | claude-sonnet-4-5 |
| `gus.openclaw.json.example` | Gus Fring (Kaizen) | claude-sonnet-4-5 |
| `twins.openclaw.json.example` | The Cousins (Research) | claude-sonnet-4-5 |

## Design Notes

- **Heisenberg uses Opus** — he's the user-facing boss, quality matters
- **All others use Sonnet** — sub-agents don't need Opus; saves cost significantly
- **remoteAgents** — each agent knows about all *other* agents (not itself)
- **Memory** — all agents use local SQLite with OpenAI embeddings for vector search
- **Heartbeat** — enabled for all agents, 30 min interval

## Security

⚠️ **Never commit real configs to git.**

The `.example` files in this directory use `{{PLACEHOLDERS}}` and are safe to commit.
Real configs with tokens/keys go in `~/.openclaw/agents/<agent>/openclaw.json` — outside this repo.

The `.gitignore` in the repo root should already exclude `*.json` in `configs/` except `*.example` files.
