#!/usr/bin/env bash
# bootstrap.sh — shared helpers for dev-env installer
set -euo pipefail

# Resolve repo root regardless of caller location
DEV_ENV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEV_ENV_ROOT
export DEV_ENV_CONFIG="${DEV_ENV_ROOT}/config"
export DEV_ENV_DOTFILES="${DEV_ENV_ROOT}/dotfiles"
export DEV_ENV_SCRIPTS="${DEV_ENV_ROOT}/scripts"
export DEV_ENV_TEMPLATES="${DEV_ENV_ROOT}/templates"
export DEV_ENV_TESTS="${DEV_ENV_ROOT}/tests"

# Colors
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

die() {
  log_error "$@"
  exit 1
}

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || die "This installer must run inside Linux (WSL2 Ubuntu)."
}

require_wsl2() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    log_ok "Running inside WSL"
    if grep -qi "WSL2" /proc/version 2>/dev/null || [[ -d /mnt/wsl ]]; then
      log_ok "WSL2 detected"
    else
      log_warn "Could not confirm WSL2. Ensure you are using WSL2, not WSL1."
    fi
  else
    log_warn "Not running inside WSL. Continuing on native Linux."
  fi
}

command_exists() {
  command -v "$1" &>/dev/null
}

run_script() {
  local script="$1"
  local name
  name="$(basename "$script")"
  [[ -f "$script" ]] || die "Missing script: $script"
  log_info "Running $name..."
  bash "$script"
  log_ok "Finished $name"
}

backup_file() {
  local target="$1"
  if [[ -e "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$target" "$backup"
    log_warn "Backed up $target -> $backup"
  fi
}

link_or_copy_dotfile() {
  local src="$1"
  local dest="$2"
  backup_file "$dest"
  ln -sf "$src" "$dest"
  log_ok "Linked $dest -> $src"
}

apt_install_if_missing() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null; then
    log_ok "apt package already installed: $pkg"
  else
    log_info "Installing apt package: $pkg"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
  fi
}

ensure_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log_info "sudo access required for system packages"
    sudo -v
  fi
}

ensure_apt_updated() {
  log_info "Updating apt package lists..."
  sudo apt-get update -qq
}

install_apt_packages_from_file() {
  local file="$1"
  [[ -f "$file" ]] || die "Missing apt package list: $file"
  ensure_sudo
  ensure_apt_updated
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -n "$line" ]] || continue
    apt_install_if_missing "$line"
  done < "$file"
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local reply
  if [[ "$default" == "y" ]]; then
    read -r -p "$prompt [Y/n]: " reply
    reply="${reply:-y}"
  else
    read -r -p "$prompt [y/N]: " reply
    reply="${reply:-n}"
  fi
  [[ "$reply" =~ ^[Yy]$ ]]
}

export -f log_info log_ok log_warn log_error die require_linux require_wsl2
export -f command_exists run_script backup_file link_or_copy_dotfile
export -f apt_install_if_missing ensure_sudo ensure_apt_updated install_apt_packages_from_file
export -f prompt_yes_no
