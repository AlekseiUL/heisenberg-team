# Changelog

All notable changes to Heisenberg Team will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-04-05

### Security
- Removed hardcoded auth token from `.mcp.json` — replaced with `${PERPLEXITY_MCP_TOKEN}` env var
- Externalized PII patterns from CI pipeline into `.pii-patterns` (gitignored)

### Fixed
- Bash syntax error in `start-team.sh` — replaced invalid `& then` construct with background process + PID check
- Unreplaced `{{YOUR_BRAND}}` placeholder in `self-heal.sh` and `agents/hank/MEMORY.md`
- Model discrepancy for Saul — `saul.openclaw.json.example` now uses `{{COORDINATOR_MODEL}}` instead of `{{AGENT_MODEL}}`

### Added
- Three-tier model strategy (Opus/Sonnet/Haiku + Gemini Flash for crons) across all agent configs and `.env.example`
- Centralized dependency management (`requirements.txt`, `package.json`)
- Expanded agent communication matrix — 3 new bidirectional links: Jesse↔Skyler, Hank↔Twins, Gus↔Twins
- Modularized team constitution into `references/constitution/` (8 modules + README index)
- Centralized thresholds configuration in `configs/thresholds.yaml`
- `.mcp.json.example` with env var placeholder for MCP auth

## [1.0.0] - 2026-XX-XX

### Added
- Initial release: 8 agents, 34 skills, Board-First protocol
- Single gateway architecture
- Self-healing and three-gate cron protection
- Telegram-first interface
