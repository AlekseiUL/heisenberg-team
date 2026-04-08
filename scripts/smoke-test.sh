#!/bin/bash
# smoke-test.sh — Quick verification that Heisenberg Team is correctly installed
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
SELECTED_AGENTS=""
ALL_AGENTS=(heisenberg saul walter jesse skyler hank gus twins)
TARGET_AGENTS=()

usage() {
  cat <<'EOF'
Usage: bash scripts/smoke-test.sh [options]

Options:
  --agents a,b,c   Check only selected character directories
  --help           Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agents)
      SELECTED_AGENTS="${2:-}"
      shift 2
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

if [ -n "$SELECTED_AGENTS" ]; then
  IFS=',' read -r -a TARGET_AGENTS <<< "$SELECTED_AGENTS"
  for i in "${!TARGET_AGENTS[@]}"; do
    TARGET_AGENTS[$i]="$(printf '%s' "${TARGET_AGENTS[$i]}" | xargs)"
  done
else
  TARGET_AGENTS=("${ALL_AGENTS[@]}")
fi

echo ""
echo "🧪 Heisenberg Team — Smoke Test"
echo "================================="
echo ""
echo "Agents under test: ${TARGET_AGENTS[*]}"
echo ""

# 1. Check critical files
echo "Checking critical files..."
for f in agents/heisenberg/AGENTS.md agents/heisenberg/SOUL.md agents/heisenberg/IDENTITY.md \
         references/team-constitution.md references/team-board.md.example \
         README.md LICENSE SETUP.md; do
  if [ -f "$f" ]; then
    echo -e "  ${GREEN}✓${NC} $f"
  else
    echo -e "  ${RED}✗${NC} $f MISSING"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# 2. Check selected agents
echo "Checking agents..."
for agent in "${TARGET_AGENTS[@]}"; do
  dir="agents/$agent"
  if [ -d "$dir" ] && [ -f "$dir/AGENTS.md" ] && [ -f "$dir/SOUL.md" ]; then
    echo -e "  ${GREEN}✓${NC} $agent"
  else
    echo -e "  ${RED}✗${NC} $agent — missing files"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# 3. Check for remaining placeholders
echo "Checking for unfilled placeholders..."
PLACEHOLDER_COUNT=0
for agent in "${TARGET_AGENTS[@]}"; do
  if [ -d "agents/$agent" ]; then
    count=$(grep -r '{{' "agents/$agent" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
    PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + count))
  fi
done
REFERENCE_PLACEHOLDERS=$(grep -r '{{' references/ --include="*.md" 2>/dev/null | grep -v '.example' | wc -l | tr -d ' ')
PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + REFERENCE_PLACEHOLDERS))
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
  echo -e "  ${YELLOW}⚠${NC} $PLACEHOLDER_COUNT unfilled placeholders found"
  echo "    Run: grep -rn '{{' agents/ references/ --include='*.md' | head -10"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "  ${GREEN}✓${NC} All placeholders filled"
fi

echo ""

# 4. Check configs
echo "Checking configs..."
if ls configs/*.example 1>/dev/null 2>&1; then
  CONFIG_COUNT=$(ls configs/*.example | wc -l | tr -d ' ')
  echo -e "  ${GREEN}✓${NC} $CONFIG_COUNT config templates found"
else
  echo -e "  ${RED}✗${NC} No config templates in configs/"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# 5. Check scripts
echo "Checking scripts..."
SCRIPT_ERRORS=0
for f in scripts/*.sh; do
  if ! bash -n "$f" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} Syntax error: $f"
    SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
  fi
done
if [ "$SCRIPT_ERRORS" -eq 0 ]; then
  echo -e "  ${GREEN}✓${NC} All scripts pass syntax check"
else
  ERRORS=$((ERRORS + SCRIPT_ERRORS))
fi

echo ""

# 6. Check OpenClaw
echo "Checking OpenClaw..."
if command -v openclaw >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} OpenClaw installed ($(openclaw --version 2>/dev/null || echo 'version unknown'))"
else
  echo -e "  ${YELLOW}⚠${NC} OpenClaw not installed — install with: npm install -g openclaw"
  WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "================================="
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
elif [ "$ERRORS" -eq 0 ]; then
  echo -e "${YELLOW}⚠️  Passed with $WARNINGS warning(s)${NC}"
else
  echo -e "${RED}❌ $ERRORS error(s), $WARNINGS warning(s)${NC}"
  exit 1
fi
