#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

if ! language_selected python; then
  log_info "Skipping uv (Python not selected)"
  exit 0
fi

UV_INSTALL_URL="https://astral.sh/uv/install.sh"

if command_exists uv; then
  log_ok "uv already installed: $(uv --version 2>/dev/null || true)"
else
  log_info "Installing uv..."
  curl -LsSf "$UV_INSTALL_URL" | sh
  export PATH="${HOME}/.local/bin:${PATH}"
  log_ok "uv installed"
fi

export PATH="${HOME}/.local/bin:${PATH}"

# uv uses mise-managed Python by preference
export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-only-managed}"

log_ok "uv setup complete"
