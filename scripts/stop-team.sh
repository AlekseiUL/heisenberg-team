#!/bin/bash
# stop-team.sh — Stop all Heisenberg Team agents
#
# Usage:
#   bash scripts/stop-team.sh                    # Stop all agents
#   bash scripts/stop-team.sh heisenberg walter  # Stop specific agents only

set -e

BASE_DIR="${OPENCLAW_AGENTS_DIR:-$HOME/openclaw-agents}"
ALL_AGENTS=("heisenberg" "saul" "walter" "jesse" "skyler" "hank" "gus" "twins")

# If agents specified as args, use those; otherwise stop all
if [ $# -gt 0 ]; then
  AGENTS=("$@")
else
  AGENTS=("${ALL_AGENTS[@]}")
fi

echo "🛑 Stopping Heisenberg Team"
echo "================================"
echo "Agents: ${AGENTS[*]}"
echo ""

STOPPED=0
SKIPPED=0

for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$BASE_DIR/$agent"

  if [ ! -d "$AGENT_DIR" ]; then
    echo "⚠️  $agent: workspace not found — skipping"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo -n "🔴 Stopping $agent... "
  if cd "$AGENT_DIR" && openclaw gateway stop 2>/dev/null; then
    echo "✅"
    STOPPED=$((STOPPED + 1))
  else
    echo "⚠️  (may not have been running)"
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo ""
echo "================================"
echo "Stopped: $STOPPED"
echo "Skipped: $SKIPPED"
echo ""
echo "To restart: bash scripts/start-team.sh"
