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
mkdir -p ~/.openclaw/agents/your-agent-name/agent
cp -r agents/your-agent-name/* ~/.openclaw/agents/your-agent-name/agent/

# Prepare a config template for the new agent
mkdir -p configs/generated
cp configs/heisenberg.openclaw.json.example configs/generated/your-agent-name.openclaw.json
# Edit agent name, bot token, workspace path, and remoteAgents as needed
```

If you keep a live gateway running, restart it from your shell only after the new config is ready.

## 6. Update Team Constitution and Routing

Add the new agent to `references/team-constitution.md` so other agents know about it.
Also update any `remoteAgents` blocks in the generated configs that should be able to reach this new agent.

## 7. Test

Run a focused smoke test for the agents affected by the new addition, then send a message that should be routed to your new agent and verify it responds correctly.
