#!/usr/bin/env python3
"""
TubeScribe Configuration
========================

Central configuration management for TubeScribe.
All settings in one place, with defaults and validation.
"""

import os
import json
import sys
from pathlib import Path

try:
    import fcntl
    _HAS_FCNTL = True
except ImportError:
    _HAS_FCNTL = False

# Config location
CONFIG_DIR = Path.home() / ".tubescribe"
CONFIG_FILE = CONFIG_DIR / "config.json"

# Default configuration with all available options
DEFAULT_CONFIG = {
    # Output settings
    "output": {
        "folder": str(Path.home() / "Documents" / "TubeScribe"),
        "open_folder_after": True,      # Open output folder when done
        "open_document_after": False,   # Auto-open generated document (docx/html/md)
        "open_audio_after": False,      # Auto-open generated audio summary
    },
    
    # Document settings
    "document": {
        "format": "docx",               # docx, html, md
        "engine": "pandoc",             # pandoc (for docx), falls back to html
    },
    
    # Audio settings
    "audio": {
        "enabled": True,                # Generate audio summary
        "format": "mp3",                # mp3, wav
        "tts_engine": "mlx",            # mlx (mlx-audio, fastest), kokoro (PyTorch), builtin (macOS say)
    },
    
    # MLX-Audio TTS settings (preferred on Apple Silicon)
    "mlx_audio": {
        "path": str(Path.home() / ".openclaw" / "tools" / "mlx-audio"),
        "model": "mlx-community/Kokoro-82M-bf16",
        "voice": "af_heart",             # Single voice name or path to .safetensors
        "voice_blend": {                  # Custom voice mix (overrides voice if set)
            "af_heart": 0.6,
            "af_sky": 0.4,
        },
        "lang_code": "a",
        "speed": 1.05,                    # Playback speed (1.0 = normal, 1.05 = 5% faster)
    },
    
    # Kokoro TTS settings (PyTorch fallback)
    "kokoro": {
        "path": str(Path.home() / ".openclaw" / "tools" / "kokoro"),
        "voice_blend": {                # Custom voice mix
            "af_heart": 0.6,
            "af_sky": 0.4,
        },
        "speed": 1.05,                  # Playback speed (1.0 = normal, 1.05 = 5% faster)
    },
    
    # Processing settings
    "processing": {
        "subagent_timeout": 600,        # Seconds for sub-agent processing
        "cleanup_temp_files": True,     # Remove /tmp files after completion
    },
    
    # Comments settings
    "comments": {
        "max_count": 50,                # Number of comments to fetch
        "timeout": 90,                  # Timeout for comment fetching (seconds)
    },
    
    # Queue settings
    "queue": {
        "stale_minutes": 30,            # Consider processing stale after this many minutes
    },
}


_CONFIG_VALIDATORS = {
    "document.format": lambda v: v in ("docx", "html", "md"),
    "audio.enabled": lambda v: isinstance(v, bool),
    "audio.format": lambda v: v in ("mp3", "wav"),
    "audio.tts_engine": lambda v: v in ("mlx", "kokoro", "builtin"),
    "mlx_audio.speed": lambda v: isinstance(v, (int, float)) and 0.1 <= v <= 5.0,
    "kokoro.speed": lambda v: isinstance(v, (int, float)) and 0.1 <= v <= 5.0,
    "processing.subagent_timeout": lambda v: isinstance(v, (int, float)) and v > 0,
    "comments.max_count": lambda v: isinstance(v, int) and v > 0,
    "comments.timeout": lambda v: isinstance(v, (int, float)) and v > 0,
    "queue.stale_minutes": lambda v: isinstance(v, (int, float)) and v > 0,
}


def _validate_config(config: dict, defaults: dict) -> dict:
    """Validate config values, reverting invalid ones to defaults."""
    for dotpath, validator in _CONFIG_VALIDATORS.items():
        keys = dotpath.split('.')
        # Navigate to value
        value = config
        default_value = defaults
        try:
            for k in keys:
                value = value[k]
                default_value = default_value[k]
        except (KeyError, TypeError):
            continue
        if not validator(value):
            # Revert to default
            target = config
            for k in keys[:-1]:
                target = target[k]
            target[keys[-1]] = deep_copy(default_value)
    return config


def get_config_dir() -> Path:
    """Get the config directory, creating if needed."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    return CONFIG_DIR


def load_config() -> dict:
    """Load config from file, merging with defaults. Invalid values are reverted."""
    config = deep_copy(DEFAULT_CONFIG)

    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, 'r') as f:
                user_config = json.load(f)
            config = deep_merge(config, user_config)
        except (json.JSONDecodeError, IOError):
            pass  # Use defaults if config is corrupted

    config = _validate_config(config, DEFAULT_CONFIG)
    return config


def save_config(config: dict) -> None:
    """Save config to file with file locking to prevent concurrent write corruption."""
    get_config_dir()
    fd = os.open(str(CONFIG_FILE), os.O_RDWR | os.O_CREAT | os.O_TRUNC, 0o644)
    try:
        if _HAS_FCNTL:
            fcntl.flock(fd, fcntl.LOCK_EX)
        os.write(fd, json.dumps(config, indent=2).encode('utf-8'))
    finally:
        os.close(fd)


def get_value(key: str, default=None):
    """
    Get a config value using dot notation.

    Example:
        get_value("output.folder")
        get_value("audio.format")
    """
    config = load_config()
    keys = key.split('.')
    value = config
    
    try:
        for k in keys:
            value = value[k]
        return value
    except (KeyError, TypeError):
        return default


def set_value(key: str, value) -> None:
    """
    Set a config value using dot notation.

    Example:
        set_value("output.folder", "~/Desktop/Videos")
        set_value("audio.enabled", False)
    """
    config = load_config()
    keys = key.split('.')
    
    # Navigate to the parent
    target = config
    for k in keys[:-1]:
        if k not in target:
            target[k] = {}
        target = target[k]
    
    # Set the value
    target[keys[-1]] = value
    save_config(config)


def deep_copy(obj):
    """Deep copy a dict/list structure."""
    if isinstance(obj, dict):
        return {k: deep_copy(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [deep_copy(v) for v in obj]
    return obj


def deep_merge(base: dict, override: dict) -> dict:
    """Deep merge override into base."""
    result = deep_copy(base)
    
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = deep_copy(value)
    
    return result


def reset_to_defaults() -> None:
    """Reset config to defaults."""
    save_config(DEFAULT_CONFIG)


def print_config() -> None:
    """Print current config in a readable format."""
    config = load_config()
    print(json.dumps(config, indent=2))


# CLI interface
if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("TubeScribe Configuration")
        print("=" * 40)
        print(f"Config file: {CONFIG_FILE}")
        print()
        print_config()
    
    elif sys.argv[1] == "get" and len(sys.argv) == 3:
        value = get_value(sys.argv[2])
        print(value if value is not None else "(not set)")
    
    elif sys.argv[1] == "set" and len(sys.argv) == 4:
        key, value = sys.argv[2], sys.argv[3]
        # Try to parse as JSON for complex values
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            pass  # Keep as string
        set_value(key, value)
        print(f"Set {key} = {value}")
    
    elif sys.argv[1] == "reset":
        reset_to_defaults()
        print("Config reset to defaults.")
    
    elif sys.argv[1] == "path":
        print(CONFIG_FILE)
    
    else:
        print("Usage:")
        print("  python config.py              # Show current config")
        print("  python config.py get KEY      # Get a value (dot notation)")
        print("  python config.py set KEY VAL  # Set a value")
        print("  python config.py reset        # Reset to defaults")
        print("  python config.py path         # Show config file path")
        print()
        print("Examples:")
        print("  python config.py get output.folder")
        print("  python config.py set audio.format wav")
        print("  python config.py set output.folder ~/Desktop/Videos")
