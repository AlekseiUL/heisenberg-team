# Architecture

## Overview

Heisenberg Team is a multi-agent system built on OpenClaw. It uses a hierarchical delegation model where specialized agents handle different types of tasks.

## Communication Model

```
┌─────────────────────────────────────────────────┐
│                    User                          │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│            Heisenberg (Main Agent)               │
│  - Receives all user requests                    │
│  - Routes to appropriate agent                   │
│  - Delivers final results                        │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│             Saul (Coordinator)                   │
│  - Breaks complex tasks into subtasks            │
│  - Creates briefings for agents                  │
│  - Monitors progress via team board              │
│  - Reports completion to Heisenberg              │
└───┬──────┬──────┬──────┬──────┬──────┬─────────┘
    │      │      │      │      │      │
    ▼      ▼      ▼      ▼      ▼      ▼
 Walter  Jesse  Skyler  Hank   Gus   Twins
```

## Agent Communication

Agents communicate via `sessions_send`:

```
sessions_send(
  sessionKey="agent:<name>:main",
  message="Task description",
  timeoutSeconds=120
)
```

### Communication Matrix

```
              Heisenberg  Saul  Walter  Jesse  Skyler  Hank  Gus  Twins
Heisenberg        —        →      →      —      —      —     —     —
Saul              ←        —      →      →      →      →     →     →
Walter            ←        ←      —      —      —      —     —     —
Jesse             ←        ←      —      —      —      —     —     ↔
Skyler            ←        ←      —      —      —      —     ↔     —
Hank              ←        ←      —      —      —      —     —     —
Gus               ←        ←      —      —      ↔      —     —     —
Twins             ←        ←      —      ↔      —      —     —     —

→ = calls  ← = reports to  ↔ = bidirectional (request-response)
```

**Key patterns:**
- All specialists report results to **Saul** (coordinator) and escalations to **Heisenberg** (boss)
- **Jesse ↔ Twins**: Jesse requests competitive research from Twins
- **Skyler ↔ Gus**: Gus requests financial data, Skyler responds
- `sessions_send` is a wake-up signal only. Task details go to the **board** and **briefings**

## Board-First Protocol

1. Saul creates a briefing in `projects/<name>/briefing.md`
2. Updates `references/team-board.md` with assignment
3. Agent reads briefing, executes, updates board status
4. Saul verifies and reports to Heisenberg

## Skill System

Skills are instruction sets in `skills/<name>/SKILL.md`. Agents load relevant skills based on task matching:

1. Agent scans skill descriptions
2. Matches task to most relevant skill
3. Reads SKILL.md for instructions
4. Follows the instructions step by step

## Memory System

Each agent has:
- `MEMORY.md` - core facts and context
- `memory/` directory - detailed logs, lessons, handoff states

Memory persists across sessions and compactions.

## File Structure per Agent

```
agents/<name>/
├── AGENTS.md      # Role and responsibilities
├── SOUL.md        # Personality and tone
├── IDENTITY.md    # Self-awareness and boundaries
├── TOOLS.md       # Available tools and usage
├── MEMORY.md      # Persistent knowledge
├── BOOTSTRAP.md   # Recovery after restart
└── HEARTBEAT.md   # Periodic tasks
```

## Security Model

- Personal data is never committed to git
- All files pass security grep before publishing
- Auth files (.json) are excluded via .gitignore
- The `depersonalize.sh` script replaces all PII with placeholders
