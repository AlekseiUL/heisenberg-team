# Environment Variables Reference

Complete reference for all environment variables used in Heisenberg Team.
Copy `.env.example` to `.env` and fill in the values before running `scripts/setup-wizard.sh`.

## Quick Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | ✅ (if using Anthropic) | Claude API key |
| `GOOGLE_API_KEY` | ✅ (if using Google) | Gemini API key |
| `OPENAI_API_KEY` | ⚡ Recommended | OpenAI key for vector memory embeddings |
| `MAIN_MODEL` | ✅ | Model for Heisenberg (boss agent) |
| `COORDINATOR_MODEL` | ✅ | Model for Saul (coordinator) |
| `OWNER_NAME` | ✅ | Your first name (used in agent greetings) |
| `OWNER_USERNAME` | ✅ | Your GitHub username |
| `OWNER_TELEGRAM_ID` | ⚡ Recommended | Your Telegram numeric user ID |
| `TELEGRAM_BOT_TOKEN` | ⚡ Recommended | Token from @BotFather |

---

## API Keys

### `ANTHROPIC_API_KEY`

**Required if:** using Anthropic Claude models (recommended).

```env
ANTHROPIC_API_KEY=sk-ant-api03-...
```

Get your key at [console.anthropic.com](https://console.anthropic.com). Starts with `sk-ant-`.

Claude Max subscribers can enter `max` — no separate API key is needed.

---

### `GOOGLE_API_KEY`

**Required if:** using Google Gemini models.

```env
GOOGLE_API_KEY=AIza...
```

Get your key at [aistudio.google.com](https://aistudio.google.com).

---

### `OPENAI_API_KEY`

**Required for:** vector memory search (semantic similarity). Strongly recommended.

```env
OPENAI_API_KEY=sk-...
```

Without this, memory search falls back to BM25 keyword matching (less accurate). The embeddings cost is negligible (check [OpenAI pricing](https://openai.com/api/pricing/) for current rates).

Also required if using OpenAI GPT models as your LLM provider.

---

## LLM Models

Models are configured in four tiers. You can mix providers across tiers.

### `MAIN_MODEL`

The model used for Heisenberg (boss agent) — the primary user-facing agent.

```env
MAIN_MODEL=anthropic/claude-sonnet-4-5-20250929
```

| Provider | Recommended model |
|----------|------------------|
| Anthropic | `anthropic/claude-opus-4-5` or `anthropic/claude-sonnet-4-5-20250929` |
| OpenAI | `openai/gpt-4o` |
| Google | `google/gemini-2.5-pro` |
| DeepSeek | `deepseek/deepseek-chat` |
| Ollama | `ollama/llama3` |

---

### `COORDINATOR_MODEL`

Model for Saul (coordinator). Handles complex pipeline orchestration.

```env
COORDINATOR_MODEL=anthropic/claude-sonnet-4-5-20250929
```

Recommended to use a capable model (Sonnet-class or above).

---

### `TECH_MODEL`

*(Optional)* Model for Walter (tech lead). Handles code, PDF generation, skill creation.

```env
# TECH_MODEL=anthropic/claude-sonnet-4-6
```

Defaults to `COORDINATOR_MODEL` if not set.

---

### `WORKER_MODEL`

*(Optional)* Model for worker agents: Jesse, Skyler, Hank, Gus, Twins.

```env
# WORKER_MODEL=anthropic/claude-haiku-4-5  # Cloud option
# WORKER_MODEL=ollama/gemma4:26b            # Local Ollama option (recommended for self-hosted setups)
```

Using a smaller/cheaper model for workers significantly reduces costs. Defaults to `COORDINATOR_MODEL` if not set.

For local inference via Ollama, **`ollama/gemma4:26b`** (Gemma 4 26B-A4B) is the recommended worker model:
- ~17 GB RAM, ~56–92 tok/s on Apple Silicon M2 Max
- 256K context window
- Native function calling / agentic tool use (τ2-bench: 85.5%)
- Apache 2.0 license

Install with: `ollama pull gemma4:26b`

---

### `CRON_MODEL`

*(Optional)* Model for background cron jobs (health checks, cleanup, monitoring).

```env
# CRON_MODEL=google/gemini-2.5-flash
```

Gemini Flash is a cost-efficient option for background tasks. Defaults to `WORKER_MODEL` if not set.

---

## Per-Agent Model Overrides

Each agent can use its own model and API key. These override the tier-level settings above.

### Heisenberg

```env
HEISENBERG_PROVIDER=anthropic
HEISENBERG_MODEL=claude-sonnet-4-5-20250929
HEISENBERG_MAX_TOKENS=4096
HEISENBERG_API_KEY=${ANTHROPIC_API_KEY}
```

### Saul

```env
SAUL_PROVIDER=anthropic
SAUL_MODEL=claude-sonnet-4-5-20250929
SAUL_MAX_TOKENS=4096
```

Other agents follow the same pattern: `<AGENT>_PROVIDER`, `<AGENT>_MODEL`, `<AGENT>_MAX_TOKENS`.

---

## Embeddings

```env
# EMBEDDING_PROVIDER=openai
# EMBEDDING_MODEL=text-embedding-3-small
```

| Variable | Values | Default |
|----------|--------|---------|
| `EMBEDDING_PROVIDER` | `openai`, `anthropic`, `google` | `openai` |
| `EMBEDDING_MODEL` | `text-embedding-3-small`, `text-embedding-3-large`, etc. | `text-embedding-3-small` |

`text-embedding-3-small` provides a good balance of quality and cost. Use `text-embedding-3-large` for higher accuracy at higher cost.

---

## Telegram

```env
# TELEGRAM_BOT_TOKEN=7123456789:AAHxxx...
# OWNER_TELEGRAM_ID=123456789
```

### `TELEGRAM_BOT_TOKEN`

Token for your Telegram bot. Create one via [@BotFather](https://t.me/BotFather).

Format: `<bot_id>:<token_string>` — for example `7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`.

### `OWNER_TELEGRAM_ID`

Your personal Telegram user ID (numeric, not your username).

Get it from [@userinfobot](https://t.me/userinfobot) — send `/start` and it will return your ID.

Format: a positive integer, e.g. `123456789`.

### `GROUP_CHAT_ID` *(Optional)*

Telegram group chat ID for team notifications.

```env
# GROUP_CHAT_ID=-100123456789
```

Group IDs are negative numbers starting with `-100`.

### `NOTIFY_CHANNEL_ID` *(Optional)*

Telegram channel ID for delivery notifications.

```env
# NOTIFY_CHANNEL_ID=-100987654321
```

---

## Personal Data

These are used as placeholders across agent config files. The setup wizard fills them in automatically.

### `OWNER_NAME`

Your first name. Used in agent greetings and notification messages.

```env
OWNER_NAME=Alex
```

### `OWNER_SURNAME`

Your last name. Used in formal documents generated by Skyler.

```env
OWNER_SURNAME=Smith
```

### `OWNER_USERNAME`

Your GitHub username. Used by Walter (tech lead) for repository operations and by github-publisher skill.

```env
OWNER_USERNAME=alexsmith
```

---

## File Paths

### `WORKSPACE_PATH`

Base path where agents store projects and outputs.

```env
# WORKSPACE_PATH=~/workspace/
```

Default: `~/workspace/` (created by `scripts/init-workspace.sh`).

All project files are stored under `$WORKSPACE_PATH/projects/<project-name>/`.

### `PROJECTS_PATH`

Path for project files (overrides the `projects/` subdirectory of `WORKSPACE_PATH`).

```env
# PROJECTS_PATH=~/projects/
```

---

## GitHub Integration *(Optional)*

```env
# GITHUB_ORG=your-github-org
# GITHUB_TOKEN=ghp_...
```

### `GITHUB_ORG`

Your GitHub organization name. Used by Walter and github-publisher skill.

### `GITHUB_TOKEN`

Personal access token for GitHub API. Required for github-publisher skill.

Scopes needed: `repo`, `read:org`.

Create at: [github.com/settings/tokens](https://github.com/settings/tokens)

---

## MCP Tools *(Optional)*

```env
# PERPLEXITY_MCP_TOKEN=pplx-...
```

### `PERPLEXITY_MCP_TOKEN`

API token for Perplexity MCP integration. Used by Twins (researcher) for web search.

---

## Webhooks *(Optional)*

```env
# WEBHOOK_TOKEN=your_webhook_token_here
```

### `WEBHOOK_TOKEN`

Token for verifying incoming webhook requests. Used by the DONE.md auto-notification hook (see `docs/api-reference.md`).

---

## Validation Rules

| Variable | Format | Example |
|----------|--------|---------|
| `ANTHROPIC_API_KEY` | `sk-ant-...` | `sk-ant-api03-abc123...` |
| `OPENAI_API_KEY` | `sk-...` | `sk-proj-abc123...` |
| `GOOGLE_API_KEY` | `AIza...` | `AIzaSyAbc123...` |
| `OWNER_TELEGRAM_ID` | Positive integer | `123456789` |
| `TELEGRAM_BOT_TOKEN` | `<digits>:<string>` | `7123456789:AAHxxx...` |
| `GITHUB_TOKEN` | `ghp_...` | `ghp_abc123...` |
| `GROUP_CHAT_ID` | Negative integer | `-100123456789` |

---

## Required vs. Optional Summary

### ✅ Required (system won't work without these)

At least one LLM API key must be set:
- `ANTHROPIC_API_KEY` **or** `OPENAI_API_KEY` **or** `GOOGLE_API_KEY`
- `MAIN_MODEL`
- `COORDINATOR_MODEL`
- `OWNER_NAME`
- `OWNER_USERNAME`

### ⚡ Strongly Recommended

- `OPENAI_API_KEY` — enables vector memory search (semantic similarity)
- `TELEGRAM_BOT_TOKEN` + `OWNER_TELEGRAM_ID` — enables notifications and user interaction
- `WORKSPACE_PATH` — sets where project files are stored

### ❌ Optional

Everything in the `TECH_MODEL`, `WORKER_MODEL`, `CRON_MODEL` group.
All GitHub, MCP, webhook, and per-agent override variables.

---

## Checking for Missing Values

After setup, verify no placeholders remain:

```bash
grep -rn '{{[A-Z_]*}}' agents/ --include='*.md'
grep -rn '{{[A-Z_]*}}' references/ --include='*.md'
```

The output should be empty. If not, run `bash scripts/setup-wizard.sh` or replace the values manually.

---

## Related Documentation

- [SETUP.md](../SETUP.md) — installation guide with step-by-step instructions
- [configs/README.md](../configs/README.md) — agent config file reference
- [Troubleshooting](troubleshooting.md) — common configuration issues
