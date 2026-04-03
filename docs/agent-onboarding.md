# Agent Onboarding Guide

Each agent performs automatic onboarding on first launch. But you can also configure them manually.

## How Auto-Onboarding Works

1. Start the agent (gateway running + send first message)
2. Agent detects `{{placeholder}}` values in its MEMORY.md
3. Agent introduces itself and asks for initial data
4. You provide information step by step
5. Agent saves data and confirms readiness

## Manual Setup Checklist

### 🧪 Heisenberg (Main Agent)
- [ ] Set your name and timezone in MEMORY.md
- [ ] Choose communication language
- [ ] Describe your main project
- [ ] Decide which team agents to activate

### 💼 Saul Goodman (Producer)
- [ ] List your content platforms
- [ ] Define content pipeline stages
- [ ] Set posting schedule
- [ ] Provide style guide (if any)

### 👨‍🔬 Walter White (Tech Lead)
- [ ] Set programming languages/stacks
- [ ] Configure GitHub integration
- [ ] Define coding standards
- [ ] Set up code review workflow

### 🎯 Jesse Pinkman (Marketing)
- [ ] Set brand name and audience
- [ ] Link social media accounts
- [ ] Provide baseline metrics
- [ ] Define brand voice/tone
- [ ] List competitors

### 💰 Skyler White (Finance)
- [ ] List income sources with amounts
- [ ] List recurring expenses
- [ ] Set currency
- [ ] Upload bank statements (optional)
- [ ] Configure payment platform integration
- [ ] Set financial goals

### 🔫 Hank Schrader (Security)
- [ ] List monitored hosts/IPs
- [ ] Document exposed ports
- [ ] Configure firewall rules
- [ ] Verify SSH key access
- [ ] Map sensitive data locations
- [ ] Document backup strategy

### 🎯 Gus Fring (Kaizen)
- [ ] Set quarterly goals (OKR format recommended)
- [ ] Define daily habits to track
- [ ] Configure note system integration
- [ ] Set review frequency
- [ ] Define success metrics

### 👥 Salamanca Twins (Research)
- [ ] Set monitoring topics/keywords
- [ ] List competitor URLs
- [ ] Add RSS feeds
- [ ] Set reporting frequency
- [ ] Choose preferred sources

## Tips
- Start with Heisenberg only — add agents as you need them
- You don't need to fill everything at once
- Agents remember what you tell them and build knowledge over time
- Use `{{PLACEHOLDER}}` grep to find unfilled values:
  ```bash
  grep -rn '{{' agents/ --include='*.md' | grep -v node_modules
  ```
