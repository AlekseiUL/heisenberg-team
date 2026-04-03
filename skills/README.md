# Skills Library

33 shared skills available to all agents. Skills are instruction sets that agents load based on task matching.

## How Skills Work

1. Agent receives a task
2. Scans skill descriptions for the best match
3. Reads `SKILL.md` for step-by-step instructions
4. Executes following the skill's protocol

## Categories

### Documents (6 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **minimax-pdf** | Professional PDFs with design identity | Python (scripts/) |
| **minimax-docx** | DOCX creation via OpenXML SDK | .NET (scripts/) |
| **minimax-xlsx** | Excel file operations | Python, pandas, openpyxl |
| **presentation** | Markdown to slides via Marp | Marp CLI, Node.js |
| **pptx-generator** | PowerPoint generation | Node.js (PptxGenJS) |
| **landing-builder** | One-page HTML landing pages | Tailwind CSS |

### Research & Analysis (6 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **deep-research-pro** | Multi-source research with citations | Web search tools |
| **researcher** | Universal research and competitor analysis | Web search, SearxNG (optional) |
| **channel-analyzer** | Telegram channel analytics | Python, Telethon |
| **reddit** | Reddit browsing, search, posting | Node.js, Reddit OAuth (optional) |
| **blogwatcher** | RSS/Atom feed monitoring | Go (blogwatcher CLI) |
| **tubescribe** | YouTube video summarization | Python, pandoc (optional) |

### Content & Writing (6 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **tweet-writer** | Viral tweets and threads | Web research |
| **brainstorming** | Structured brainstorming sessions | None |
| **writing-plans** | Step-by-step implementation plans | None |
| **swipe-file** | Content analysis (YouTube, Telegram) | tubescribe, web tools |
| **last30days** | 30-day trend research on Reddit + X | Web search |
| **excalidraw** | Diagrams for Obsidian | Node.js, Obsidian |

### Development (4 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **skill-and-agent-creator** | Create and audit OpenClaw skills/agents | OpenClaw |
| **github-publisher** | Publish projects to GitHub | Git, GitHub auth |
| **cursor-agent** | Cursor CLI for coding tasks | Cursor CLI |
| **browser-use-api** | Cloud browser automation | Browser Use API key |

### Automation (3 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **n8n-workflow-automation** | n8n workflow JSON generation | n8n platform |
| **gog** | Google Workspace (Gmail, Calendar, Drive) | gog CLI, OAuth |
| **byterover** | Project knowledge management | ByteRover CLI |

### Quality & Security (4 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **quality-check** | Pre-delivery quality control | None |
| **product-validator** | Automated product checks | Python (scripts/) |
| **audit-website** | Website SEO/security audit | Web fetch tools |
| **systematic-debugging** | Systematic bug investigation | Platform tools |

### Diagnostics (2 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **agent-doctor** | OpenClaw agent self-diagnostics | OpenClaw |
| **safeskillmonitor** | Safe skill monitoring without shell | OpenClaw |

### Utilities (2 skills)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| **weather** | Weather and forecasts | curl (no API key) |
| **gemini** | Google Gemini CLI for Q&A | Node.js, Gemini CLI |

## Which Skills Need Setup?

Most skills work out of the box. These require additional installation:

| Skill | What to Install |
|-------|----------------|
| minimax-pdf | `pip install reportlab pillow` |
| minimax-docx | .NET SDK |
| minimax-xlsx | `pip install pandas openpyxl` |
| presentation | `npm install -g @marp-team/marp-cli` |
| blogwatcher | `go install github.com/Hyaxia/blogwatcher@latest` |
| gog | `brew install steipete/tap/gogcli` |
| channel-analyzer | `pip install telethon` + Telegram account |
| reddit | `npm install` in skills/reddit/ |
| gemini | `npm install -g @google/generative-ai-cli` |
| cursor-agent | Cursor CLI from cursor.com |
| browser-use-api | BROWSER_USE_API_KEY in .env |

## Adding a Skill

See [examples/create-skill.md](../examples/create-skill.md).

Minimum structure:
```
skills/my-skill/
└── SKILL.md      # Instructions with YAML frontmatter
```

Optional:
```
skills/my-skill/
├── SKILL.md      # Instructions
├── scripts/      # Helper scripts
├── data/         # Reference data
└── references/   # Documentation
```
