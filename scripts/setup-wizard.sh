#!/bin/bash
# setup-wizard.sh — Interactive setup for Heisenberg Team
# Guides user through all configuration steps
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Cross-platform sed: macOS uses -i '', Linux uses -i
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i ''"
else
  SED_INPLACE="sed -i"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🧪 Heisenberg Team — Setup Wizard${NC}"
echo "========================================"
echo ""
echo -e "${CYAN}This wizard will configure your multi-agent system.${NC}"
echo -e "${CYAN}It takes about 5 minutes. You can re-run it anytime.${NC}"
echo ""

# ─── Step 1: Check prerequisites ───
echo -e "${BOLD}Step 1/5: Checking prerequisites...${NC}"
echo ""

ERRORS=0

if command -v openclaw >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} OpenClaw installed ($(openclaw --version 2>/dev/null || echo 'version unknown'))"
else
  echo -e "  ${RED}✗${NC} OpenClaw not found. Install: ${BOLD}npm install -g openclaw${NC}"
  ERRORS=$((ERRORS + 1))
fi

if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version)
  echo -e "  ${GREEN}✓${NC} Node.js $NODE_VER"
else
  echo -e "  ${RED}✗${NC} Node.js not found. Install v20+ from https://nodejs.org/"
  ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo -e "${RED}Fix the issues above and re-run this script.${NC}"
  exit 1
fi

echo ""

# ─── Step 2: Collect user data ───
echo -e "${BOLD}Step 2/5: Your information${NC}"
echo -e "${CYAN}This data replaces {{PLACEHOLDER}} values in agent configs.${NC}"
echo ""

# Helper: prompt with default
ask() {
  local var_name="$1"
  local prompt="$2"
  local default="${3:-}"
  local required="${4:-false}"

  if [ -n "$default" ]; then
    read -p "  $prompt [$default]: " value
    value="${value:-$default}"
  else
    if [ "$required" = "true" ]; then
      while true; do
        read -p "  $prompt: " value
        [ -n "$value" ] && break
        echo -e "  ${RED}This field is required.${NC}"
      done
    else
      read -p "  $prompt (skip with Enter): " value
    fi
  fi
  eval "$var_name=\"$value\""
}

echo -e "${YELLOW}── Required ──${NC}"
ask OWNER_NAME "Your first name" "" true
ask OWNER_USERNAME "Your GitHub/online username" "" true

echo ""
echo -e "${YELLOW}── LLM Provider ──${NC}"
echo ""
echo "  Which LLM provider do you use?"
echo ""
echo "  1) Anthropic (Claude) — recommended"
echo "  2) OpenAI (GPT-4, GPT-4o)"
echo "  3) Google (Gemini)"
echo "  4) Ollama (local models)"
echo "  5) Other / I'll configure manually"
echo ""
read -p "  Choose [1]: " LLM_CHOICE
LLM_CHOICE="${LLM_CHOICE:-1}"

case "$LLM_CHOICE" in
  1)
    LLM_PROVIDER="anthropic"
    MAIN_MODEL="anthropic/claude-opus-4-5"
    AGENT_MODEL="anthropic/claude-sonnet-4-5"
    ask ANTHROPIC_API_KEY "Anthropic API key (or 'max' for Claude Max subscription)" "" true
    if [ "$ANTHROPIC_API_KEY" = "max" ]; then
      ANTHROPIC_API_KEY=""
      echo -e "  ${CYAN}Claude Max detected — no API key needed, uses built-in auth${NC}"
    fi
    ;;
  2)
    LLM_PROVIDER="openai"
    MAIN_MODEL="openai/gpt-4o"
    AGENT_MODEL="openai/gpt-4o"
    ask OPENAI_API_KEY "OpenAI API key" "" true
    ;;
  3)
    LLM_PROVIDER="google"
    MAIN_MODEL="google/gemini-2.5-pro"
    AGENT_MODEL="google/gemini-2.5-flash"
    ask GOOGLE_API_KEY "Google AI API key" "" true
    ;;
  4)
    LLM_PROVIDER="ollama"
    MAIN_MODEL="ollama/llama3"
    AGENT_MODEL="ollama/llama3"
    echo -e "  ${CYAN}Make sure Ollama is running: ollama serve${NC}"
    ask OLLAMA_MODEL "Ollama model name" "llama3" false
    MAIN_MODEL="ollama/$OLLAMA_MODEL"
    AGENT_MODEL="ollama/$OLLAMA_MODEL"
    ;;
  5)
    LLM_PROVIDER="custom"
    ask MAIN_MODEL "Main model (provider/model format)" "anthropic/claude-opus-4-5" true
    AGENT_MODEL="$MAIN_MODEL"
    ;;
esac

echo ""
echo "  Embedding model for vector memory (semantic search)."
echo "  Options:"
echo "    - OpenAI text-embedding-3-small (recommended, needs OpenAI key)"
echo "    - Skip (memory search will use BM25 only, no vectors)"
echo ""

if [ "$LLM_PROVIDER" = "openai" ] && [ -n "${OPENAI_API_KEY:-}" ]; then
  EMBEDDING_PROVIDER="openai"
  EMBEDDING_MODEL="text-embedding-3-small"
  echo -e "  ${GREEN}✓${NC} Using OpenAI embeddings (same API key)"
else
  read -p "  OpenAI API key for embeddings (or 'skip'): " EMBED_KEY
  if [ "$EMBED_KEY" = "skip" ] || [ -z "$EMBED_KEY" ]; then
    EMBEDDING_PROVIDER="none"
    EMBEDDING_MODEL=""
    echo -e "  ${YELLOW}⚠${NC} Embeddings skipped — memory search will be keyword-only"
  else
    OPENAI_API_KEY="$EMBED_KEY"
    EMBEDDING_PROVIDER="openai"
    EMBEDDING_MODEL="text-embedding-3-small"
    echo -e "  ${GREEN}✓${NC} Embeddings configured"
  fi
fi

echo ""
echo -e "${YELLOW}── Telegram (recommended) ──${NC}"
echo -e "  ${CYAN}Agents send you status updates via Telegram.${NC}"
echo -e "  ${CYAN}Get your ID from @userinfobot on Telegram.${NC}"
ask OWNER_TELEGRAM_ID "Your Telegram user ID (digits)"
ask TELEGRAM_CHANNEL "Your Telegram channel name (without @)"
ask BOT_USERNAME "Main bot username (e.g. @MyBot_bot)"

echo ""
echo -e "${YELLOW}── Optional ──${NC}"
ask OWNER_SURNAME "Your last name"
ask COUNTRY "Your country"
ask CITY "Your city"
ask GITHUB_ORG "GitHub organization/username" "$OWNER_USERNAME"
ask WORKSPACE_PATH "Workspace path" "~/workspace/"

echo ""

# ─── Step 3: Replace placeholders ───
echo -e "${BOLD}Step 3/5: Applying configuration...${NC}"
echo ""

# Build replacement pairs
declare -A REPLACEMENTS=(
  ["{{OWNER_NAME}}"]="${OWNER_NAME}"
  ["{{OWNER_USERNAME}}"]="${OWNER_USERNAME}"
  ["{{OWNER_TELEGRAM_ID}}"]="${OWNER_TELEGRAM_ID:-YOUR_TELEGRAM_ID}"
  ["{{TELEGRAM_CHANNEL}}"]="${TELEGRAM_CHANNEL:-YOUR_CHANNEL}"
  ["{{BOT_USERNAME}}"]="${BOT_USERNAME:-@YourBot_bot}"
  ["{{OWNER_SURNAME}}"]="${OWNER_SURNAME:-Surname}"
  ["{{COUNTRY}}"]="${COUNTRY:-Country}"
  ["{{CITY}}"]="${CITY:-City}"
  ["{{GITHUB_ORG}}"]="${GITHUB_ORG:-$OWNER_USERNAME}"
  ["{{WORKSPACE_PATH}}"]="${WORKSPACE_PATH:-~/workspace/}"
  ["{{PROJECTS_PATH}}"]="${WORKSPACE_PATH:-~/workspace/}projects/"
  ["{{MAIN_MODEL}}"]="${MAIN_MODEL:-anthropic/claude-opus-4-5}"
  ["{{AGENT_MODEL}}"]="${AGENT_MODEL:-anthropic/claude-sonnet-4-5}"
  ["{{EMBEDDING_PROVIDER}}"]="${EMBEDDING_PROVIDER:-openai}"
  ["{{EMBEDDING_MODEL}}"]="${EMBEDDING_MODEL:-text-embedding-3-small}"
  ["{{ANTHROPIC_API_KEY}}"]="${ANTHROPIC_API_KEY:-your-anthropic-key}"
  ["{{OPENAI_API_KEY}}"]="${OPENAI_API_KEY:-your-openai-key}"
  ["{{GOOGLE_API_KEY}}"]="${GOOGLE_API_KEY:-your-google-key}"
)

# Count files to process
FILE_COUNT=$(find "$REPO_DIR" -type f \( \
  -name "*.md" -o -name "*.sh" -o -name "*.txt" -o \
  -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o \
  -name "*.example" -o -name "*.py" -o -name "LICENSE" \
\) ! -path "*/setup-wizard.sh" ! -path "*/.git/*" | wc -l | tr -d ' ')

echo -e "  Processing $FILE_COUNT files..."
echo ""

REPLACED_TOTAL=0

for placeholder in "${!REPLACEMENTS[@]}"; do
  value="${REPLACEMENTS[$placeholder]}"
  # Escape special chars for sed
  escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
  escaped_placeholder=$(printf '%s\n' "$placeholder" | sed 's/[{}]/\\&/g')

  count=$(grep -rl "$placeholder" "$REPO_DIR" --include="*.md" --include="*.sh" --include="*.txt" --include="*.yaml" --include="*.yml" --include="*.json" --include="*.example" --include="*.py" --include="LICENSE" 2>/dev/null | grep -v setup-wizard.sh | grep -v depersonalize.sh | wc -l | tr -d ' ')

  if [ "$count" -gt 0 ]; then
    find "$REPO_DIR" -type f \( \
      -name "*.md" -o -name "*.sh" -o -name "*.txt" -o \
      -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o \
      -name "*.example" -o -name "*.py" -o -name "LICENSE" \
    \) ! -path "*/setup-wizard.sh" ! -path "*/depersonalize.sh" ! -path "*/.git/*" \
    -print0 2>/dev/null | while IFS= read -r -d '' file; do
      eval "$SED_INPLACE \"s|$escaped_placeholder|$escaped_value|g\" \"$file\"" 2>/dev/null || true
    done

    echo -e "  ${GREEN}✓${NC} $placeholder → $value ($count files)"
    REPLACED_TOTAL=$((REPLACED_TOTAL + count))
  fi
done

echo ""
echo -e "  Replaced in $REPLACED_TOTAL file locations."
echo ""

# ─── Step 4: Install agents and skills ───
echo -e "${BOLD}Step 4/5: Installing agents and skills...${NC}"
echo ""

OPENCLAW_DIR="$HOME/.openclaw/agents"

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

INSTALLED=0
for char_name in "${!AGENT_MAP[@]}"; do
  agent_name="${AGENT_MAP[$char_name]}"
  src="$REPO_DIR/agents/$char_name"
  dest="$OPENCLAW_DIR/$agent_name/agent"

  if [ -d "$src" ]; then
    mkdir -p "$dest"
    cp "$src"/*.md "$dest/"
    echo -e "  ${GREEN}✓${NC} $char_name → $agent_name"
    INSTALLED=$((INSTALLED + 1))
  else
    echo -e "  ${YELLOW}⚠${NC} $char_name not found, skipping"
  fi
done

echo ""

# Skills
SKILLS_DEST="$OPENCLAW_DIR/producer/agent/skills"
if [ -d "$REPO_DIR/skills" ]; then
  mkdir -p "$SKILLS_DEST"
  SKILL_ERRORS=0
  SKILL_OK=0
  for skill_dir in "$REPO_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    if cp -r "$skill_dir" "$SKILLS_DEST/" 2>/dev/null; then
      SKILL_OK=$((SKILL_OK + 1))
    else
      echo -e "  ${YELLOW}⚠${NC} Failed to copy skill: $skill_name"
      SKILL_ERRORS=$((SKILL_ERRORS + 1))
    fi
  done
  echo -e "  ${GREEN}✓${NC} $SKILL_OK skills installed"
  if [ "$SKILL_ERRORS" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠${NC} $SKILL_ERRORS skills failed to copy"
  fi
else
  echo -e "  ${RED}✗${NC} Skills directory not found!"
fi

echo ""

# ─── Step 5: Verification ───
echo -e "${BOLD}Step 5/5: Verification...${NC}"
echo ""

# Check remaining placeholders
REMAINING=$(grep -rn '{{[A-Z_]*}}' "$REPO_DIR" \
  --include="*.md" --include="*.sh" --include="*.py" \
  2>/dev/null \
  | grep -v setup-wizard.sh \
  | grep -v depersonalize.sh \
  | grep -v ".env.example" \
  | grep -v "quality-check/SKILL.md" \
  | wc -l | tr -d ' ')

if [ "$REMAINING" -gt 0 ]; then
  echo -e "  ${YELLOW}⚠${NC} $REMAINING placeholder(s) still unfilled."
  echo -e "  ${CYAN}  These are optional fields. You can fill them later by editing the files directly.${NC}"
  echo -e "  ${CYAN}  Run: grep -rn '{{[A-Z_]*}}' . --include='*.md' | grep -v setup-wizard | head -20${NC}"
else
  echo -e "  ${GREEN}✓${NC} All placeholders replaced"
fi

# Check agents installed
AGENT_COUNT=$(ls "$OPENCLAW_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} $AGENT_COUNT agents installed in ~/.openclaw/agents/"

# Check skills
SKILL_COUNT=$(ls "$SKILLS_DEST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} $SKILL_COUNT skills installed"

echo ""
echo "========================================"
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Initialize OpenClaw (if first time):  ${BOLD}openclaw init${NC}"
echo -e "  2. Start the system:                     ${BOLD}openclaw gateway start${NC}"
echo -e "  3. Check status:                         ${BOLD}openclaw status${NC}"
echo -e "  4. Send a message to your bot to test!"
echo ""
echo -e "Guides:"
echo -e "  First task:    ${BLUE}docs/first-task.md${NC}"
echo -e "  Architecture:  ${BLUE}docs/architecture.md${NC}"
echo -e "  FAQ:           ${BLUE}docs/faq.md${NC}"
echo ""
echo -e "🧪 ${BOLD}Say my name.${NC}"
