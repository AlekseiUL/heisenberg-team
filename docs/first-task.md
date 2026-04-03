# Your First Task

This guide walks you through sending your first task to the Heisenberg Team after setup.

## Prerequisites

- Setup wizard completed (`bash scripts/setup-wizard.sh`)
- OpenClaw gateway running (`openclaw gateway start`)
- Telegram bot configured (or other messaging channel)

## How It Works

```
You send a message
       │
       ▼
  Heisenberg (Main Agent)
  Receives your request, decides complexity
       │
       ├── Simple task → Heisenberg handles it directly
       │
       └── Complex task → Delegates to Saul (Coordinator)
                │
                ▼
           Saul creates:
           1. Briefing in projects/<name>/briefing.md
           2. Task on team-board.md
           3. Sends alert to the right agent
                │
                ▼
           Specialist agent executes
           (Walter for code, Jesse for marketing, etc.)
                │
                ▼
           Result delivered back to you
```

## Step-by-Step Example

### 1. Send a Message to Your Bot

Open Telegram and write to your bot:

```
Create a PDF about the benefits of AI agents for small businesses
```

### 2. What Happens Inside

**Heisenberg** receives your message and recognizes this needs production work.

He sends the task to **Saul** (Coordinator):
```
sessions_send(
  sessionKey="agent:producer:main",
  message="User wants a PDF about AI agents for small businesses",
  timeoutSeconds=120
)
```

**Saul** creates a briefing:
```markdown
# Briefing: AI Agents PDF

## Task
Create a professional PDF about the benefits of AI agents for small businesses.

## Assigned to: Walter (teamlead)
## Skills to use: minimax-pdf
## Deadline: ASAP
## Quality: Production-ready
```

**Saul** updates `team-board.md`:
```
- ⏳ [2026-04-02] [producer → teamlead] PDF: AI agents for small businesses
```

**Walter** (Team Lead) picks up the task, uses the `minimax-pdf` skill, and creates the PDF.

**Walter** notifies Saul, who notifies Heisenberg, who sends you the result.

### 3. You Get the Result

In Telegram, you'll receive:
- A confirmation when the task is accepted
- The completed PDF file
- A summary of what was done

## Quick Tasks to Try

| Task | Who Handles It | What You Get |
|------|---------------|--------------|
| "Create a PDF about X" | Walter (teamlead) | Professional PDF |
| "Write a Telegram post about Y" | Jesse (marketing) | Ready-to-publish post |
| "Research competitor Z" | Twins (researcher) | Research report |
| "Create a financial report" | Skyler (admin) | XLSX/PDF report |
| "Check system security" | Hank (security) | Security audit report |

## Tips

1. **Be specific** — "Create a 10-page PDF with charts" works better than "make something about AI"
2. **One task at a time** — Wait for completion before sending the next
3. **Check the board** — `references/team-board.md` shows all task statuses
4. **Direct routing** — Mention the agent if you know who should handle it: "Walter, create a skill for..."

## Troubleshooting

| Problem | Check |
|---------|-------|
| No response from bot | Is the gateway running? `openclaw status` |
| Task accepted but no result | Check `references/team-board.md` for status |
| Agent says "I don't have this skill" | Verify skills are installed: `ls ~/.openclaw/agents/producer/agent/skills/` |
| Telegram notifications not working | Check `OWNER_TELEGRAM_ID` is set correctly |

## What's Next?

- [Add a new agent](../examples/add-new-agent.md) to extend the team
- [Create a custom skill](../examples/create-skill.md) for your specific needs
- [Set up cron jobs](../examples/configure-crons.md) for automated tasks
