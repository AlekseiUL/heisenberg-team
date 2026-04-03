#!/bin/bash
# setup.sh - One-command setup for Heisenberg Team
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw/agents"

echo "🧪 Heisenberg Team - Setup"
echo "=========================="
echo ""

# Check prerequisites
command -v openclaw >/dev/null 2>&1 || { echo "❌ OpenClaw not installed. Run: npm install -g openclaw"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js not installed."; exit 1; }

echo "✅ Prerequisites OK"
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

echo "📦 Installing agents..."
for char_name in "${!AGENT_MAP[@]}"; do
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

echo ""
echo "📄 Installing references..."
if [ -d "$REPO_DIR/references" ]; then
  echo "  References are in $REPO_DIR/references/"
  echo "  Copy them to your workspace as needed."
fi

echo ""

# Verify installation
echo "🔍 Verifying..."
AGENT_COUNT=$(ls "$OPENCLAW_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo "  Agents installed: $AGENT_COUNT/8"
if [ "$AGENT_COUNT" -lt 8 ]; then
  echo "  ⚠ Expected 8 agents. Check the output above for errors."
fi

# Check for remaining placeholders
PLACEHOLDER_COUNT=$(grep -rl '{{[A-Z_]*}}' "$REPO_DIR/agents" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
  echo ""
  echo "  ⚠ $PLACEHOLDER_COUNT agent files still contain {{PLACEHOLDER}} values."
  echo "  Run the setup wizard to fill them: bash scripts/setup-wizard.sh"
fi

echo ""
echo "=========================="
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run: openclaw init (if first time)"
echo "  2. Run: openclaw gateway start"
echo "  3. Run: openclaw status (verify 8 agents)"
echo "  4. Send a message to your bot"
echo ""
echo "📖 Guide: docs/first-task.md"
echo ""
echo "🧪 Say my name."
