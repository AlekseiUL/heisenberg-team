#!/usr/bin/env python3
"""
TubeScribe Setup Wizard
=======================

Checks dependencies, sets optimal defaults, and offers to install
missing components for the best experience.

Usage:
    python setup.py [--check-only] [--quiet]
"""

import subprocess
import shutil
import sys
import os
import json

# Add script directory to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from config import (
    CONFIG_DIR, CONFIG_FILE, DEFAULT_CONFIG,
    load_config, save_config, get_config_dir
)
from tubescribe import (
    find_ytdlp as _find_ytdlp,
    find_kokoro as _find_kokoro,
    find_mlx_audio as _find_mlx_audio,
    KOKORO_DEPS,
)


def print_header():
    print("""
🎬 TubeScribe Setup
═══════════════════
""")


def check_command(cmd: str) -> bool:
    """Check if a command exists in PATH."""
    return shutil.which(cmd) is not None


def check_python_package(package: str, import_name: str = None) -> bool:
    """Check if a Python package is installed in system Python."""
    import_name = import_name or package
    try:
        result = subprocess.run(
            [sys.executable, "-c", f"import {import_name}"],
            capture_output=True, timeout=10
        )
        return result.returncode == 0
    except (subprocess.SubprocessError, OSError, TimeoutError):
        return False


def get_kokoro_path() -> str:
    """Get the path to Kokoro repo."""
    return os.path.expanduser("~/.openclaw/tools/kokoro")


def get_ml_env_path() -> str:
    """Get the path to shared ML environment."""
    return os.path.expanduser("~/.openclaw/tools/ml-env")


def check_ml_deps() -> dict:
    """Check which ML dependencies are available in system Python."""
    results = {}
    for package, import_name in KOKORO_DEPS.items():
        results[package] = check_python_package(package, import_name)
    return results


def get_python_for_kokoro() -> tuple[str, str | None]:
    """
    Find the best Python to use for Kokoro.
    Returns (python_path, kokoro_dir or None).
    """
    kokoro_dir = get_kokoro_path()
    ml_env = get_ml_env_path()
    ml_env_python = os.path.join(ml_env, "bin", "python")
    
    # Check if kokoro repo exists
    if not os.path.exists(kokoro_dir):
        return None, None
    
    # 1. Check system Python — all deps present?
    deps = check_ml_deps()
    if all(deps.values()):
        return sys.executable, kokoro_dir
    
    # 2. Check shared ML env
    if os.path.exists(ml_env_python):
        try:
            result = subprocess.run(
                [ml_env_python, "-c", "import torch, soundfile, numpy, huggingface_hub"],
                capture_output=True, timeout=10
            )
            if result.returncode == 0:
                return ml_env_python, kokoro_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    
    # 3. Check old-style venv inside kokoro dir (legacy)
    venv_python = os.path.join(kokoro_dir, ".venv", "bin", "python")
    if os.path.exists(venv_python):
        try:
            result = subprocess.run(
                [venv_python, "-c", "from kokoro import KPipeline"],
                capture_output=True, timeout=10, cwd=kokoro_dir
            )
            if result.returncode == 0:
                return venv_python, kokoro_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    
    return None, kokoro_dir  # Repo exists but no working Python


def find_kokoro() -> tuple[bool, str | None, str | None]:
    """
    Find Kokoro TTS installation.
    Returns (found: bool, python_path: str | None, kokoro_dir: str | None).
    """
    # Delegate to tubescribe's cached finder, skip cache for setup checks
    python_path, kokoro_dir = _find_kokoro(use_cache=False)
    if python_path and kokoro_dir:
        return True, python_path, kokoro_dir
    # Fall back to get_python_for_kokoro for the case where repo exists but
    # tubescribe's finder didn't find a working Python (setup may install deps)
    python_path, kokoro_dir = get_python_for_kokoro()
    if python_path and kokoro_dir:
        try:
            result = subprocess.run(
                [python_path, "-c", "from kokoro import KPipeline; print('ok')"],
                capture_output=True, timeout=10, cwd=kokoro_dir
            )
            if result.returncode == 0:
                return True, python_path, kokoro_dir
        except (subprocess.SubprocessError, OSError, TimeoutError):
            pass
    return False, None, None


def check_kokoro() -> bool:
    """Check if Kokoro TTS is installed and working."""
    found, _, _ = find_kokoro()
    return found


def check_mlx_audio() -> bool:
    """Check if mlx-audio is installed and working."""
    python_path, _ = _find_mlx_audio()
    return python_path is not None


def run_checks() -> dict:
    """Run all dependency checks and return results."""
    return {
        "required": {
            "summarize": check_command("summarize"),
            "python3": sys.version_info >= (3, 8),
        },
        "document": {
            "pandoc": check_pandoc(),
        },
        "audio": {
            "mlx_audio": check_mlx_audio(),
            "kokoro": check_kokoro(),
            "ffmpeg": check_command("ffmpeg"),
        },
        "comments": {
            "yt-dlp": check_ytdlp(),
        },
        "ml_deps": check_ml_deps(),  # Individual ML dep status
    }


def print_status(name: str, installed: bool, required: bool = False):
    """Print a status line."""
    icon = "✅" if installed else ("❌" if required else "⚠️")
    status = "installed" if installed else "not found"
    print(f"  {icon} {name:20} {status}")


def determine_config(checks: dict) -> dict:
    """Determine best config based on available dependencies.
    Starts from existing user config to preserve customizations,
    falls back to defaults for missing keys."""
    from config import deep_copy, deep_merge, DEFAULT_CONFIG

    config = deep_merge(deep_copy(DEFAULT_CONFIG), load_config())
    
    # Document format: DOCX if possible, else HTML
    if checks["document"]["pandoc"]:
        config["document"]["format"] = "docx"
        config["document"]["engine"] = "pandoc"
    else:
        config["document"]["format"] = "html"
        config["document"]["engine"] = None
    
    # Audio format: MP3 if ffmpeg available, else WAV
    if checks["audio"]["ffmpeg"]:
        config["audio"]["format"] = "mp3"
    else:
        config["audio"]["format"] = "wav"
    
    # TTS engine: mlx-audio (fastest) > Kokoro PyTorch > builtin
    if checks["audio"]["mlx_audio"]:
        config["audio"]["tts_engine"] = "mlx"
    elif checks["audio"]["kokoro"]:
        config["audio"]["tts_engine"] = "kokoro"
    else:
        config["audio"]["tts_engine"] = "builtin"
    
    return config


def prompt_yn(question: str) -> bool:
    """Ask a yes/no question. Returns False in non-interactive mode."""
    try:
        response = input(f"{question} [y/N] ").strip().lower()
        return response == 'y'
    except (EOFError, KeyboardInterrupt):
        print()
        return False


def install_with_brew(formula: str, name: str) -> bool:
    """Install something with Homebrew."""
    print(f"  → Installing {name}...")
    try:
        subprocess.run(["brew", "install", formula], check=True)
        print(f"  ✅ {name} installed!")
        return True
    except subprocess.CalledProcessError:
        print(f"  ❌ Installation failed")
        return False
    except FileNotFoundError:
        print(f"  ❌ Homebrew not found. Install manually: brew install {formula}")
        return False


def get_pandoc_path() -> str:
    """Get path to pandoc in tools."""
    return os.path.expanduser("~/.openclaw/tools/pandoc/pandoc")


def install_pandoc() -> bool:
    """Install pandoc standalone binary."""
    import platform
    import urllib.request
    import tarfile
    import zipfile
    
    tools_dir = os.path.expanduser("~/.openclaw/tools/pandoc")
    os.makedirs(tools_dir, exist_ok=True)
    
    # Determine platform
    system = platform.system().lower()
    machine = platform.machine().lower()
    
    # Try to fetch latest version from GitHub API, fall back to known version
    version = None
    try:
        req = urllib.request.Request(
            "https://api.github.com/repos/jgm/pandoc/releases/latest",
            headers={"Accept": "application/vnd.github.v3+json", "User-Agent": "TubeScribe-Setup"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            tag = data.get("tag_name", "")
            if tag:
                version = tag.lstrip("v")
    except Exception:
        pass
    if not version:
        version = "3.6.4"  # Fallback, last checked 2026-02
    
    if system == "darwin":
        if machine == "arm64":
            archive = f"pandoc-{version}-arm64-macOS.zip"
        else:
            archive = f"pandoc-{version}-x86_64-macOS.zip"
    elif system == "linux":
        if machine == "aarch64":
            archive = f"pandoc-{version}-linux-arm64.tar.gz"
        else:
            archive = f"pandoc-{version}-linux-amd64.tar.gz"
    else:
        print(f"  ❌ Unsupported platform: {system}/{machine}")
        return False
    
    url = f"https://github.com/jgm/pandoc/releases/download/{version}/{archive}"
    download_path = os.path.join(tools_dir, archive)
    
    try:
        print(f"  → Downloading pandoc {version}...")
        urllib.request.urlretrieve(url, download_path)
        
        print("  → Extracting...")
        if archive.endswith(".zip"):
            with zipfile.ZipFile(download_path, 'r') as z:
                # Validate no path traversal in zip entries
                for info in z.infolist():
                    target = os.path.realpath(os.path.join(tools_dir, info.filename))
                    if not target.startswith(os.path.realpath(tools_dir)):
                        raise ValueError(f"Unsafe zip entry: {info.filename}")
                z.extractall(tools_dir)
        else:
            with tarfile.open(download_path, 'r:gz') as t:
                # Validate no path traversal in tar entries
                for member in t.getmembers():
                    target = os.path.realpath(os.path.join(tools_dir, member.name))
                    if not target.startswith(os.path.realpath(tools_dir)):
                        raise ValueError(f"Unsafe tar entry: {member.name}")
                extract_kwargs = {"path": tools_dir}
                if sys.version_info >= (3, 12):
                    extract_kwargs["filter"] = "data"
                t.extractall(**extract_kwargs)

        # Find and move the binary
        extracted_dir = os.path.join(tools_dir, f"pandoc-{version}")
        binary_src = os.path.join(extracted_dir, "bin", "pandoc")
        
        binary_dst = os.path.join(tools_dir, "pandoc")
        if os.path.exists(binary_src):
            shutil.move(binary_src, binary_dst)
            os.chmod(binary_dst, 0o755)
        
        # Cleanup
        os.remove(download_path)
        shutil.rmtree(extracted_dir, ignore_errors=True)
        
        print(f"  ✅ Pandoc installed to {tools_dir}")
        return True
        
    except Exception as e:
        print(f"  ❌ Failed: {e}")
        return False


def check_pandoc() -> bool:
    """Check if pandoc is available (system or tools)."""
    # Check system first
    if shutil.which("pandoc"):
        return True
    # Check our tools dir
    tools_pandoc = get_pandoc_path()
    return os.path.exists(tools_pandoc) and os.access(tools_pandoc, os.X_OK)


def get_ytdlp_path() -> str:
    """Get path to yt-dlp in our tools directory."""
    return os.path.expanduser("~/.openclaw/tools/yt-dlp/yt-dlp")


def find_ytdlp() -> str | None:
    """Find yt-dlp binary. Delegates to tubescribe.find_ytdlp."""
    return _find_ytdlp()


def check_ytdlp() -> bool:
    """Check if yt-dlp is available anywhere."""
    return find_ytdlp() is not None


def install_ytdlp() -> bool:
    """
    Install yt-dlp standalone binary.
    
    Installation location: ~/.openclaw/tools/yt-dlp/yt-dlp
    
    This is a self-contained binary that doesn't conflict with
    system installations (Homebrew, pip, etc.). If user later
    installs via Homebrew, that will take precedence (checked first).
    """
    import platform
    import urllib.request
    
    # Check if already installed somewhere
    existing = find_ytdlp()
    if existing:
        print(f"  ℹ️  yt-dlp already installed at {existing}")
        return True
    
    tools_dir = os.path.expanduser("~/.openclaw/tools/yt-dlp")
    os.makedirs(tools_dir, exist_ok=True)
    
    # Determine platform
    system = platform.system().lower()
    machine = platform.machine().lower()
    
    # yt-dlp releases - standalone binaries
    # https://github.com/yt-dlp/yt-dlp/releases
    base_url = "https://github.com/yt-dlp/yt-dlp/releases/latest/download"
    
    if system == "darwin":
        binary_name = "yt-dlp_macos"  # Universal binary (x86_64 + arm64)
    elif system == "linux":
        if machine == "aarch64":
            binary_name = "yt-dlp_linux_aarch64"
        else:
            binary_name = "yt-dlp_linux"
    else:
        print(f"  ❌ Unsupported platform: {system}/{machine}")
        print(f"     Try: pip install yt-dlp")
        return False
    
    url = f"{base_url}/{binary_name}"
    download_path = os.path.join(tools_dir, "yt-dlp")
    
    try:
        print(f"  → Downloading yt-dlp...")
        urllib.request.urlretrieve(url, download_path)
        os.chmod(download_path, 0o755)
        
        print(f"  ✅ yt-dlp installed to {download_path}")
        return True
        
    except Exception as e:
        print(f"  ❌ Failed: {e}")
        print(f"     Try manually: brew install yt-dlp")
        return False


def is_apple_silicon() -> bool:
    """Check if running on Apple Silicon (M1/M2/M3/M4)."""
    import platform
    return platform.system() == "Darwin" and platform.machine() == "arm64"


def install_mlx_audio() -> bool:
    """Install mlx-audio in a dedicated venv at ~/.openclaw/tools/mlx-audio/.
    
    Only works on Apple Silicon (requires MLX framework).
    Creates a Python venv, installs mlx-audio + dependencies.
    """
    import platform
    
    if not is_apple_silicon():
        print("  ❌ mlx-audio requires Apple Silicon (M1/M2/M3/M4)")
        print("     Use Kokoro TTS (PyTorch) instead.")
        return False
    
    mlx_dir = os.path.expanduser("~/.openclaw/tools/mlx-audio")
    venv_dir = os.path.join(mlx_dir, ".venv")
    
    try:
        os.makedirs(mlx_dir, exist_ok=True)
        
        # Find a suitable Python (3.10-3.12 work best with MLX)
        python_candidates = [
            "/usr/local/bin/python3.12",
            "/opt/homebrew/bin/python3.12",
            "/opt/homebrew/bin/python3.13",
            sys.executable,
        ]
        python_bin = None
        for p in python_candidates:
            if os.path.exists(p):
                python_bin = p
                break
        
        if not python_bin:
            print("  ❌ No suitable Python found")
            return False
        
        # Create venv
        if not os.path.exists(venv_dir):
            print(f"  → Creating venv with {os.path.basename(python_bin)}...")
            subprocess.run([python_bin, "-m", "venv", venv_dir], check=True)
        
        venv_pip = os.path.join(venv_dir, "bin", "pip")
        venv_python = os.path.join(venv_dir, "bin", "python3")
        
        # Install mlx-audio + deps
        print("  → Installing mlx-audio (this may take a minute)...")
        subprocess.run(
            [venv_pip, "install", "--quiet", "mlx-audio", "misaki", "num2words",
             "spacy", "espeakng_loader"],
            check=True
        )
        
        # Patch misaki/espeak.py if homebrew espeak-ng is available
        brew_lib = "/opt/homebrew/lib/libespeak-ng.dylib"
        if os.path.exists(brew_lib):
            import glob
            import re as _re
            espeak_files = glob.glob(os.path.join(venv_dir, "lib", "python3.*",
                                                   "site-packages", "misaki", "espeak.py"))
            for espeak_py in espeak_files:
                with open(espeak_py, 'r') as f:
                    content = f.read()
                # Skip if already patched
                if "/opt/homebrew" in content:
                    continue
                # Use regex to match the target pattern flexibly (survives minor whitespace/comment changes)
                pattern = _re.compile(
                    r'EspeakWrapper\.set_library\(espeakng_loader\.get_library_path\(\)\).*?'
                    r'EspeakWrapper\.set_data_path\(espeakng_loader\.get_data_path\(\)\)',
                    _re.DOTALL
                )
                if pattern.search(content):
                    print("  → Patching misaki for homebrew espeak-ng...")
                    replacement = (
                        "import os as _os\n"
                        "_brew_lib = '/opt/homebrew/lib/libespeak-ng.dylib'\n"
                        "_brew_data = '/opt/homebrew/share/espeak-ng-data'\n"
                        "if _os.path.exists(_brew_lib):\n"
                        "    EspeakWrapper.set_library(_brew_lib)\n"
                        "    EspeakWrapper.data_path = _brew_data\n"
                        "else:\n"
                        "    EspeakWrapper.set_library(espeakng_loader.get_library_path())\n"
                        "    EspeakWrapper.data_path = espeakng_loader.get_data_path()"
                    )
                    content = pattern.sub(replacement, content, count=1)
                    with open(espeak_py, 'w') as f:
                        f.write(content)
                elif "espeakng_loader" in content:
                    print("  ⚠️  misaki/espeak.py has changed — skipping homebrew patch (may not be needed)")
        
        # Verify it works
        print("  → Verifying mlx-audio...")
        result = subprocess.run(
            [venv_python, "-c", "from mlx_audio.tts.generate import generate_audio; print('OK')"],
            capture_output=True, text=True, timeout=30
        )
        
        if result.returncode == 0 and "OK" in result.stdout:
            print("  ✅ mlx-audio installed and working!")
            print(f"  📁 Location: {mlx_dir}")
            print("  ℹ️  Kokoro model (~345MB) will download on first use")
            return True
        else:
            print(f"  ❌ Verification failed: {result.stderr[:200]}")
            return False
        
    except subprocess.CalledProcessError as e:
        print(f"  ❌ Installation failed: {e}")
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


def install_kokoro() -> bool:
    """Install Kokoro TTS (PyTorch) in a clean venv.
    
    Creates ~/.openclaw/tools/kokoro/.venv with kokoro + torch.
    No git clone needed — kokoro is available on PyPI.
    """
    kokoro_dir = get_kokoro_path()
    venv_dir = os.path.join(kokoro_dir, ".venv")
    
    try:
        os.makedirs(kokoro_dir, exist_ok=True)
        
        # Find a suitable Python
        python_candidates = [
            "/usr/local/bin/python3.12",
            "/opt/homebrew/bin/python3.12",
            "/opt/homebrew/bin/python3.13",
            sys.executable,
        ]
        python_bin = None
        for p in python_candidates:
            if os.path.exists(p):
                python_bin = p
                break
        
        if not python_bin:
            print("  ❌ No suitable Python found")
            return False
        
        # Create venv
        if not os.path.exists(venv_dir):
            print(f"  → Creating venv with {os.path.basename(python_bin)}...")
            subprocess.run([python_bin, "-m", "venv", venv_dir], check=True)
        
        venv_pip = os.path.join(venv_dir, "bin", "pip")
        venv_python = os.path.join(venv_dir, "bin", "python3")
        
        # Install kokoro + deps (~500MB for PyTorch)
        print("  → Installing Kokoro + PyTorch (this may take a few minutes)...")
        subprocess.run(
            [venv_pip, "install", "--quiet", "kokoro", "soundfile", "torch",
             "misaki", "num2words", "spacy"],
            check=True
        )
        
        # Verify it works
        print("  → Verifying Kokoro...")
        result = subprocess.run(
            [venv_python, "-c", "from kokoro import KPipeline; print('OK')"],
            capture_output=True, text=True, timeout=30
        )
        
        if result.returncode == 0 and "OK" in result.stdout:
            print("  ✅ Kokoro installed and working!")
            print(f"  📁 Location: {kokoro_dir}")
            print("  ℹ️  Voice model (~326MB) will download on first use")
            return True
        else:
            print(f"  ❌ Verification failed: {result.stderr[:200]}")
            return False
        
    except subprocess.CalledProcessError as e:
        print(f"  ❌ Installation failed: {e}")
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


# save_config is imported from config.py


def main(check_only: bool = False, quiet: bool = False):
    if not quiet:
        print_header()
        print("Checking dependencies...\n")
    
    checks = run_checks()
    
    # === REQUIRED DEPENDENCIES ===
    if not quiet:
        print("Required:")
    
    all_required = True
    for name, installed in checks["required"].items():
        if not quiet:
            print_status(name, installed, required=True)
        if not installed:
            all_required = False
    
    if not all_required:
        print("\n❌ Missing required dependencies!")
        if not checks["required"]["summarize"]:
            print("\n   Install summarize CLI:")
            print("   brew install steipete/tap/summarize")
        sys.exit(1)
    
    # === OPTIONAL DEPENDENCIES ===
    if not quiet:
        print("\nDocument output:")
        print_status("pandoc", checks["document"]["pandoc"])
        print("\nAudio output:")
        print_status("mlx-audio", checks["audio"]["mlx_audio"])
        print_status("kokoro", checks["audio"]["kokoro"])
        print_status("ffmpeg", checks["audio"]["ffmpeg"])
        
        print("\nComments:")
        print_status("yt-dlp", checks["comments"]["yt-dlp"])
    
    if check_only:
        if quiet:
            print(json.dumps(checks))
        return checks
    
    # === DETERMINE BEST CONFIG ===
    config = determine_config(checks)
    
    if not quiet:
        print("\n" + "─" * 40)
        print("\n📋 Your configuration (based on available tools):\n")
        
        doc_format = config["document"]["format"]
        doc_engine = config["document"].get("engine")
        doc_note = f" (via {doc_engine})" if doc_engine else ""
        if doc_format == "html":
            doc_note = " (no dependencies needed)"
        print(f"  📄 Document: {doc_format.upper()}{doc_note}")
        
        audio_format = config["audio"]["format"]
        tts_engine = config["audio"]["tts_engine"]
        if tts_engine == "mlx":
            audio_note = " (MLX — fastest on Apple Silicon)"
        elif tts_engine == "kokoro":
            audio_note = " (Kokoro PyTorch)"
        else:
            audio_note = " (built-in macOS voice)"
        print(f"  🔊 Audio:    {audio_format.upper()}{audio_note}")
        print(f"  📁 Output:   {config['output']['folder']}")
    
    # === OFFER TO INSTALL MISSING FOR BEST EXPERIENCE ===
    missing_upgrades = []
    
    if not checks["document"]["pandoc"]:
        missing_upgrades.append({
            "name": "pandoc",
            "desc": "DOCX support",
            "why": "Better document formatting, opens in Word/Pages",
            "brew": "pandoc",
            "standalone_installer": install_pandoc,
            "config_update": lambda c: c["document"].update({"format": "docx", "engine": "pandoc"}),
        })
    
    if not checks["audio"]["ffmpeg"]:
        missing_upgrades.append({
            "name": "ffmpeg",
            "desc": "MP3 audio output",
            "why": "Smaller file sizes (MP3 vs WAV)",
            "brew": "ffmpeg",
            "config_update": lambda c: c["audio"].update({"format": "mp3"}),
        })
    
    if not checks["audio"]["mlx_audio"] and not checks["audio"]["kokoro"]:
        # Neither TTS backend available — offer the best one for this platform
        if is_apple_silicon():
            missing_upgrades.append({
                "name": "mlx-audio",
                "desc": "High-quality voices (MLX — fastest on Apple Silicon)",
                "why": "Natural-sounding speech, 3-4x faster than PyTorch on M-series chips",
                "brew": None,
                "installer": install_mlx_audio,
                "install_note": "Requires ~900MB download (one-time)",
                "config_update": lambda c: c["audio"].update({"tts_engine": "mlx"}),
            })
        else:
            missing_upgrades.append({
                "name": "Kokoro TTS",
                "desc": "High-quality voices (PyTorch)",
                "why": "Natural-sounding speech instead of robotic macOS voice",
                "brew": None,
                "installer": install_kokoro,
                "install_note": "Requires ~500MB download (one-time)",
                "config_update": lambda c: c["audio"].update({"tts_engine": "kokoro"}),
            })
    
    if not checks["comments"]["yt-dlp"]:
        missing_upgrades.append({
            "name": "yt-dlp",
            "desc": "YouTube comments",
            "why": "Extract top comments for summary & best-of section",
            "brew": "yt-dlp",
            "standalone_installer": install_ytdlp,
            "config_update": lambda c: c.setdefault("comments", {}).update({"enabled": True}),
        })
    
    if missing_upgrades and not quiet:
        print("\n" + "─" * 40)
        print("\n🚀 For the best experience, consider installing:\n")
        
        for upgrade in missing_upgrades:
            print(f"  • {upgrade['desc']} ({upgrade['name']})")
            print(f"    → {upgrade['why']}")
            
            if upgrade.get("install_note"):
                print(f"    {upgrade['install_note']}")
            
            if upgrade.get("brew") and upgrade.get("standalone_installer"):
                # Offer choice: brew or standalone
                if prompt_yn(f"\n    Install {upgrade['name']}?"):
                    print("      1. Homebrew (brew install)")
                    print("      2. Standalone binary (~/.openclaw/tools/)")
                    choice = input("      Choice [1/2]: ").strip()
                    success = False
                    if choice == "2":
                        success = upgrade["standalone_installer"]()
                    else:
                        success = install_with_brew(upgrade["brew"], upgrade["name"])
                    if success and upgrade.get("config_update"):
                        upgrade["config_update"](config)
            elif upgrade.get("brew"):
                if prompt_yn(f"\n    Install {upgrade['name']}?"):
                    if install_with_brew(upgrade["brew"], upgrade["name"]):
                        if upgrade.get("config_update"):
                            upgrade["config_update"](config)
            elif upgrade.get("installer"):
                if prompt_yn(f"\n    Install {upgrade['name']}?"):
                    if upgrade["installer"]():
                        if upgrade.get("config_update"):
                            upgrade["config_update"](config)
            print()
    
    # === SAVE CONFIG ===
    save_config(config)
    
    if not quiet:
        print("─" * 40)
        print(f"\n💾 Config saved to: {CONFIG_FILE}")
        print("\n✅ Setup complete!\n")
        
        print("Final configuration:")
        print(f"  📄 Document: {config['document']['format'].upper()}")
        print(f"  🔊 Audio:    {config['audio']['format'].upper()} via {config['audio']['tts_engine']}")
        print(f"  📁 Output:   {config['output']['folder']}")
        
        print("\n" + "─" * 40)
        print("\nUsage: Just send a YouTube URL to your OpenClaw agent!")
        print("       Or run: python tubescribe.py <youtube_url>\n")
    
    return config


if __name__ == "__main__":
    check_only = "--check-only" in sys.argv
    quiet = "--quiet" in sys.argv
    main(check_only=check_only, quiet=quiet)
