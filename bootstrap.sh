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
    if should_install_apt_package "$line"; then
      apt_install_if_missing "$line"
    else
      log_info "Skipping apt package (C/C++ not selected): $line"
    fi
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

# Language selection (exported for child install scripts; default 1 = install all)
language_selected() {
  local lang="$1"
  case "$lang" in
    python) [[ "${DEV_ENV_INSTALL_PYTHON:-1}" == 1 ]] ;;
    node)   [[ "${DEV_ENV_INSTALL_NODE:-1}" == 1 ]] ;;
    go)     [[ "${DEV_ENV_INSTALL_GO:-1}" == 1 ]] ;;
    java)   [[ "${DEV_ENV_INSTALL_JAVA:-1}" == 1 ]] ;;
    cpp)    [[ "${DEV_ENV_INSTALL_CPP:-1}" == 1 ]] ;;
    *) die "Unknown language: $lang" ;;
  esac
}

is_cpp_apt_package() {
  case "$1" in
    build-essential|gcc|g++|clang|lldb|gdb|cmake|make|pkg-config|libssl-dev|libffi-dev|zlib1g-dev)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

should_install_apt_package() {
  local pkg="$1"
  if is_cpp_apt_package "$pkg" && ! language_selected cpp; then
    return 1
  fi
  return 0
}

read_mise_tool_line() {
  local tool="$1"
  local file="${2:-${DEV_ENV_CONFIG}/mise.toml}"
  grep -E "^${tool}[[:space:]]*=" "$file" | head -1 || true
}

prompt_language_selection() {
  echo ""
  log_info "Select languages to install (press Enter to accept the default):"
  echo ""

  if prompt_yes_no "Install Python?" "y"; then
    export DEV_ENV_INSTALL_PYTHON=1
  else
    export DEV_ENV_INSTALL_PYTHON=0
  fi

  if prompt_yes_no "Install Node.js?" "y"; then
    export DEV_ENV_INSTALL_NODE=1
  else
    export DEV_ENV_INSTALL_NODE=0
  fi

  if prompt_yes_no "Install Go?" "y"; then
    export DEV_ENV_INSTALL_GO=1
  else
    export DEV_ENV_INSTALL_GO=0
  fi

  if prompt_yes_no "Install Java?" "y"; then
    export DEV_ENV_INSTALL_JAVA=1
  else
    export DEV_ENV_INSTALL_JAVA=0
  fi

  if prompt_yes_no "Install C/C++ toolchain?" "y"; then
    export DEV_ENV_INSTALL_CPP=1
  else
    export DEV_ENV_INSTALL_CPP=0
  fi

  echo ""
  log_info "Language selection summary:"
  language_selected python && echo "  Python: yes" || echo "  Python: no"
  language_selected node   && echo "  Node.js: yes" || echo "  Node.js: no"
  language_selected go     && echo "  Go: yes" || echo "  Go: no"
  language_selected java   && echo "  Java: yes" || echo "  Java: no"
  language_selected cpp    && echo "  C/C++ toolchain: yes" || echo "  C/C++ toolchain: no"
  echo ""
}

export -f log_info log_ok log_warn log_error die require_linux require_wsl2
export -f command_exists run_script backup_file link_or_copy_dotfile
export -f apt_install_if_missing ensure_sudo ensure_apt_updated install_apt_packages_from_file
export -f prompt_yes_no language_selected is_cpp_apt_package should_install_apt_package
export -f read_mise_tool_line prompt_language_selection
