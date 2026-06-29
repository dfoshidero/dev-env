#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

MISE_INSTALL_URL="https://mise.run"
MISE_CONFIG_DIR="${HOME}/.config/mise"
MISE_CONFIG_FILE="${MISE_CONFIG_DIR}/config.toml"

# Install mise
if command_exists mise; then
  log_ok "mise already installed: $(mise --version 2>/dev/null || true)"
else
  log_info "Installing mise..."
  curl -fsSL "$MISE_INSTALL_URL" | sh
  export PATH="${HOME}/.local/bin:${PATH}"
  log_ok "mise installed"
fi

# Ensure mise is on PATH for this session
export PATH="${HOME}/.local/bin:${PATH}"

# Copy global tool versions
mkdir -p "$MISE_CONFIG_DIR"
if [[ -f "${DEV_ENV_CONFIG}/mise.toml" ]]; then
  cp "${DEV_ENV_CONFIG}/mise.toml" "$MISE_CONFIG_FILE"
  log_ok "Synced mise config -> $MISE_CONFIG_FILE"
fi

# Install all tools from config
log_info "Installing mise tools (this may take a few minutes)..."
mise trust "$MISE_CONFIG_FILE" 2>/dev/null || true
mise install --yes
log_ok "mise tools installed"

# Enable Corepack for Node package managers (pnpm/yarn) without global frameworks
if command_exists node; then
  log_info "Enabling Corepack..."
  corepack enable 2>/dev/null || log_warn "Corepack enable failed (non-fatal)"
  log_ok "Corepack enabled"
fi

log_ok "mise setup complete"
