# Contributing to Heisenberg Team

Thanks for your interest in contributing! Here's how to get started.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Include steps to reproduce, expected vs actual behavior
- Mention which agent or skill is affected

### Adding a New Agent

See [examples/add-new-agent.md](examples/add-new-agent.md) for a step-by-step guide.

Each agent needs 7 files:
- `AGENTS.md` — Role and responsibilities
- `SOUL.md` — Personality and tone
- `IDENTITY.md` — Name and boundaries
- `TOOLS.md` — Available tools
- `MEMORY.md` — Persistent knowledge
- `BOOTSTRAP.md` — Recovery instructions
- `HEARTBEAT.md` — Scheduled tasks

### Adding a New Skill

See [examples/create-skill.md](examples/create-skill.md).

Each skill needs at minimum a `SKILL.md` file with YAML frontmatter.

### Code Style

- **Directories:** lowercase with hyphens (`my-new-skill`)
- **Config files:** UPPERCASE with extension (`SKILL.md`, `AGENTS.md`)
- **Scripts:** lowercase with hyphens (`my-script.sh`)
- **Language:** English for code and docs, Russian is acceptable for agent personalities

### Pull Requests

1. Fork the repo
2. Create a branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run `scripts/depersonalize.sh` if you added any personal data
5. Test your changes with OpenClaw
6. Commit and push
7. Open a Pull Request with a clear description

### Before Submitting

- [ ] No personal data (API keys, tokens, real names, emails)
- [ ] Files follow the naming conventions
- [ ] Agent configs have all 7 required files
- [ ] Skills have `SKILL.md` with proper frontmatter
- [ ] Scripts are executable (`chmod +x`)

## Still Stuck?

Open an issue or check [docs/troubleshooting.md](docs/troubleshooting.md) for a detailed guide.
