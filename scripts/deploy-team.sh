#!/bin/bash
# deploy-team.sh — Deploy the Heisenberg Team
# Creates workspace directories and copies agent files
#
# Usage:
#   bash scripts/deploy-team.sh           # Create workspaces (skip existing)
#   bash scripts/deploy-team.sh --force   # Overwrite existing workspaces
#   OPENCLAW_AGENTS_DIR=/custom/path bash scripts/deploy-team.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

AGENTS_DIR="$REPO_DIR/agents"
REFS_DIR="$REPO_DIR/references"
SCRIPTS_DIR="$REPO_DIR/scripts"
CONFIGS_DIR="$REPO_DIR/configs"

BASE_DIR="${OPENCLAW_AGENTS_DIR:-$HOME/openclaw-agents}"
FORCE=false

# Parse args
for arg in "$@"; do
  case $arg in
    --force) FORCE=true ;;
    --help|-h)
      echo "Usage: $0 [--force]"
      echo "  --force   Overwrite existing agent workspaces"
      echo ""
      echo "Environment:"
      echo "  OPENCLAW_AGENTS_DIR   Base directory for agent workspaces (default: ~/openclaw-agents)"
      exit 0
      ;;
  esac
done

echo "🧪 Heisenberg Team Deployment"
echo "================================"
echo "Repo:           $REPO_DIR"
echo "Base directory: $BASE_DIR"
echo "Force:          $FORCE"
echo ""

# List of agents
AGENTS=("heisenberg" "saul" "walter" "jesse" "skyler" "hank" "gus" "twins")

# ── Workspaces ──────────────────────────────────────────────────────────────
for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$BASE_DIR/$agent"

  if [ -d "$AGENT_DIR" ] && [ "$FORCE" = false ]; then
    echo "⚠️  $agent: directory exists, skipping (use --force to overwrite)"
    continue
  fi

  echo "📁 Creating workspace for $agent..."
  mkdir -p "$AGENT_DIR"
  mkdir -p "$AGENT_DIR/memory"
  mkdir -p "$AGENT_DIR/memory/core"
  mkdir -p "$AGENT_DIR/memory/decisions"
  mkdir -p "$AGENT_DIR/memory/archive"
  mkdir -p "$AGENT_DIR/references"
  mkdir -p "$AGENT_DIR/scripts"

  # Copy agent markdown files to workspace root
  if [ -d "$AGENTS_DIR/$agent" ]; then
    cp "$AGENTS_DIR/$agent/"*.md "$AGENT_DIR/" 2>/dev/null || true
    echo "  ✓ Copied agent files from agents/$agent/"
  else
    echo "  ⚠ No agent directory found at agents/$agent/ — skipping file copy"
  fi

  echo "✅ $agent workspace created at $AGENT_DIR"
done

# ── Shared references ────────────────────────────────────────────────────────
echo ""
echo "📋 Copying shared references..."
for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$BASE_DIR/$agent"
  [ -d "$AGENT_DIR/references" ] || mkdir -p "$AGENT_DIR/references"

  if [ -f "$REFS_DIR/team-constitution.md" ]; then
    cp "$REFS_DIR/team-constitution.md" "$AGENT_DIR/references/"
  fi

  if [ -f "$REFS_DIR/team-board.md.example" ]; then
    cp "$REFS_DIR/team-board.md.example" "$AGENT_DIR/references/team-board.md"
  elif [ -f "$REFS_DIR/team-board.md" ]; then
    cp "$REFS_DIR/team-board.md" "$AGENT_DIR/references/"
  fi
done
echo "  ✓ References copied"

# ── Shared scripts ───────────────────────────────────────────────────────────
echo "📜 Copying scripts..."
SHARED_SCRIPTS=("self-heal.sh" "trash-agent-session.sh" "agent-health-check.sh")
for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$BASE_DIR/$agent"
  [ -d "$AGENT_DIR/scripts" ] || mkdir -p "$AGENT_DIR/scripts"

  for script in "${SHARED_SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
      cp "$SCRIPTS_DIR/$script" "$AGENT_DIR/scripts/"
      chmod +x "$AGENT_DIR/scripts/$script"
    fi
  done
done
echo "  ✓ Scripts copied"

# ── Config examples ──────────────────────────────────────────────────────────
echo "⚙️  Copying config examples..."
for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$BASE_DIR/$agent"
  EXAMPLE="$CONFIGS_DIR/$agent.openclaw.json.example"

  if [ -f "$EXAMPLE" ]; then
    cp "$EXAMPLE" "$AGENT_DIR/openclaw.json.example"
    echo "  ✓ $agent config example copied"
  else
    echo "  ⚠ No config example found for $agent at $EXAMPLE"
  fi
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "================================"
echo "✅ All workspaces created!"
echo ""
echo "Next steps:"
echo ""
echo "1. Create Telegram bots via @BotFather (one per agent)"
echo "   See docs/deploy-agents.md for bot names"
echo ""
echo "2. Configure each agent:"
echo "   For each agent in: heisenberg saul walter jesse skyler hank gus twins"
echo "   ┌──────────────────────────────────────────────────────────────────┐"
echo "   │  mkdir -p ~/.openclaw/agents/<agent>                            │"
echo "   │  cp $BASE_DIR/<agent>/openclaw.json.example \\                  │"
echo "   │     ~/.openclaw/agents/<agent>/openclaw.json                   │"
echo "   │  # Edit: replace {{TELEGRAM_BOT_TOKEN}}, {{OWNER_TELEGRAM_ID}} │"
echo "   │  # Edit: replace {{ANTHROPIC_API_KEY}}, {{OPENAI_API_KEY}}     │"
echo "   └──────────────────────────────────────────────────────────────────┘"
echo ""
echo "3. Start agents:"
echo "   bash $SCRIPT_DIR/start-team.sh"
echo "   # Or start individually:"
echo "   cd $BASE_DIR/heisenberg && openclaw gateway start"
echo ""
echo "4. Verify (message Heisenberg in Telegram): 'Hello, are you there?'"
echo ""
echo "See docs/deploy-agents.md for the full guide."
