#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

# Homebrew on Linux (WSL2) installs to /home/linuxbrew/.linuxbrew by default.
# Note: Homebrew Cask (GUI apps, fonts) is macOS-only — only CLI formulae work here.
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
BREW_BIN="${BREW_PREFIX}/bin/brew"
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

brew_shellenv() {
  if [[ -x "$BREW_BIN" ]]; then
    eval "$("$BREW_BIN" shellenv)"
  elif command_exists brew; then
    eval "$(brew shellenv)"
  fi
}

if command_exists brew || [[ -x "$BREW_BIN" ]]; then
  brew_shellenv
  log_ok "Homebrew already installed: $(brew --version 2>/dev/null | head -1 || true)"
else
  ensure_sudo
  log_info "Installing Homebrew (this may take a few minutes)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$BREW_INSTALL_URL")"
  brew_shellenv
  if command_exists brew; then
    log_ok "Homebrew installed: $(brew --version 2>/dev/null | head -1 || true)"
  else
    die "Homebrew install completed but 'brew' is not on PATH"
  fi
fi

log_ok "Homebrew setup complete"
