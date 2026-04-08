# Agent Config Examples

This directory contains **committable example OpenClaw configuration files** for each agent on the Heisenberg Team.

## Directory Layout

- `configs/*.openclaw.json.example` - tracked example templates, safe to commit
- `configs/generated/` - local generated configs, ignored by git, never commit secrets from here

## How to Use

1. Copy the example for your agent, or generate a local config into `configs/generated/` first:
   ```bash
   mkdir -p configs/generated
   cp configs/heisenberg.openclaw.json.example configs/generated/heisenberg.openclaw.json
   ```

2. Then copy the real config to your OpenClaw agent directory:
   ```bash
   mkdir -p ~/.openclaw/agents/heisenberg
   cp configs/generated/heisenberg.openclaw.json ~/.openclaw/agents/heisenberg/openclaw.json
   ```

2. Replace all `{{PLACEHOLDERS}}` with real values:

   | Placeholder | What to put there |
   |-------------|------------------|
   | `{{DISPLAY_NAME_HEISENBERG}}` etc. | Visible display name for each built-in agent |
   | `{{TELEGRAM_BOT_TOKEN_HEISENBERG}}` etc. | Bot token for that specific agent |
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

The setup wizard fills per-agent display names and Telegram bot tokens into the generated copies automatically.

## Design Notes

- **Heisenberg uses Opus** — he's the user-facing boss, quality matters
- **All others use Sonnet** — sub-agents don't need Opus; saves cost significantly
- **remoteAgents** — each agent knows about all *other* agents (not itself)
- **Memory** — all agents use local SQLite with OpenAI embeddings for vector search
- **Heartbeat** — enabled for all agents, 30 min interval

## Security

⚠️ **Never commit real configs to git.**

The `.example` files in this directory use `{{PLACEHOLDERS}}` and are safe to commit.
Real configs with tokens or keys should live either in:

- `configs/generated/` while you are preparing them locally
- `~/.openclaw/agents/<agent>/openclaw.json` for actual runtime use

`configs/generated/` is ignored by the repo root `.gitignore` on purpose.
