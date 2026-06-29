#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

# Docker CLI tools — assumes Docker Desktop on Windows with WSL integration
# This script only verifies/installs docker compose plugin if available via apt

if command_exists docker; then
  log_ok "Docker CLI available: $(docker --version 2>/dev/null || true)"
else
  log_warn "Docker CLI not found in WSL."
  log_info "Install Docker Desktop on Windows and enable WSL integration:"
  log_info "  Settings -> Resources -> WSL Integration -> Enable for Ubuntu"
fi

if command_exists docker && docker compose version &>/dev/null; then
  log_ok "Docker Compose available: $(docker compose version 2>/dev/null | head -1)"
else
  log_warn "Docker Compose plugin not detected (optional if using Docker Desktop)"
fi

log_ok "Docker tools check complete"
