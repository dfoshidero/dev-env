#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

export PATH="${HOME}/.local/bin:${PATH}"
[[ -f "${HOME}/.config/mise/config.toml" ]] && eval "$(mise activate bash 2>/dev/null)" || true

PASS=0
FAIL=0
WARN=0

check_cmd() {
  local name="$1"
  local cmd="${2:-$1}"
  if command_exists "$cmd"; then
    local version
    version="$($cmd --version 2>/dev/null | head -1 || $cmd version 2>/dev/null | head -1 || echo 'installed')"
    log_ok "$name: $version"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "$name: NOT FOUND"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

check_optional() {
  local name="$1"
  local cmd="${2:-$1}"
  if command_exists "$cmd"; then
    local version
    version="$($cmd --version 2>/dev/null | head -1 || echo 'installed')"
    log_ok "$name: $version"
    PASS=$((PASS + 1))
  else
    log_warn "$name: not installed (optional)"
    WARN=$((WARN + 1))
  fi
}

echo ""
log_info "Verifying development environment..."
echo ""

# Shell
check_cmd "zsh"
check_cmd "git"

# Version managers
check_cmd "mise"
check_cmd "uv"

# Languages (via mise)
check_cmd "python" "python3"
check_cmd "node"
check_cmd "go"
check_cmd "java"

# Cloud / K8s
check_cmd "aws"
check_cmd "kubectl"
check_cmd "helm"
check_cmd "k9s"
check_cmd "terraform"

# C/C++ toolchain
check_cmd "gcc"
check_cmd "clang"
check_cmd "cmake"
check_cmd "make"
check_cmd "gdb"

# Optional
check_optional "docker"
check_optional "npm"
check_optional "corepack"

echo ""
echo "----------------------------------------"
echo "  Passed: $PASS  |  Failed: $FAIL  |  Optional missing: $WARN"
echo "----------------------------------------"

if [[ $FAIL -gt 0 ]]; then
  log_error "Some required tools are missing. Re-run ./install.sh or mise install"
  exit 1
fi

log_ok "Verification passed"
exit 0
