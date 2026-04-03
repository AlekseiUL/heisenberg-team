# How to Configure Cron Jobs

## What are Cron Jobs?

Cron jobs are scheduled tasks that agents execute automatically. Examples: daily health checks, weekly reports, backup reminders.

## 1. Using HEARTBEAT.md

The simplest way. Add tasks to an agent's `HEARTBEAT.md`:

```markdown
# HEARTBEAT.md

- Check system health every 6 hours
- Send daily summary at 9:00 AM
```

OpenClaw will execute these tasks on the configured heartbeat interval.

## 2. Using OpenClaw Cron

For precise scheduling, use OpenClaw's built-in cron:

```bash
# List current cron jobs
openclaw cron list

# Add a new job
openclaw cron add --agent kaizen --schedule "0 9 * * *" --task "Run daily health check"

# Remove a job
openclaw cron remove --id <job-id>
```

## 3. Using System Cron + Scripts

For tasks that don't need agent intelligence:

```bash
# Edit crontab
crontab -e

# Add a script
0 3 * * * /path/to/heisenberg-team/scripts/night-cleanup.sh
```

## Available Scripts

| Script | Purpose | Suggested Schedule |
|--------|---------|-------------------|
| `agent-health-check.sh` | Check agent status | Every 6h |
| `memory-hygiene.sh` | Clean memory files | Daily at 3 AM |
| `rotate-logs.sh` | Rotate log files | Daily at 2 AM |
| `git-backup.sh` | Backup to git | Daily at 4 AM |
| `consistency-check.sh` | Verify config consistency | Weekly |

## Best Practices

- Always test scripts manually before scheduling
- Use logging (`>> /path/to/log 2>&1`)
- Set reasonable intervals (don't overload)
- Monitor failures with `cron-watchdog.sh`
