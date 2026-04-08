#!/bin/bash
# bootstrap-install.sh - install system dependencies for Heisenberg Team
set -euo pipefail

OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.4.8}"

log() { echo "[bootstrap] $*"; }
need_sudo=false
command -v sudo >/dev/null 2>&1 && need_sudo=true

if [[ "${OSTYPE:-}" == linux* ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    $need_sudo && SUDO=sudo || SUDO=
    log "Updating apt indexes"
    $SUDO apt-get update
    log "Installing git, curl, build essentials, nodejs prerequisites"
    $SUDO apt-get install -y git curl ca-certificates gnupg
    if ! command -v node >/dev/null 2>&1; then
      log "Installing Node.js 20.x"
      curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
      $SUDO apt-get install -y nodejs
    fi
  else
    log "Unsupported Linux package manager. Install git + Node.js 20+ manually."
    exit 1
  fi
elif [[ "${OSTYPE:-}" == darwin* ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is required on macOS. Install it first: https://brew.sh"
    exit 1
  fi
  log "Installing git and node via Homebrew"
  brew install git node
else
  log "Unsupported OS. Install git, Node.js 20+, and OpenClaw manually."
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  log "Installing OpenClaw @$OPENCLAW_VERSION"
  npm install -g "openclaw@$OPENCLAW_VERSION"
else
  log "OpenClaw already installed: $(openclaw --version 2>/dev/null || echo unknown)"
fi

log "Done. Next: bash scripts/setup-wizard.sh"
