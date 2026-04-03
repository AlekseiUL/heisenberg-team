#!/bin/bash
# start-team.sh — Start all Heisenberg Team agents
#
# Usage:
#   bash scripts/start-team.sh                    # Start all agents
#   bash scripts/start-team.sh heisenberg walter  # Start specific agents only
#
# Each agent must have:
#   - Workspace at ~/openclaw-agents/<agent>/
#   - Config at ~/.openclaw/agents/<agent>/openclaw.json

set -e

BASE_DIR="${OPENCLAW_AGENTS_DIR:-$HOME/openclaw-agents}"
ALL_AGENTS=("heisenberg" "saul" "walter" "jesse" "skyler" "hank" "gus" "twins")

# If agents specified as args, use those; otherwise start all
if [ $# -gt 0 ]; then
  AGENTS=("$@")
else
  AGENTS=("${ALL_AGENTS[@]}")
fi

echo "🧪 Starting Heisenberg Team"
echo "================================"
echo "Base directory: $BASE_DIR"
echo "Agents: ${AGENTS[*]}"
echo ""

STARTED=0
FAILED=0
SKIPPED=0

for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$BASE_DIR/$agent"

  # Check workspace exists
  if [ ! -d "$AGENT_DIR" ]; then
    echo "⚠️  $agent: workspace not found at $AGENT_DIR — skipping"
    echo "   Run: bash scripts/deploy-team.sh"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Check config exists
  if [ ! -f "$HOME/.openclaw/agents/$agent/openclaw.json" ]; then
    echo "⚠️  $agent: config not found at ~/.openclaw/agents/$agent/openclaw.json — skipping"
    echo "   Copy and edit: cp $AGENT_DIR/openclaw.json.example ~/.openclaw/agents/$agent/openclaw.json"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo -n "🚀 Starting $agent... "
  if cd "$AGENT_DIR" && openclaw gateway start --detach 2>/dev/null; then
    echo "✅"
    STARTED=$((STARTED + 1))
  else
    # openclaw gateway start might not have --detach, try without
    if cd "$AGENT_DIR" && openclaw gateway start &>/dev/null & then
      echo "✅ (background)"
      STARTED=$((STARTED + 1))
    else
      echo "❌ failed"
      FAILED=$((FAILED + 1))
    fi
  fi

  # Small delay to avoid port conflicts during startup
  sleep 1
done

echo ""
echo "================================"
echo "Started:  $STARTED"
echo "Skipped:  $SKIPPED"
echo "Failed:   $FAILED"
echo ""

if [ $STARTED -gt 0 ]; then
  echo "✅ Agents are running!"
  echo ""
  echo "Check status:"
  for agent in "${AGENTS[@]}"; do
    AGENT_DIR="$BASE_DIR/$agent"
    [ -d "$AGENT_DIR" ] && echo "  cd $AGENT_DIR && openclaw status"
  done
fi

if [ $FAILED -gt 0 ]; then
  echo ""
  echo "⚠️  Some agents failed to start. Check logs:"
  echo "  cd ~/openclaw-agents/<agent> && openclaw gateway logs"
fi
