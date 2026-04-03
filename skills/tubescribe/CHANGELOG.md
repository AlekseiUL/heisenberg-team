# Changelog

All notable changes to TubeScribe.

## [1.1.8] - 2026-02-10

### Changed
- **Description updated** — clarifies works out of the box, optional tools enhance quality, internet required for YouTube
- Added **OpenClaw metadata** — declares `summarize` as required binary (`requires.bins`)
- Added security clarifications to SKILL.md: no data uploaded, sub-agent has strict no-install instructions
- Expanded setup.py documentation in README (what it does and doesn't do)
- Fixed display name on ClawHub: "TubeScribe" (was "Tubescribe")

## [1.1.7] - 2026-02-10

### Security
- **Code injection risk in voice blending** — `blend_name` was interpolated raw into subprocess code strings; now passed via `json.dumps` for safe escaping
- **URL validation bypass** — replaced regex-based domain extraction with `urllib.parse.urlparse()` to prevent bypass via URLs like `youtube.com@evil.com`
- **CSS-based XSS in HTML writer** — added `style` attribute stripping alongside existing `on*` event handler removal

### Fixed
- **`is_processing()` had write side-effects** — split into read-only `is_processing()` and separate `clear_stale_current()` for stale entry cleanup
- **Duplicate `tempfile` import** — removed redundant local import in `generate_builtin_audio` (already imported at module level)
- **Silent fallthrough for unknown doc formats** — `convert_to_document` now warns and falls back to markdown instead of silently returning raw path
- **`prompt_yn` crash in non-interactive mode** — `input()` now catches `EOFError`/`KeyboardInterrupt` and returns `False`
- **Hardcoded pandoc version** — `install_pandoc()` now fetches latest release from GitHub API, falls back to known version
- **Fragile misaki espeak patch** — replaced exact string match with regex pattern; skips if already patched; warns if target code has changed

### Added
- **Markdown list support in HTML writer** — unordered (`- item`), ordered (`1. item`) lists now render as `<ul>`/`<ol>` with proper styling
- **Fenced code block support** — ` ``` ` blocks render as `<pre><code>` with syntax-appropriate styling
- **Inline code support** — `` `code` `` renders as `<code>` with monospace background
- **Config validation** — `load_config()` now validates types and ranges (format enums, numeric bounds, booleans); invalid values silently revert to defaults
- **File locking on `save_config`** — uses `fcntl.flock` to prevent concurrent write corruption (matches queue locking pattern)
- **Missing fcntl warning** — queue operations now log a stderr warning (once) when file locking is unavailable on non-Unix platforms

### Changed
- **"100% Free & Local" → "Free & No Paid APIs"** — clarified that YouTube fetching requires internet; processing and TTS are local
- Added **Privacy & Network** section to README — explains exactly what uses network vs what runs locally
- Clarified that config paths (`~/.tubescribe/config.json`) point to local TTS installations, not remote services
- Updated SKILL.md to match new wording
- Updated author line: `Jackie 🦊 & Matus 🇸🇰`
- Updated footer: `Made by Jackie 🦊 & Matus 🇸🇰`
- **Renamed `config.get()` → `config.get_value()`** — avoids shadowing Python's built-in `get`

## [1.1.6] - 2026-02-10

### Fixed
- Wrapped long code line in SKILL.md that caused horizontal scroll on ClawHub page

## [1.1.5] - 2026-02-10

### Added
- **MLX-Audio TTS backend** — 3-4x faster audio generation on Apple Silicon via Apple's MLX framework
  - Uses `mlx-community/Kokoro-82M-bf16` — same Kokoro model, native Metal GPU backend
  - New `mlx_audio` config section for model, voice, language, and speed settings
  - Custom voice blending support (`voice_blend` config with arbitrary weights, e.g. 60% af_heart + 40% af_sky)
  - Blended voices cached as `.safetensors` — created once, reused on subsequent runs
  - Graceful fallback chain: mlx → kokoro (PyTorch) → builtin (macOS say)
- **`find_mlx_audio()` helper** — detects mlx-audio venv or system install
- **`_get_or_create_mlx_blended_voice()`** — creates and caches blended voice tensors in HF cache
- **Setup wizard with platform-aware TTS install** — detects Apple Silicon, offers mlx-audio; offers PyTorch Kokoro on other platforms
- **`install_mlx_audio()`** — creates venv, installs deps, patches misaki/espeak for homebrew, verifies
- **`is_apple_silicon()` helper** — platform detection for install decisions

### Changed
- **Default TTS engine is now `mlx`** — fastest option on Apple Silicon (M1/M2/M3/M4)
- **TTS engine priority:** `mlx` > `kokoro` > `builtin` (was: `kokoro` > `builtin`)
- **Config default updated** — `audio.tts_engine` default changed from `builtin` to `mlx`
- **Kokoro install rewritten** — clean venv + pip install (no more git clone of 2GB repo with CoreML models)
- **`find_kokoro()` simplified** — checks venv first, then system Python, then legacy locations
- **SKILL.md** — updated audio generation instructions with mlx-audio commands
- **`fcntl` import is now conditional** — prevents crash on non-Unix systems; queue locking degrades gracefully to no-op
- **`determine_config` uses `deep_merge`** — was using shallow `.update()` which could lose nested user customizations
- **Atomic queue operations** — replaced separate `load_queue()` + `save_queue()` with `_locked_queue()` context manager that holds exclusive lock across read-modify-write
- **Temp files use per-user directory** — `/tmp/tubescribe-{uid}/` with `0o700` permissions instead of predictable `/tmp/tubescribe_{video_id}_*` paths

### Fixed
- **Double JSON encoding in Kokoro TTS** — `voice_blend` was double-encoded via `json.dumps(json.dumps(...))`, now uses `!r` repr formatting
- **Builtin TTS mp3 path handling** — `generate_builtin_audio` could produce wrong filenames when `output_path` didn't end with `.mp3`; now matches the defensive checks in mlx/kokoro generators
- **HTML injection via raw passthrough** — markdown lines starting with `<` were passed through unescaped; dangerous tags (`script`, `iframe`, `object`, `embed`, `form`, etc.) are now escaped
- **Recursive fallback in `convert_to_document`** — docx-to-html fallback used a recursive call; replaced with direct HTML generation
- **Dead code in `install_mlx_audio`** — removed unused `espeak_py` variable that was immediately overwritten by glob
- **`safe_unescape` replacement order** — backslash escapes were processed in wrong order; `\\n` in input would incorrectly become a newline instead of literal `\n`. Double-backslash replacement now runs first
- **Hardcoded `max_comments` ignored config** — `prepare_source_data` passed `max_comments=50` directly, ignoring `comments.max_count` from config
- **`view_count` dropped from source data** — `get_video_metadata` returned `view_count` but `prepare_source_data` didn't include it in the output JSON
- **Missing `encoding='utf-8'` in `convert_to_document`** — file reads/writes could break on systems where default encoding isn't UTF-8
- **Unhandled exception in `--generate-audio`** — if all TTS engines failed, raw traceback was shown instead of clean error message
- **`text=True` missing in `find_mlx_audio`** — subprocess calls were inconsistent with the rest of the codebase
- **yt-dlp `max_comments` format** — was passing 4 values (undocumented format); now uses correct 5-value format `COUNT,COUNT,0,0,1` per yt-dlp docs (`max-comments,max-parents,max-replies,max-replies-per-thread,max-depth`); `max-depth=1` fetches top-level comments only

### Security
- **XSS via HTML tag blocklist bypass** — dangerous tags like `<svg onload=...>`, `<img onerror=...>` bypassed the blocklist. Replaced with strict allowlist of safe tags and strips all `on*` event handler attributes
- **Protocol-relative URL bypass** — URLs like `//evil.com` started with `/` and passed link validation. Now explicitly blocked
- **TOCTOU race in queue operations** — concurrent processes could corrupt the queue. Fixed with atomic `_locked_queue()` context manager
- **`tarfile.extractall` without filter** — added `filter='data'` on Python 3.12+ for defense-in-depth against path traversal

### Other
- **`.gitignore`** — excludes `.DS_Store`, `__pycache__/`, `*.pyc`

### Benchmark (M1 Max, 2026-02-08)

| Text | PyTorch Gen | MLX Gen | Speedup |
|------|------------|---------|---------|
| Short (192 chars) | 2.35s | 0.76s | **3.1x** |
| Long (619 chars) | 8.20s | 2.05s | **4.0x** |

---

## [1.1.4] - 2026-02-08

### Fixed
- Wrapped long line in SKILL.md that caused horizontal scroll on ClawHub page

---

## [1.1.3] - 2026-02-08

### Fixed
- **YouTube URL normalization** — `/live/`, `/shorts/` and other non-standard URL formats now handled correctly
- **False-positive error detection** — error patterns only checked when command actually fails (was triggering on successful runs)
- **Queue file locking** — proper lock-before-open semantics with `os.open()` + `os.fdopen()` (prevents corruption)
- **Timezone comparison crash** — stale job detection now ensures timezone-aware datetime comparison
- **HTML link double-encoding** — URLs with `&` were getting double-escaped; links now extracted before HTML escaping
- **Built-in TTS for long text** — uses temp file to avoid CLI argument length limits with macOS `say`
- **HTML headings/tables** — now render bold, italic, and links correctly (was only escaping, not formatting)
- **Cleanup includes TTS temp files** — removes `_tts.py` alongside source JSON and output markdown

### Security
- **Zip-slip prevention** — validates zip/tar entries during pandoc/yt-dlp install to prevent path traversal attacks
- **Single-quote escaping** — added `'` → `&#39;` in HTML escape function
- **Sub-agent install guard** — SKILL.md now instructs sub-agents to never install software

### Changed
- **Kokoro voice blend from config** — reads voice blend dict + speed from `~/.tubescribe/config.json` instead of hardcoded values
- **Config uses nested keys throughout** — `config["audio"]["format"]` instead of flat `config["audio_format"]`
- **Renamed `config.set()` → `config.set_value()`** — avoids shadowing Python builtin
- **DRY: setup.py delegates to tubescribe.py** — imports `find_ytdlp`, `find_kokoro`, `KOKORO_DEPS` instead of duplicating
- **Uses `find_ytdlp()` helper** — multi-path search instead of raw `subprocess.run(["yt-dlp", ...])`
- **SKILL.md uses relative paths** — portable across installations
- **TTS respects config** — reads `tts_engine` setting (kokoro/builtin/disabled)
- **Better error for missing `say`** — FileNotFoundError with helpful message about Kokoro alternative
- **Removed `live_stream` error pattern** — was unreliable, caused false positives
- **Default Kokoro path** — updated to `~/.openclaw/tools/kokoro`

---

## [1.1.2] - 2026-02-06

### Fixed
- **Stale queue detection crash** — timezone-aware/naive datetime comparison caused TypeError, leaving queue permanently stuck
- **Config file corruption** — `_save_kokoro_cache()` was writing internal wrapper keys (`_raw`, flat keys) back to config.json
- **HTML table rendering** — all rows rendered as `<th>` headers; body rows now correctly use `<td>`
- **XSS vulnerability in HTML output** — paragraph text was not escaped before inline formatting; `<script>` tags could pass through
- **`--no-audio` CLI flag** — was defined but never wired up
- **Empty title filenames** — videos with empty titles produced `.docx` filename; now falls back to video ID
- **URL validation** — accepted any domain with `?v=` parameter; now validates YouTube domains only
- **Comment HTML double-wrapping** — `<p align="right">` tags got wrapped in another `<p>`; raw HTML now passes through
- **`safe_unescape()` fragility** — replaced encode/decode chain with `json.loads()` approach

### Removed
- **python-docx fallback** — was a half-broken DOCX generator; fallback chain is now pandoc → HTML (cleaner, better output)
- **`set_current()` dead code** — was never called; queue uses `pop_from_queue()` instead
- **`afconvert` dependency** — `say` now outputs WAV directly via `--data-format`; no intermediate AIFF conversion

### Changed
- **Built-in TTS** — simplified from `say` → AIFF → `afconvert` → WAV to just `say` → WAV directly
- **Timestamps** — replaced `subprocess.run(["date"])` with native `datetime.now().astimezone().isoformat()`
- **Queue file locking** — added `fcntl.flock()` advisory locking to prevent corruption from concurrent access
- **Config cleanup** — removed stale flat keys from config.json

### Added
- **HTML blockquotes** — `> text` lines now render as `<blockquote>` blocks
- **`sanitize_filename()` fallback parameter** — accepts video ID as fallback for empty titles

---

## [1.1.1] - 2026-02-06

- **Non-blocking async workflow** — Sub-agent handles entire pipeline (extract → process → DOCX → audio → cleanup)
- **Queue processing** — More robust handling of multiple videos
- **Comments section** — Viewer sentiment analysis and best comments

---

## [1.1.0] - 2026-02-06

### Changed
- **Comment sections renamed** — "Comment Summary" → "Viewer Sentiment", "Best Comments" reformatted with italic attribution
- **Bold headings** — Title and section headers use explicit bold (`# **Title**`) for consistent DOCX rendering

### Fixed
- Comment text and attribution were merging into single line in DOCX output

---

## [1.0.9] - 2026-02-06

### Added
- **YouTube comments** — Fetches top 50 comments, adds Comment Summary + Best Comments sections
- **yt-dlp support** — Auto-install to `~/.openclaw/tools/yt-dlp/` if not present
- **Progress feedback** — Clear step-by-step output with stages
- **Video metadata** — Channel name, upload date, and duration in output
- **Better error messages** — Human-readable errors for common issues:
  - Private videos, removed videos, no captions
  - Age-restricted, region-blocked, live streams
  - Invalid URLs, network errors, timeouts
- **CLI batch processing** — Process multiple URLs: `tubescribe url1 url2 url3`
- **Session queue** — Queue management for processing multiple videos:
  - `--queue-add URL` — Add to queue
  - `--queue-status` — Show current + queued items
  - `--queue-next` — Process next from queue
  - `--queue-clear` — Clear queue
- **Processing time estimates** — Shows estimated time based on word count

### Fixed
- **Code injection vulnerability** — Text now properly escaped with `json.dumps()`
- **Config schema compatibility** — Setup and runtime use same config format
- **Missing import** — Added `import json` for `--quiet --check-only` mode
- **Output directory default** — Now uses config value instead of current directory
- **Comment sorting** — Uses `comment_sort=top` to get highest-liked (not newest)
- **Unicode escape crash** — `safe_unescape()` handles edge cases in video descriptions
- **YouTube Shorts/Live URLs** — Now extracts video ID from `/shorts/` and `/live/` URLs

### New Config Options
- `comments.max_count` — Number of comments to fetch (default: 50)
- `comments.timeout` — Timeout for comment fetching (default: 90s)
- `queue.stale_minutes` — Consider processing stale after N minutes (default: 30)

### Output Format
- **Clickable URL** — Video URL in header is now a markdown link
- **Bold table headers** — Participants table uses `| **Name** | **Role** |`
- **Section separators** — `---` between all major sections
- **Best Comments** — Two-line format: comment text, then `   ▲ likes @Author`
- **Viewer Sentiment** — Flat section (not nested under "Comment Highlights")

### Changed
- **Metadata extraction** — Now uses `yt-dlp` if available (better data), falls back to HTML scraping
- **Transcript timeout** — Increased from 60s to 120s for long videos
- **SKILL.md output format** — Now includes video info block (channel, date, duration, URL)

## [1.0.8] - 2026-02-05

### Fixed
- Recovered from ClawHub publish disaster via `clawhub undelete`

## [1.0.7] - 2026-02-04

### Added
- Kokoro TTS integration with dynamic path detection
- Path caching for instant Kokoro startup (2.5s → 0.1ms)
- Smart dependency detection (system pip → known locations → fallback venv)
- Transcript segment merging in SKILL.md instructions

### Fixed
- MP3 output was using macOS `say` instead of Kokoro

## [1.0.0] - 2026-02-04

### Added
- Initial release
- YouTube transcript extraction via `summarize` CLI
- Sub-agent processing for speaker detection and summarization
- Document output (HTML, DOCX, Markdown)
- Audio summary generation (Kokoro TTS or macOS built-in)
- Setup wizard with dependency checking
