#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

install_apt_packages_from_file "${DEV_ENV_CONFIG}/apt-packages.txt"
log_ok "Apt packages installed"
