#!/usr/bin/env python3
"""
TubeScribe - YouTube Video Summarizer
=====================================

Extracts transcripts from YouTube videos, generates summaries with speaker
detection, and creates document + audio output.

Usage:
    python tubescribe.py <youtube_url> [options]
    python tubescribe.py url1 url2 url3  # Batch mode
    python tubescribe.py --queue-status  # Queue management

Options:
    --output-dir DIR     Output directory (default: from config)
    --doc-format FORMAT  Document format: html, docx, md
    --audio-format FMT   Audio format: wav, mp3, none
    --no-audio           Skip audio generation
    --quiet              Minimal output
    --queue-add URL      Add URL to processing queue
    --queue-status       Show queue status
    --queue-next         Process next item from queue
    --queue-clear        Clear the queue

Author: Jackie 🦊 & Matus 🇸🇰
"""

__version__ = "1.1.8"

import subprocess
import json
import re
import sys
import os
import tempfile
import time
import urllib.request
from contextlib import contextmanager
from pathlib import Path
from datetime import datetime, timedelta

try:
    import fcntl
    _HAS_FCNTL = True
except ImportError:
    _HAS_FCNTL = False

# Add scripts dir to path for imports
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

from html_writer import create_html_from_markdown
from config import load_config, save_config, CONFIG_FILE


def extract_video_id(url: str) -> str | None:
    """Extract video ID from various YouTube URL formats."""
    patterns = [
        r'(?:v=|/v/|youtu\.be/)([a-zA-Z0-9_-]{11})',
        r'(?:embed/)([a-zA-Z0-9_-]{11})',
        r'(?:shorts/)([a-zA-Z0-9_-]{11})',  # YouTube Shorts
        r'(?:live/)([a-zA-Z0-9_-]{11})',    # YouTube Live
        r'^([a-zA-Z0-9_-]{11})$'            # Just the ID
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def is_youtube_url(url: str) -> bool:
    """Check if URL is a valid YouTube URL with proper domain validation."""
    from urllib.parse import urlparse

    # First check if we can extract a video ID
    video_id = extract_video_id(url)
    if not video_id:
        return False

    # If it's just a bare video ID (11 chars), accept it
    if re.match(r'^[a-zA-Z0-9_-]{11}$', url):
        return True

    # Otherwise validate the domain using proper URL parsing
    valid_domains = {
        'youtube.com',
        'www.youtube.com',
        'm.youtube.com',
        'youtu.be',
        'music.youtube.com',
    }

    # Ensure URL has a scheme for proper parsing
    parse_url = url if url.startswith(('http://', 'https://')) else 'https://' + url
    parsed = urlparse(parse_url)
    hostname = (parsed.hostname or '').lower()

    return hostname in valid_domains


# Error patterns from summarize/yt-dlp
ERROR_PATTERNS = {
    "private": [
        "Private video",
        "Video is private",
        "Sign in if you've been granted access",
    ],
    "unavailable": [
        "Video unavailable",
        "This video isn't available",
        "removed by the uploader",
        "account associated with this video has been terminated",
    ],
    "no_captions": [
        "Subtitles are disabled",
        "no subtitles",
        "Could not retrieve",
        "No transcript",
    ],
    "age_restricted": [
        "Sign in to confirm your age",
        "age-restricted",
        "Age-restricted",
    ],
    "region_blocked": [
        "not available in your country",
        "geo-restricted",
        "blocked in your country",
    ],
}

ERROR_MESSAGES = {
    "private": "❌ Video is private — can't access",
    "unavailable": "❌ Video not found or removed",
    "no_captions": "❌ No captions available for this video",
    "age_restricted": "❌ Age-restricted video — can't access without login",
    "region_blocked": "❌ Video blocked in your region",
    "invalid_url": "❌ Not a valid YouTube URL",
    "network": "❌ Network error — check your connection",
    "timeout": "❌ Request timed out — try again later",
    "unknown": "❌ Failed to process video",
}


def detect_error(text: str) -> str | None:
    """Detect error type from output text."""
    text_lower = text.lower()
    for error_type, patterns in ERROR_PATTERNS.items():
        for pattern in patterns:
            if pattern.lower() in text_lower:
                return error_type
    return None


def find_ytdlp() -> str | None:
    """
    Find yt-dlp binary in common locations.
    Returns full path if found, None otherwise.
    
    Search order:
    1. System PATH (via shutil.which)
    2. Homebrew locations (/opt/homebrew, /usr/local)
    3. pip/pipx user installs (~/.local/bin)
    4. Our tools directory (~/.openclaw/tools/yt-dlp)
    """
    import shutil
    
    # Check system PATH first
    system_ytdlp = shutil.which("yt-dlp")
    if system_ytdlp:
        return system_ytdlp
    
    # Common installation paths
    paths = [
        "/opt/homebrew/bin/yt-dlp",           # Homebrew (Apple Silicon)
        "/usr/local/bin/yt-dlp",              # Homebrew (Intel) / Linux
        "/usr/bin/yt-dlp",                    # System (Linux)
        os.path.expanduser("~/.local/bin/yt-dlp"),  # pip install --user
        os.path.expanduser("~/.local/pipx/venvs/yt-dlp/bin/yt-dlp"),  # pipx
        os.path.expanduser("~/.openclaw/tools/yt-dlp/yt-dlp"),  # Our tools
    ]
    
    for path in paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path
    
    return None


def fetch_comments(url: str, max_comments: int = None, timeout: int = None, config: dict = None) -> tuple[list[dict] | None, str | None]:
    """
    Fetch top comments from YouTube video.
    Returns (comments_list, error_message).
    Uses config values for max_comments and timeout if not specified.
    """
    ytdlp = find_ytdlp()
    if not ytdlp:
        return None, None  # No yt-dlp, skip comments silently

    # Get from config if not specified
    if config is None:
        config = load_config()
    if max_comments is None:
        max_comments = config.get("comments", {}).get("max_count", 50)
    if timeout is None:
        timeout = config.get("comments", {}).get("timeout", 90)
    
    try:
        # comment_sort=top gets highest-liked comments (default is "new")
        # Format: max_comments=max-comments,max-parents,max-replies,max-replies-per-thread,max-depth
        # We fetch top-level parent comments only: depth=1, no replies
        result = subprocess.run(
            [ytdlp, "--dump-json", "--no-download", "--write-comments", 
             "--extractor-args", f"youtube:comment_sort=top;max_comments={max_comments},{max_comments},0,0,1",
             url],
            capture_output=True, text=True, timeout=timeout
        )
        
        if result.returncode != 0:
            return None, None  # Failed, skip comments silently
        
        data = json.loads(result.stdout)
        raw_comments = data.get("comments", [])
        
        if not raw_comments:
            return [], None
        
        # Sort by likes and extract relevant fields
        comments = []
        for c in raw_comments:
            comments.append({
                "author": c.get("author", "Unknown"),
                "text": c.get("text", ""),
                "likes": c.get("like_count", 0),
                "time": c.get("timestamp", 0),
                "time_text": c.get("time_text", ""),
            })
        
        # Sort by likes descending
        comments.sort(key=lambda x: x["likes"], reverse=True)
        
        return comments[:max_comments], None
        
    except subprocess.TimeoutExpired:
        return None, None  # Timeout, skip comments
    except json.JSONDecodeError:
        return None, None  # Invalid JSON, skip comments
    except Exception:
        return None, None  # Any error, skip comments


MAX_HTML_SIZE = 5 * 1024 * 1024  # 5MB limit for safety


def format_duration(seconds: int) -> str:
    """Format seconds as H:MM:SS or M:SS."""
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    if hours > 0:
        return f"{hours}:{minutes:02d}:{secs:02d}"
    return f"{minutes}:{secs:02d}"


def safe_unescape(text: str) -> str:
    """Safely decode unicode escapes, handling edge cases."""
    if not text:
        return text
    try:
        # Use json.loads to properly decode JSON string escapes
        return json.loads(f'"{text}"')
    except (json.JSONDecodeError, ValueError):
        # Fallback: just handle the common ones manually
        text = text.replace('\\\\', '\\')
        text = text.replace('\\n', '\n')
        text = text.replace('\\t', '\t')
        text = text.replace('\\"', '"')
        return text


def get_video_metadata(url: str) -> tuple[dict | None, str | None]:
    """
    Extract video metadata from YouTube.
    Returns (metadata_dict, error_message).
    Uses yt-dlp if available, falls back to HTML scraping.
    """
    video_id = extract_video_id(url)
    
    # Try yt-dlp first (best metadata)
    ytdlp = find_ytdlp()
    if ytdlp:
        try:
            result = subprocess.run(
                [ytdlp, "--dump-json", "--no-download", "--no-warnings", url],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                data = json.loads(result.stdout)
                return {
                    "title": data.get("title", "Unknown"),
                    "channel": data.get("channel", data.get("uploader", "Unknown")),
                    "upload_date": data.get("upload_date", ""),  # YYYYMMDD format
                    "duration": data.get("duration", 0),
                    "duration_string": format_duration(data.get("duration", 0)),
                    "view_count": data.get("view_count", 0),
                    "description": data.get("description", ""),
                    "video_id": video_id,
                }, None
            else:
                # Check for known errors
                error_type = detect_error(result.stderr)
                if error_type:
                    return None, ERROR_MESSAGES[error_type]
        except subprocess.TimeoutExpired:
            return None, ERROR_MESSAGES["timeout"]
        except json.JSONDecodeError:
            pass  # Invalid JSON, fall back to HTML
    
    # Fallback: HTML scraping
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=15) as response:
            html = response.read(MAX_HTML_SIZE).decode('utf-8')
        
        # Check for error pages
        error_type = detect_error(html)
        if error_type:
            return None, ERROR_MESSAGES[error_type]
        
        # Extract metadata from JSON in HTML
        title_match = re.search(r'"title":"([^"]+)"', html)
        title = safe_unescape(title_match.group(1)) if title_match else "Unknown"
        
        channel_match = re.search(r'"ownerChannelName":"([^"]+)"', html)
        channel = safe_unescape(channel_match.group(1)) if channel_match else "Unknown"
        
        # Duration in seconds
        duration_match = re.search(r'"lengthSeconds":"(\d+)"', html)
        duration = int(duration_match.group(1)) if duration_match else 0
        
        # Upload date
        date_match = re.search(r'"uploadDate":"([^"]+)"', html)
        upload_date = date_match.group(1) if date_match else ""
        
        desc_match = re.search(r'"shortDescription":"([^"]*)"', html)
        description = safe_unescape(desc_match.group(1)) if desc_match else ""
        
        return {
            "title": title,
            "channel": channel,
            "upload_date": upload_date,
            "duration": duration,
            "duration_string": format_duration(duration),
            "view_count": 0,  # Not easily available from HTML
            "description": description,
            "video_id": video_id,
        }, None
        
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None, ERROR_MESSAGES["unavailable"]
        return None, ERROR_MESSAGES["unknown"]
    except urllib.error.URLError:
        return None, ERROR_MESSAGES["network"]
    except TimeoutError:
        return None, ERROR_MESSAGES["timeout"]
    except Exception as e:
        return None, f"❌ Failed to fetch metadata: {e}"


def normalize_youtube_url(url: str) -> str:
    """Normalize any YouTube URL format to standard watch?v= format."""
    video_id = extract_video_id(url)
    if video_id:
        return f"https://www.youtube.com/watch?v={video_id}"
    return url


def download_transcript(url: str) -> tuple[list[dict] | None, str | None]:
    """
    Download transcript with timestamps using summarize CLI.
    Returns (segments, error_message).
    """
    # Normalize URL to standard format (fixes /live/, /shorts/, etc.)
    normalized_url = normalize_youtube_url(url)
    try:
        result = subprocess.run(
            ["summarize", normalized_url, "--youtube", "auto", "--extract-only", "--timestamps"],
            capture_output=True, text=True, timeout=120  # 2 min timeout for long videos
        )
        
        if result.returncode != 0:
            # Only check error patterns when the command actually failed
            combined_output = result.stdout + result.stderr
            error_type = detect_error(combined_output)
            if error_type:
                return None, ERROR_MESSAGES[error_type]
            return None, f"❌ Transcript extraction failed: {result.stderr[:200]}"
        
        lines = result.stdout.strip().split('\n')
        segments = []
        
        for line in lines:
            match = re.match(r'\[(\d+:\d+(?::\d+)?)\]\s*(.*)', line)
            if match:
                segments.append({
                    "ts": match.group(1),
                    "text": match.group(2).strip()
                })
        
        if not segments:
            return None, ERROR_MESSAGES["no_captions"]
        
        return segments, None
        
    except FileNotFoundError:
        return None, "❌ 'summarize' CLI not found. Install with: brew install steipete/tap/summarize"
    except subprocess.TimeoutExpired:
        return None, ERROR_MESSAGES["timeout"]


def clean_transcript(segments: list[dict]) -> list[dict]:
    """Clean transcript segments."""
    cleaned = []
    for seg in segments:
        text = seg["text"]
        text = re.sub(r'\s+', ' ', text).strip()
        text = re.sub(r'>>\s*', '', text)  # Remove >> artifacts
        if text:
            cleaned.append({"ts": seg["ts"], "text": text})
    return cleaned


def sanitize_filename(title: str, fallback: str = "untitled") -> str:
    """Create safe filename from title. Uses fallback if result is empty."""
    safe = re.sub(r'[<>:"/\\|?*]', '', title)
    safe = re.sub(r'\s+', ' ', safe).strip()
    safe = safe[:100]  # Limit length
    return safe if safe else fallback


def _get_temp_dir() -> str:
    """Get a secure per-user temp directory for TubeScribe."""
    try:
        uid = os.getuid()
    except AttributeError:
        uid = os.getenv("USERNAME", "default")
    temp_dir = os.path.join(tempfile.gettempdir(), f"tubescribe-{uid}")
    os.makedirs(temp_dir, mode=0o700, exist_ok=True)
    return temp_dir


def prepare_source_data(url: str, temp_dir: str = None, quiet: bool = False) -> tuple[str | None, str | None, str | None]:
    """
    Prepare source data for processing.
    Returns: (source_json_path, output_md_path, error_message)
    """
    if temp_dir is None:
        temp_dir = _get_temp_dir()

    def log(msg: str):
        if not quiet:
            print(msg)

    # Validate URL first
    if not is_youtube_url(url):
        return None, None, ERROR_MESSAGES["invalid_url"]
    
    video_id = extract_video_id(url)

    timings = {}
    
    log(f"\n🎬 TubeScribe")
    log(f"{'─' * 50}")
    
    # Check if yt-dlp available for comments (always fetch if available)
    has_ytdlp = find_ytdlp() is not None
    total_steps = 4 if has_ytdlp else 3
    step = 0
    
    # Step 1: Fetch metadata
    step += 1
    log(f"\n[{step}/{total_steps}] 🔍 Fetching video metadata...")
    t_start = time.time()
    metadata, error = get_video_metadata(url)
    timings['metadata'] = time.time() - t_start
    if error:
        return None, None, error
    
    title_display = metadata['title'][:50] + "..." if len(metadata['title']) > 50 else metadata['title']
    log(f"      → \"{title_display}\"")
    log(f"      → {metadata['channel']} • {metadata['duration_string']}")
    log(f"      ⏱️ {timings['metadata']:.1f}s")
    
    # Step 2: Download transcript
    step += 1
    log(f"\n[{step}/{total_steps}] 📝 Extracting transcript...")
    t_start = time.time()
    segments, error = download_transcript(url)
    timings['transcript'] = time.time() - t_start
    if error:
        return None, None, error
    
    log(f"      → {len(segments)} raw segments")
    log(f"      ⏱️ {timings['transcript']:.1f}s")
    
    # Step 3: Clean transcript
    step += 1
    log(f"\n[{step}/{total_steps}] 🧹 Cleaning transcript...")
    t_start = time.time()
    segments = clean_transcript(segments)
    timings['cleaning'] = time.time() - t_start
    word_count = sum(len(s["text"].split()) for s in segments)
    
    log(f"      → {len(segments)} segments")
    log(f"      → ~{word_count:,} words")
    log(f"      ⏱️ {timings['cleaning']:.1f}s")
    
    # Estimate processing time
    if word_count < 3000:
        est_time = "2-4 minutes"
    elif word_count < 10000:
        est_time = "5-8 minutes"
    else:
        est_time = "10-15 minutes"
    log(f"      → Est. processing: {est_time}")
    
    # Step 4: Fetch comments (optional)
    comments = []
    if has_ytdlp:
        step += 1
        log(f"\n[{step}/{total_steps}] 💬 Fetching comments...")
        t_start = time.time()
        cfg = load_config()
        max_comments_count = cfg.get("comments", {}).get("max_count", 50)
        comments, _ = fetch_comments(url, max_comments=max_comments_count, config=cfg)
        timings['comments'] = time.time() - t_start
        if comments:
            log(f"      → {len(comments)} top comments")
        else:
            log(f"      → No comments available")
        log(f"      ⏱️ {timings['comments']:.1f}s")
    
    # Prepare output with full metadata
    source_data = {
        "metadata": {
            "url": url,
            "video_id": video_id,
            "title": metadata["title"],
            "channel": metadata["channel"],
            "upload_date": metadata["upload_date"],
            "duration": metadata["duration"],
            "duration_string": metadata["duration_string"],
            "view_count": metadata.get("view_count", 0),
            "description": metadata["description"],
        },
        "segments": segments,
        "comments": comments if comments else [],
        "stats": {
            "segment_count": len(segments),
            "word_count": word_count,
            "comment_count": len(comments) if comments else 0,
        }
    }
    
    source_path = f"{temp_dir}/tubescribe_{video_id}_source.json"
    output_path = f"{temp_dir}/tubescribe_{video_id}_output.md"
    
    with open(source_path, 'w', encoding='utf-8') as f:
        json.dump(source_data, f, indent=2, ensure_ascii=False)
    
    log(f"\n{'─' * 50}")
    log(f"✅ Ready for processing")
    log(f"   Source: {source_path}")
    log(f"   Output: {output_path}")
    
    # Timing summary
    total_extract = sum(timings.values())
    log(f"\n⏱️ Extraction timing:")
    log(f"   Metadata:   {timings.get('metadata', 0):.1f}s")
    log(f"   Transcript: {timings.get('transcript', 0):.1f}s")
    log(f"   Cleaning:   {timings.get('cleaning', 0):.1f}s")
    if 'comments' in timings:
        log(f"   Comments:   {timings['comments']:.1f}s")
    log(f"   Total:      {total_extract:.1f}s")
    
    return source_path, output_path, None


def cleanup_temp_files(video_id: str, quiet: bool = False, temp_dir: str = None) -> bool:
    """Remove temp files for a video after successful processing."""
    if temp_dir is None:
        temp_dir = _get_temp_dir()
    source_path = f"{temp_dir}/tubescribe_{video_id}_source.json"
    output_path = f"{temp_dir}/tubescribe_{video_id}_output.md"
    tts_path = f"{temp_dir}/tubescribe_{video_id}_tts.py"

    cleaned = False
    for path in [source_path, output_path, tts_path]:
        if os.path.exists(path):
            os.remove(path)
            cleaned = True
            if not quiet:
                print(f"   🗑️  Removed {path}")
    
    return cleaned


def convert_to_document(md_path: str, output_dir: str, doc_format: str, video_id: str = None) -> str:
    """Convert markdown to final document format."""
    
    # Get title from markdown for filename
    with open(md_path, 'r', encoding='utf-8') as f:
        content = f.read()
    title_match = re.search(r'^# (.+)$', content, re.MULTILINE)
    title = title_match.group(1) if title_match else "TubeScribe Output"
    fallback = video_id if video_id else "TubeScribe_Output"
    safe_title = sanitize_filename(title, fallback=fallback)
    
    if doc_format == "md":
        # Just copy/rename markdown
        out_path = os.path.join(output_dir, f"{safe_title}.md")
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return out_path
    
    elif doc_format == "html":
        out_path = os.path.join(output_dir, f"{safe_title}.html")
        create_html_from_markdown(md_path, out_path)
        return out_path
    
    elif doc_format == "docx":
        out_path = os.path.join(output_dir, f"{safe_title}.docx")
        # Try pandoc first (system or tools)
        pandoc_paths = [
            "pandoc",  # System PATH
            os.path.expanduser("~/.openclaw/tools/pandoc/pandoc"),  # Our tools
        ]
        for pandoc in pandoc_paths:
            try:
                subprocess.run(
                    [pandoc, md_path, "-o", out_path],
                    check=True, capture_output=True
                )
                return out_path
            except FileNotFoundError:
                continue
        
        # No pandoc available, fall back to HTML
        print("   pandoc not found, falling back to HTML")
        out_path = os.path.join(output_dir, f"{safe_title}.html")
        create_html_from_markdown(md_path, out_path)
        return out_path

    else:
        print(f"   Unknown document format '{doc_format}', falling back to markdown")
        out_path = os.path.join(output_dir, f"{safe_title}.md")
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return out_path


def generate_audio_summary(summary_text: str, output_path: str, config: dict) -> str:
    """Generate audio summary using configured TTS engine."""

    audio_format = config.get("audio", {}).get("format", "wav")
    tts_engine = config.get("audio", {}).get("tts_engine", "builtin")

    print(f"🔊 Generating audio ({tts_engine}, {audio_format})...")

    if tts_engine == "mlx":
        return generate_mlx_audio(summary_text, output_path, audio_format, config)
    elif tts_engine == "kokoro":
        return generate_kokoro_audio(summary_text, output_path, audio_format, config)
    else:
        return generate_builtin_audio(summary_text, output_path, audio_format)


def find_mlx_audio(config: dict = None) -> tuple[str | None, str | None]:
    """
    Find mlx-audio installation.
    Returns (python_path, mlx_audio_dir).
    """
    if config is None:
        config = load_config()
    
    mlx_config = config.get("mlx_audio", {})
    mlx_dir = os.path.expanduser(mlx_config.get("path", "~/.openclaw/tools/mlx-audio"))
    
    # Check venv inside mlx-audio dir
    venv_python = os.path.join(mlx_dir, ".venv", "bin", "python3")
    if os.path.exists(venv_python):
        try:
            result = subprocess.run(
                [venv_python, "-c", "from mlx_audio.tts.generate import generate_audio; print('ok')"],
                capture_output=True, text=True, timeout=15
            )
            if result.returncode == 0:
                return venv_python, mlx_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    
    # Check system Python
    import shutil
    system_python = shutil.which("python3")
    if system_python:
        try:
            result = subprocess.run(
                [system_python, "-c", "from mlx_audio.tts.generate import generate_audio; print('ok')"],
                capture_output=True, text=True, timeout=15
            )
            if result.returncode == 0:
                return system_python, mlx_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    
    return None, None


def _get_or_create_mlx_blended_voice(mlx_python: str, voice_blend: dict, model: str) -> str | None:
    """
    Create a blended voice .safetensors file from multiple voices with custom weights.
    Caches the result so it only runs once.
    Returns path to the blended .safetensors file, or None on failure.
    """
    # Build a deterministic filename from the blend spec
    parts = sorted(voice_blend.items())
    blend_name = "_".join(f"{re.sub(r'[^a-z0-9_]', '', name)}_{int(weight*100)}" for name, weight in parts)
    if not blend_name:
        return None
    safe_blend_name = json.dumps(blend_name)
    
    # Check if blend already exists in HF cache
    code = f'''
import json
from huggingface_hub import snapshot_download
from pathlib import Path

local_dir = snapshot_download(repo_id={json.dumps(model)}, local_files_only=True)
blend_path = str(Path(local_dir) / "voices" / ({safe_blend_name} + ".safetensors"))

import os
if os.path.exists(blend_path):
    print(blend_path)
else:
    print("NEEDS_CREATE")
    print(local_dir)
'''
    try:
        result = subprocess.run(
            [mlx_python, "-c", code],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0:
            return None
        
        lines = result.stdout.strip().split('\n')
        if lines[0] != "NEEDS_CREATE":
            return lines[0]  # Already exists
        
        local_dir = lines[1]
    except (subprocess.SubprocessError, OSError, TimeoutError):
        return None
    
    # Create the blended voice
    blend_spec = json.dumps(voice_blend)
    code = f'''
import json
import numpy as np
import mlx.core as mx
from mlx_audio.tts.models.kokoro.voice import load_voice_tensor
from safetensors.numpy import save_file

local_dir = {json.dumps(local_dir)}
voice_blend = json.loads({json.dumps(blend_spec)})
blend_name = {safe_blend_name}

# Load and blend voices
voices = []
weights = []
for name, weight in voice_blend.items():
    v = load_voice_tensor(f"{{local_dir}}/voices/{{name}}.safetensors")
    voices.append(v)
    weights.append(weight)

blended = sum(w * v for w, v in zip(weights, voices))
blend_path = f"{{local_dir}}/voices/{{blend_name}}.safetensors"
save_file({{"voice": np.array(blended)}}, blend_path)
print(blend_path)
'''
    try:
        result = subprocess.run(
            [mlx_python, "-c", code],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.SubprocessError, OSError, TimeoutError):
        pass
    
    return None


def generate_mlx_audio(text: str, output_path: str, audio_format: str, config: dict) -> str:
    """Generate audio using mlx-audio (MLX backend for Kokoro — fastest on Apple Silicon)."""
    try:
        wav_path = output_path.replace('.mp3', '.wav') if output_path.endswith('.mp3') else output_path
        if not wav_path.endswith('.wav'):
            wav_path = output_path + '.wav'

        mlx_python, mlx_dir = find_mlx_audio(config)
        if not mlx_python:
            raise Exception("mlx-audio not found. Falling back to Kokoro PyTorch.")

        mlx_config = config.get("mlx_audio", {})
        model = mlx_config.get("model", "mlx-community/Kokoro-82M-bf16")
        voice = mlx_config.get("voice", "af_heart")
        voice_blend = mlx_config.get("voice_blend", {})
        lang_code = mlx_config.get("lang_code", "a")
        speed = mlx_config.get("speed", 1.0)

        # If voice_blend is configured, create/load blended voice
        if voice_blend and len(voice_blend) > 1:
            blended_path = _get_or_create_mlx_blended_voice(mlx_python, voice_blend, model)
            if blended_path:
                voice = blended_path

        safe_text = json.dumps(text)
        safe_wav_path = json.dumps(wav_path)

        code = f'''
import os
from mlx_audio.tts.generate import generate_audio

text = {safe_text}
wav_path = {safe_wav_path}
output_dir = os.path.dirname(wav_path)
file_prefix = os.path.splitext(os.path.basename(wav_path))[0]

generate_audio(
    text=text,
    model={json.dumps(model)},
    voice={json.dumps(voice)},
    lang_code={json.dumps(lang_code)},
    speed={json.dumps(speed)},
    output_path=output_dir,
    file_prefix=file_prefix,
    audio_format="wav",
    join_audio=True,
    verbose=False,
)
print("OK")
'''
        result = subprocess.run(
            [mlx_python, "-c", code],
            capture_output=True, text=True, timeout=300
        )

        if result.returncode == 0 and os.path.exists(wav_path):
            if audio_format == "mp3":
                base = output_path[:-4] if output_path.endswith(('.mp3', '.wav')) else output_path
                mp3_path = base + '.mp3'
                subprocess.run(
                    ["ffmpeg", "-y", "-i", wav_path, "-b:a", "128k", mp3_path],
                    capture_output=True, check=True
                )
                os.remove(wav_path)
                return mp3_path
            return wav_path
        else:
            raise Exception(f"mlx-audio failed: {result.stderr[:300]}")

    except Exception as e:
        print(f"   mlx-audio failed, falling back to Kokoro PyTorch: {e}")
        return generate_kokoro_audio(text, output_path, audio_format, config)


KOKORO_DEPS = {
    "torch": "torch",
    "soundfile": "soundfile",
    "numpy": "numpy",
    "huggingface_hub": "huggingface_hub",
}


def _check_python_has_deps(python_path: str) -> bool:
    """Check if a Python has all required ML deps."""
    import_names = ", ".join(KOKORO_DEPS.values())
    try:
        result = subprocess.run(
            [python_path, "-c", f"import {import_names}"],
            capture_output=True, timeout=10
        )
        return result.returncode == 0
    except (subprocess.SubprocessError, OSError, TimeoutError):
        return False


def find_kokoro(use_cache: bool = True, config: dict = None) -> tuple[str | None, str | None]:
    """
    Find Kokoro installation efficiently.
    Returns (python_path, kokoro_dir).
    
    Checks (in order):
    1. Config cache (instant)
    2. Venv at ~/.openclaw/tools/kokoro/.venv (pip install)
    3. System Python with kokoro importable
    4. Legacy locations (cloned repos)
    """
    if config is None:
        config = load_config()
    kokoro_dir = os.path.expanduser("~/.openclaw/tools/kokoro")
    
    # 1. Check cache first (instant)
    if use_cache:
        cached = config.get("kokoro", {})
        cached_python = cached.get("python")
        cached_dir = cached.get("path")
        
        if cached_python and cached_dir:
            if cached_python == "system":
                cached_python = sys.executable
            if os.path.exists(cached_python):
                return cached_python, cached_dir
    
    # 2. Check venv at standard location (clean pip install)
    venv_python = os.path.join(kokoro_dir, ".venv", "bin", "python3")
    if os.path.exists(venv_python):
        try:
            result = subprocess.run(
                [venv_python, "-c", "from kokoro import KPipeline; print('ok')"],
                capture_output=True, timeout=10
            )
            if result.returncode == 0:
                _save_kokoro_cache(venv_python, kokoro_dir, "venv")
                return venv_python, kokoro_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    
    # 3. Check system Python
    if _check_python_has_deps(sys.executable):
        try:
            result = subprocess.run(
                [sys.executable, "-c", "from kokoro import KPipeline; print('ok')"],
                capture_output=True, timeout=10
            )
            if result.returncode == 0:
                _save_kokoro_cache(sys.executable, kokoro_dir, "system")
                return sys.executable, kokoro_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    
    # 4. Legacy: check old locations (cloned repos, shared ML env)
    legacy_locations = [
        kokoro_dir,
        "/tmp/kokoro-coreml",
        os.path.expanduser("~/kokoro-coreml"),
        os.path.expanduser("~/.local/share/kokoro"),
    ]
    ml_env_python = os.path.expanduser("~/.openclaw/tools/ml-env/bin/python")
    
    for loc in legacy_locations:
        if not os.path.exists(loc):
            continue
        for python_path, source in [(ml_env_python, "ml-env"), (sys.executable, "system")]:
            if not os.path.exists(python_path):
                continue
            try:
                result = subprocess.run(
                    [python_path, "-c", "from kokoro import KPipeline; print('ok')"],
                    capture_output=True, timeout=10, cwd=loc
                )
                if result.returncode == 0:
                    _save_kokoro_cache(python_path, loc, source)
                    return python_path, loc
            except (subprocess.SubprocessError, OSError, TimeoutError):
                pass
    
    return None, None


def _save_kokoro_cache(python_path: str, kokoro_dir: str, source: str):
    """Cache found Kokoro setup."""
    try:
        config = load_config()
        if "kokoro" not in config:
            config["kokoro"] = {}
        config["kokoro"]["python"] = "system" if source == "system" else python_path
        config["kokoro"]["path"] = kokoro_dir
        config["kokoro"]["source"] = source
        save_config(config)
    except (IOError, KeyError, TypeError):
        pass  # Non-critical: cache save failed, will retry next time


def generate_kokoro_audio(text: str, output_path: str, audio_format: str, config: dict) -> str:
    """Generate audio using Kokoro TTS."""
    try:
        wav_path = output_path.replace('.mp3', '.wav') if output_path.endswith('.mp3') else output_path
        if not wav_path.endswith('.wav'):
            wav_path = output_path + '.wav'

        # Find Kokoro installation
        kokoro_python, kokoro_dir = find_kokoro()

        if not kokoro_python:
            raise Exception("Kokoro not found. Run: python setup.py")

        # Read voice blend and speed from config
        kokoro_config = config.get("kokoro", {})
        voice_blend = kokoro_config.get("voice_blend", {"af_heart": 0.6, "af_sky": 0.4})
        speed = kokoro_config.get("speed", 1.05)

        # Safely escape values for Python string using json.dumps
        safe_text = json.dumps(text)
        safe_wav_path = json.dumps(wav_path)
        safe_voice_blend = json.dumps(voice_blend)
        safe_speed = json.dumps(speed)

        code = f'''
from kokoro import KPipeline
import soundfile as sf
import torch
import numpy as np
import os
import json

pipeline = KPipeline(lang_code='a')

voice_blend = json.loads({safe_voice_blend!r})
speed = {safe_speed}

# Try to load custom voice blend, fall back to default
try:
    cache_dir = os.path.expanduser('~/.cache/huggingface/hub/models--hexgrad--Kokoro-82M/snapshots')
    snapshot = os.listdir(cache_dir)[0]
    voices_dir = os.path.join(cache_dir, snapshot, 'voices')
    voices = {{}}
    for name in voice_blend:
        voices[name] = torch.load(os.path.join(voices_dir, f'{{name}}.pt'), weights_only=True)
    voice = sum(weight * voices[name] for name, weight in voice_blend.items())
except Exception:
    voice = list(voice_blend.keys())[0] if voice_blend else 'af_heart'

text = {safe_text}
wav_path = {safe_wav_path}
audio_chunks = []
for _, _, audio in pipeline(text, voice=voice, speed=speed):
    audio_chunks.append(audio)
full_audio = np.concatenate(audio_chunks)
sf.write(wav_path, full_audio, 24000)
print("OK")
'''
        # Run from kokoro directory so local module is found
        # cwd=kokoro_dir for legacy cloned repos where kokoro is a local module
        run_kwargs = {"capture_output": True, "text": True, "timeout": 300}
        if os.path.exists(os.path.join(kokoro_dir, "kokoro", "__init__.py")):
            run_kwargs["cwd"] = kokoro_dir
        result = subprocess.run([kokoro_python, "-c", code], **run_kwargs)

        if result.returncode == 0 and os.path.exists(wav_path):
            if audio_format == "mp3":
                base = output_path[:-4] if output_path.endswith(('.mp3', '.wav')) else output_path
                mp3_path = base + '.mp3'
                subprocess.run(["ffmpeg", "-y", "-i", wav_path, "-b:a", "128k", mp3_path],
                             capture_output=True, check=True)
                os.remove(wav_path)
                return mp3_path
            return wav_path
        else:
            raise Exception(f"Kokoro failed: {result.stderr}")

    except Exception as e:
        print(f"   Kokoro failed, falling back to built-in TTS: {e}")
        return generate_builtin_audio(text, output_path, audio_format)


def generate_builtin_audio(text: str, output_path: str, audio_format: str) -> str:
    """Generate audio using macOS say command (fallback)."""
    wav_path = output_path.replace('.mp3', '.wav') if output_path.endswith('.mp3') else output_path
    if not wav_path.endswith('.wav'):
        wav_path = output_path + '.wav'

    # Write text to temp file to avoid CLI argument length limits
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as tf:
        tf.write(text)
        text_file = tf.name
    try:
        subprocess.run(["say", "-o", wav_path, "--data-format=LEI16@22050", "-f", text_file],
                      check=True, capture_output=True)
    except FileNotFoundError:
        os.remove(text_file)
        raise FileNotFoundError(
            "macOS 'say' command not found. Built-in TTS is only available on macOS. "
            "Install Kokoro TTS for cross-platform support: python setup.py"
        )
    finally:
        if os.path.exists(text_file):
            os.remove(text_file)

    if audio_format == "mp3":
        base = output_path[:-4] if output_path.endswith(('.mp3', '.wav')) else output_path
        mp3_path = base + '.mp3'
        try:
            subprocess.run(["ffmpeg", "-y", "-i", wav_path, "-b:a", "128k", mp3_path],
                         capture_output=True, check=True)
            os.remove(wav_path)
            return mp3_path
        except FileNotFoundError:
            print("   ffmpeg not found, keeping wav format")
            return wav_path

    return wav_path


def process_single_url(url: str, config: dict, quiet: bool = False) -> tuple[str | None, str | None, str | None]:
    """
    Process a single URL.
    Returns: (source_path, output_path, error_message)
    Temp files go to /tmp, final output uses config folder.
    """
    source_path, output_path, error = prepare_source_data(url, _get_temp_dir(), quiet)
    
    if error:
        if not quiet:
            print(f"\n{error}")
        return None, None, error
    
    return source_path, output_path, None


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="TubeScribe - YouTube Video Summarizer",
        epilog="Examples:\n"
               "  tubescribe https://youtube.com/watch?v=xxx\n"
               "  tubescribe url1 url2 url3  # Batch processing\n"
               "  tubescribe --queue-status  # Check queue\n",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--version", action="version", version=f"TubeScribe {__version__}")
    parser.add_argument("urls", nargs="*", help="YouTube URL(s)")
    parser.add_argument("--output-dir", default=None, help="Output directory (default: from config)")
    parser.add_argument("--doc-format", choices=["html", "docx", "md"], help="Document format")
    parser.add_argument("--audio-format", choices=["wav", "mp3", "none"], help="Audio format")
    parser.add_argument("--no-audio", action="store_true", help="Skip audio generation")
    parser.add_argument("--quiet", action="store_true", help="Minimal output")
    # Queue management
    parser.add_argument("--queue-add", metavar="URL", help="Add URL to queue")
    parser.add_argument("--queue-status", action="store_true", help="Show queue status")
    parser.add_argument("--queue-clear", action="store_true", help="Clear the queue")
    parser.add_argument("--queue-next", action="store_true", help="Process next item in queue")
    # Cleanup
    parser.add_argument("--cleanup", metavar="VIDEO_ID", help="Remove temp files for video ID")
    # Audio generation from text
    parser.add_argument("--generate-audio", metavar="TEXT_FILE", help="Generate audio from a text file (reads file, uses TTS config)")
    parser.add_argument("--audio-output", metavar="PATH", help="Output path for generated audio (used with --generate-audio)")
    
    args = parser.parse_args()
    
    config = load_config()
    
    # Override config with args
    if args.doc_format:
        config["document"]["format"] = args.doc_format
    if args.audio_format:
        config["audio"]["format"] = args.audio_format
    if args.no_audio:
        config["audio"]["enabled"] = False

    # Use config output folder if not specified
    output_dir = args.output_dir or os.path.expanduser(config.get("output", {}).get("folder", "~/Documents/TubeScribe"))
    os.makedirs(output_dir, exist_ok=True)
    
    # Audio generation from text file
    if args.generate_audio:
        text_file = args.generate_audio
        if not os.path.exists(text_file):
            print(f"❌ File not found: {text_file}")
            sys.exit(1)
        with open(text_file, 'r') as f:
            text = f.read().strip()
        if not text:
            print(f"❌ File is empty: {text_file}")
            sys.exit(1)
        audio_output = args.audio_output or os.path.join(output_dir, "summary")
        try:
            result = generate_audio_summary(text, audio_output, config)
        except Exception as e:
            print(f"❌ Audio generation failed: {e}")
            sys.exit(1)
        if result:
            print(f"✅ Audio: {result}")
        else:
            print("❌ Audio generation failed")
            sys.exit(1)
        return

    # Cleanup operation
    if args.cleanup:
        if cleanup_temp_files(args.cleanup, args.quiet):
            print(f"✅ Cleaned up temp files for {args.cleanup}")
        else:
            print(f"ℹ️  No temp files found for {args.cleanup}")
        return
    
    # Queue operations
    if args.queue_status:
        show_queue_status()
        return
    if args.queue_clear:
        clear_queue()
        return
    if args.queue_add:
        add_to_queue(args.queue_add)
        return
    if args.queue_next:
        url = pop_from_queue()
        if url:
            args.urls = [url]
        else:
            print("📋 Queue is empty")
            return
    
    # Need at least one URL
    if not args.urls:
        parser.print_help()
        return
    
    # Process URLs
    results = []
    for i, url in enumerate(args.urls):
        if len(args.urls) > 1:
            print(f"\n{'═' * 50}")
            print(f"📹 Video {i+1}/{len(args.urls)}")
            print(f"{'═' * 50}")
        
        source_path, output_path, error = process_single_url(
            url, config, args.quiet
        )
        
        if error:
            results.append({"url": url, "error": error})
        else:
            results.append({"url": url, "source": source_path, "output": output_path})
    
    # Summary for batch
    if len(args.urls) > 1:
        print(f"\n{'═' * 50}")
        print(f"📊 Batch Summary")
        print(f"{'═' * 50}")
        success = [r for r in results if "source" in r]
        failed = [r for r in results if "error" in r]
        print(f"   ✅ Success: {len(success)}")
        print(f"   ❌ Failed: {len(failed)}")
        if failed:
            print(f"\n   Failed videos:")
            for r in failed:
                print(f"      • {r['url'][:50]}...")
                print(f"        {r['error']}")
    
    # Print next steps for successful extractions
    successful = [r for r in results if "source" in r]
    if successful:
        print(f"\n📋 Next: Process with AI agent")
        for r in successful:
            print(f"   • {r['source']}")


# ═══════════════════════════════════════════════════════════════════════════════
# Queue Management
# ═══════════════════════════════════════════════════════════════════════════════

QUEUE_FILE = os.path.expanduser("~/.tubescribe/queue.json")


@contextmanager
def _locked_queue():
    """Context manager for atomic queue read-modify-write with file locking."""
    os.makedirs(os.path.dirname(QUEUE_FILE), exist_ok=True)
    fd = os.open(QUEUE_FILE, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        if _HAS_FCNTL:
            fcntl.flock(fd, fcntl.LOCK_EX)
        elif not getattr(_locked_queue, '_warned', False):
            print("Warning: File locking unavailable on this platform, queue operations may race", file=sys.stderr)
            _locked_queue._warned = True
        content = b''
        while True:
            chunk = os.read(fd, 4096)
            if not chunk:
                break
            content += chunk
        try:
            data = json.loads(content.decode('utf-8')) if content.strip() else {"current": None, "queue": []}
        except json.JSONDecodeError:
            data = {"current": None, "queue": []}

        yield data

        # Write back (only reached if no exception in with-block)
        os.ftruncate(fd, 0)
        os.lseek(fd, 0, os.SEEK_SET)
        os.write(fd, json.dumps(data, indent=2).encode('utf-8'))
    finally:
        os.close(fd)


def load_queue() -> dict:
    """Load queue from file (read-only, no locking)."""
    if os.path.exists(QUEUE_FILE):
        try:
            with open(QUEUE_FILE, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError, OSError):
            pass
    return {"current": None, "queue": []}


def add_to_queue(url: str, title: str = None) -> int:
    """Add URL to queue. Returns position (1-indexed)."""
    if not is_youtube_url(url):
        print(ERROR_MESSAGES["invalid_url"])
        return 0

    with _locked_queue() as data:
        entry = {
            "url": url,
            "title": title,
            "added": datetime.now().astimezone().isoformat()
        }
        data["queue"].append(entry)
        position = len(data["queue"])
        if data["current"]:
            position += 1

    print(f"📋 Added to queue (position {position})")
    return position


def pop_from_queue() -> str | None:
    """Get next URL from queue."""
    with _locked_queue() as data:
        if not data["queue"]:
            return None
        entry = data["queue"].pop(0)
        data["current"] = entry
        return entry["url"]


def clear_current():
    """Clear current processing item."""
    with _locked_queue() as data:
        data["current"] = None


def clear_queue():
    """Clear entire queue."""
    with _locked_queue() as data:
        data["current"] = None
        data["queue"] = []
    print("📋 Queue cleared")


def show_queue_status():
    """Show queue status."""
    data = load_queue()

    print("📋 TubeScribe Queue")
    print("─" * 40)

    if data["current"]:
        title = data["current"].get("title") or data["current"]["url"][:50]
        print(f"▶️  Processing: {title}")
    else:
        print("▶️  Processing: (none)")

    if data["queue"]:
        print(f"\n📝 Queued ({len(data['queue'])}):")
        for i, entry in enumerate(data["queue"], 1):
            title = entry.get("title") or entry["url"][:50]
            print(f"   {i}. {title}")
    else:
        print("\n📝 Queue: (empty)")


def clear_stale_current(config: dict = None) -> bool:
    """Clear the current processing item if it is stale. Returns True if cleared."""
    if config is None:
        config = load_config()
    stale_minutes = config.get("queue", {}).get("stale_minutes", 30)

    with _locked_queue() as data:
        if not data["current"]:
            return False
        try:
            added_str = data["current"].get("added", "")
            if added_str:
                added = datetime.fromisoformat(added_str.replace("Z", "+00:00"))
                now = datetime.now().astimezone()
                if added.tzinfo is None:
                    added = added.astimezone()
                if now - added > timedelta(minutes=stale_minutes):
                    data["current"] = None
                    return True
        except (ValueError, TypeError):
            pass
    return False


def is_processing(config: dict = None) -> bool:
    """Check if currently processing. Clears stale entries first."""
    clear_stale_current(config)
    data = load_queue()
    return data["current"] is not None


if __name__ == "__main__":
    main()
