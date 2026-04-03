# TubeScribe 🎬

**Turn any YouTube video into a polished document + audio summary.**

Drop a YouTube link → get a beautiful transcript with speaker labels, key quotes, clickable timestamps, and an audio summary you can listen to on the go.

## Features

- 🎯 **Smart Speaker Detection** — Automatically identifies participants
- 🔊 **Audio Summaries** — Listen to key points (MP3/WAV)
- 📝 **Clickable Timestamps** — Every quote links directly to that moment in the video
- 💬 **YouTube Comments** — Viewer sentiment analysis and best comments
- 📄 **Transcript with summary and key quotes** — Export as DOCX, HTML, or Markdown
- 📋 **Queue Support** — Send multiple links, they get processed in order
- 🚀 **Non-Blocking Workflow** — Conversation continues while video processes in background

## Free & No Paid APIs

- **No subscriptions** — no API keys, no paid services
- **No usage limits** — process as many videos as you want
- **Local processing** — transcription, speaker detection, TTS all run on your machine
- **Network access** — YouTube fetching (video metadata, captions, comments) requires internet

## Quick Start

Just send a YouTube URL to your agent. TubeScribe handles everything automatically.

### Non-Blocking Processing

TubeScribe runs in the background:
1. You send a YouTube link
2. Agent replies: "🎬 TubeScribe is processing **[title]**..."
3. **You can keep chatting** — conversation isn't blocked
4. When done, you get notified with the results

No waiting, no freezing — just seamless async processing.

### First-Time Setup

```bash
python skills/tubescribe/scripts/setup.py
```

**What setup.py does:** Checks if recommended tools are present (`summarize`, `pandoc`, `ffmpeg`, TTS engine) and offers to install any missing ones. It only downloads from official sources (Homebrew, PyPI, GitHub releases). You can skip any install — the skill works without them using macOS built-in TTS and HTML fallback.

**What setup.py does NOT do:** It does not upload data, contact unknown hosts, or modify system files outside `~/.openclaw/tools/` and `~/.tubescribe/`.

## Output Example

```
~/Documents/TubeScribe/
├── Interview With Expert.docx    # Formatted document
└── Interview With Expert.mp3     # Audio summary
```

### Document Structure

1. **Title** + video info (channel, date, duration)
2. **Participants** — who's speaking
3. **Summary** — key points in 3-5 paragraphs
4. **Key Quotes** — 5 best moments with clickable timestamps
5. **Viewer Sentiment** — what commenters are saying
6. **Best Comments** — top 5 comments by likes
7. **Full Transcript** — merged paragraphs with speaker labels

## Batch & Queue

### Multiple videos at once
```bash
tubescribe url1 url2 url3
```

### Queue management
```bash
tubescribe --queue-add "URL"      # Add while processing
tubescribe --queue-status         # Check queue
tubescribe --queue-next           # Process next
tubescribe --queue-clear          # Clear queue
```

## Configuration

Config file: `~/.tubescribe/config.json`

| Setting | Default | Options |
|---------|---------|---------|
| `document.format` | `docx` | `docx`, `html`, `md` |
| `audio.format` | `mp3` | `mp3`, `wav` |
| `audio.tts_engine` | `mlx` | `mlx`, `kokoro`, `builtin` |
| `mlx_audio.voice_blend` | `{af_heart: 0.6, af_sky: 0.4}` | any voice mix |
| `output.folder` | `~/Documents/TubeScribe` | any path |

## Requirements

- **Required:** `summarize` CLI (`brew install steipete/tap/summarize`)
- **Optional:**
  - `pandoc` — DOCX output (`brew install pandoc`)
  - `ffmpeg` — MP3 audio (`brew install ffmpeg`)
  - `yt-dlp` — YouTube comments (`brew install yt-dlp`)
  - mlx-audio — Fastest TTS on Apple Silicon (auto-installed via setup)
  - Kokoro TTS — PyTorch fallback for non-Apple-Silicon (auto-installed via setup)

### yt-dlp Installation

TubeScribe checks these locations for yt-dlp (in order):

1. System PATH (`which yt-dlp`)
2. Homebrew: `/opt/homebrew/bin/yt-dlp` or `/usr/local/bin/yt-dlp`
3. pip/pipx: `~/.local/bin/yt-dlp`
4. TubeScribe tools: `~/.openclaw/tools/yt-dlp/yt-dlp`

If not found, setup will offer to download a standalone binary to the tools directory.

## Error Handling

Clear messages for common issues:

| Issue | Message |
|-------|---------|
| Private video | ❌ Video is private — can't access |
| No captions | ❌ No captions available for this video |
| Invalid URL | ❌ Not a valid YouTube URL |
| Age-restricted | ❌ Age-restricted video — can't access without login |

## Privacy & Network

**What uses the network:**
- `summarize` CLI / `yt-dlp` — fetches video captions, metadata, and comments from YouTube
- `setup.py` — one-time download of tools (pandoc, ffmpeg, yt-dlp, TTS models) from official sources

**What runs locally (no network):**
- Speaker detection and transcript analysis (Claude sub-agent, same as your main agent)
- TTS audio generation (MLX-Audio Kokoro, Apple `say`, or Kokoro PyTorch — all on-device)
- Document generation (pandoc)
- Audio conversion (ffmpeg)

**No data is uploaded anywhere.** Video content is fetched *from* YouTube, processed on your machine, and saved locally. Nothing is sent back.

**Config paths (`~/.tubescribe/config.json`)** point to local TTS installations on your machine (e.g., `~/.openclaw/tools/mlx-audio`). These are not remote services.

## Security

### Code Injection (Fixed in v1.1.0)
Earlier development versions had a vulnerability where video text could be injected into dynamically executed Python code. This was fixed by properly escaping all text with `json.dumps()`.

### HTML Output (Fixed in v1.1.2+)
- XSS prevention: all text escaped before inline formatting
- Single-quote escaping added in v1.1.3
- Link double-encoding fixed in v1.1.3

### Archive Extraction (Fixed in v1.1.3)
Zip-slip path traversal prevention when installing pandoc/yt-dlp via setup script.

### Shell Commands
The skill uses subprocess to call external CLI tools (`summarize`, `yt-dlp`, `pandoc`, `ffmpeg`). YouTube URLs are validated and normalized before processing, and filenames are sanitized. However, as with any tool that processes external content, review the code if you have concerns.

### External Dependencies
The setup script downloads tools from official sources:
- **pandoc** — from Homebrew or official releases
- **yt-dlp** — from GitHub releases (yt-dlp/yt-dlp)
- **mlx-audio** — pip install from PyPI (Apple Silicon only, uses MLX framework)
- **Kokoro TTS** — pip install from PyPI (PyTorch, cross-platform fallback)

All sources are well-known and widely used. Review `scripts/setup.py` if you have concerns about supply chain security.

## License

MIT

---

Made by Jackie 🦊 & Matus 🇸🇰
