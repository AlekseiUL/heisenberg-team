#!/bin/bash
# setup.sh - One-command setup for Heisenberg Team
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw/agents"
ATTACH_EXISTING=false
INSTALL_SKILLS=true
SELECTED_AGENTS=""

usage() {
  cat <<'EOF'
Usage: bash scripts/setup.sh [options]

Options:
  --agents a,b,c        Install only selected character directories
  --attach-existing     Install into existing ~/.openclaw/agents without implying full fresh setup
  --no-skills           Skip shared skills installation
  --help                Show this help

Examples:
  bash scripts/setup.sh
  bash scripts/setup.sh --agents heisenberg,saul,walter
  bash scripts/setup.sh --attach-existing --agents heisenberg,walter
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agents)
      SELECTED_AGENTS="${2:-}"
      shift 2
      ;;
    --attach-existing)
      ATTACH_EXISTING=true
      shift
      ;;
    --no-skills)
      INSTALL_SKILLS=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Agent mapping: directory name -> OpenClaw agent name
declare -A AGENT_MAP=(
  ["heisenberg"]="main"
  ["saul"]="producer"
  ["walter"]="teamlead"
  ["jesse"]="marketing-funnel"
  ["skyler"]="skyler"
  ["hank"]="hank"
  ["gus"]="kaizen"
  ["twins"]="researcher"
)

ALL_AGENTS=(heisenberg saul walter jesse skyler hank gus twins)
TARGET_AGENTS=()

if [ -n "$SELECTED_AGENTS" ]; then
  IFS=',' read -r -a REQUESTED_AGENTS <<< "$SELECTED_AGENTS"
  for raw_agent in "${REQUESTED_AGENTS[@]}"; do
    agent="$(printf '%s' "$raw_agent" | xargs)"
    [ -z "$agent" ] && continue
    if [ -z "${AGENT_MAP[$agent]:-}" ]; then
      echo "❌ Unknown agent: $agent"
      echo "   Valid agents: ${ALL_AGENTS[*]}"
      exit 1
    fi
    TARGET_AGENTS+=("$agent")
  done
else
  TARGET_AGENTS=("${ALL_AGENTS[@]}")
fi

echo "🧪 Heisenberg Team - Setup"
echo "=========================="
echo ""

# Check prerequisites
command -v openclaw >/dev/null 2>&1 || { echo "❌ OpenClaw not installed. Run: npm install -g openclaw"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js not installed."; exit 1; }

echo "✅ Prerequisites OK"
echo ""
echo "Mode: $( [ "$ATTACH_EXISTING" = true ] && echo "attach to existing OpenClaw" || echo "fresh or standard install" )"
echo "Agents: ${TARGET_AGENTS[*]}"
echo "Skills: $( [ "$INSTALL_SKILLS" = true ] && echo "install" || echo "skip" )"
echo ""

# Check .env
if [ ! -f "$REPO_DIR/.env" ]; then
  echo "⚠️  No .env file found. Copy and configure:"
  echo "   cp .env.example .env"
  echo "   # Edit .env with your values"
  echo ""
  read -p "Continue without .env? [y/N] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo "📦 Installing agents..."
for char_name in "${TARGET_AGENTS[@]}"; do
  agent_name="${AGENT_MAP[$char_name]}"
  src="$REPO_DIR/agents/$char_name"
  dest="$OPENCLAW_DIR/$agent_name/agent"

  if [ -d "$src" ]; then
    mkdir -p "$dest"
    cp "$src"/*.md "$dest/" 2>/dev/null || true
    echo "  ✓ $char_name → $agent_name"
  else
    echo "  ⚠ $char_name directory not found, skipping"
  fi
done

echo ""
if [ "$INSTALL_SKILLS" = true ]; then
  echo "📚 Installing skills..."
  SKILLS_DEST="$OPENCLAW_DIR/producer/agent/skills"
  if [ -d "$REPO_DIR/skills" ]; then
    mkdir -p "$SKILLS_DEST"
    SKILL_OK=0
    SKILL_FAIL=0
    for skill_dir in "$REPO_DIR/skills"/*/; do
      skill_name=$(basename "$skill_dir")
      if cp -r "$skill_dir" "$SKILLS_DEST/" 2>/dev/null; then
        SKILL_OK=$((SKILL_OK + 1))
      else
        echo "  ⚠ Failed to copy: $skill_name"
        SKILL_FAIL=$((SKILL_FAIL + 1))
      fi
    done
    echo "  ✓ $SKILL_OK skills installed"
    [ "$SKILL_FAIL" -gt 0 ] && echo "  ⚠ $SKILL_FAIL skills failed — check permissions"
  else
    echo "  ❌ Skills directory not found!"
    exit 1
  fi
else
  echo "📚 Skipping skills installation (--no-skills)"
fi

echo ""
echo "📄 Installing references..."
if [ -d "$REPO_DIR/references" ]; then
  echo "  References are in $REPO_DIR/references/"
  echo "  Copy them to your workspace as needed."
fi

echo ""

# Verify installation
echo "🔍 Verifying..."
INSTALLED_COUNT=0
for char_name in "${TARGET_AGENTS[@]}"; do
  agent_name="${AGENT_MAP[$char_name]}"
  if [ -d "$OPENCLAW_DIR/$agent_name/agent" ]; then
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  fi
done
echo "  Selected agents installed: $INSTALLED_COUNT/${#TARGET_AGENTS[@]}"
if [ "$INSTALLED_COUNT" -lt "${#TARGET_AGENTS[@]}" ]; then
  echo "  ⚠ Expected ${#TARGET_AGENTS[@]} selected agents. Check the output above for errors."
fi

# Check for remaining placeholders in selected agents
PLACEHOLDER_COUNT=0
for char_name in "${TARGET_AGENTS[@]}"; do
  if [ -d "$REPO_DIR/agents/$char_name" ]; then
    count=$(grep -rl '{{[A-Z_]*}}' "$REPO_DIR/agents/$char_name" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
    PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + count))
  fi
done
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
  echo ""
  echo "  ⚠ $PLACEHOLDER_COUNT selected agent file(s) still contain {{PLACEHOLDER}} values."
  echo "  Run the setup wizard to fill them: bash scripts/setup-wizard.sh"
fi

echo ""
echo "=========================="
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run: openclaw init (if first time or when attaching to an existing install)"
echo "  2. Prepare configs from configs/*.example or configs/generated/"
echo "  3. Run: openclaw gateway start"
echo "  4. Run: bash scripts/smoke-test.sh --agents $(IFS=,; echo "${TARGET_AGENTS[*]}")"
echo "  5. Send a message to your bot"
echo ""
echo "📖 Guide: docs/first-task.md"
echo ""
echo "🧪 Say my name."
