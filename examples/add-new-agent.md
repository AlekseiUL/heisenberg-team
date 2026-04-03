# How to Add a New Agent

## 1. Create Agent Directory

```bash
mkdir -p agents/your-agent-name/
```

## 2. Create Config Files

Every agent needs these files:

| File | Purpose |
|------|---------|
| `AGENTS.md` | Role, responsibilities, team connections |
| `SOUL.md` | Personality, tone, character traits |
| `IDENTITY.md` | Name, boundaries, self-awareness |
| `TOOLS.md` | Available tools and how to use them |
| `MEMORY.md` | Persistent knowledge and context |
| `BOOTSTRAP.md` | Recovery instructions after restart |
| `HEARTBEAT.md` | Periodic tasks (empty = no heartbeat) |

## 3. Define the Role (AGENTS.md)

```markdown
# AGENTS.md - Your Agent Name

## Role
[What this agent does]

## Responsibilities
- [Task 1]
- [Task 2]

## Communication
| Agent | How to reach |
|-------|-------------|
| Saul | sessions_send(sessionKey="agent:producer:main", ...) |

## Rules
- [Rule 1]
- [Rule 2]
```

## 4. Set the Personality (SOUL.md)

Give your agent a distinct voice. This affects how it communicates:

```markdown
# SOUL.md - Your Agent

## Character
- [Trait 1]
- [Trait 2]

## Style
- [Communication style]
```

## 5. Register in OpenClaw

```bash
# Copy to OpenClaw agents directory
cp -r agents/your-agent-name ~/.openclaw/agents/your-agent-name/agent/

# Restart gateway
openclaw gateway restart
```

## 6. Update Team Constitution

Add the new agent to `references/team-constitution.md` so other agents know about it.

## 7. Test

Send a message that should be routed to your new agent and verify it responds correctly.
