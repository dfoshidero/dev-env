#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

AWS_CLI_ZIP="/tmp/awscliv2.zip"
AWS_CLI_INSTALLER="/tmp/aws/install"

if command_exists aws; then
  log_ok "AWS CLI already installed: $(aws --version 2>&1 | head -1)"
  exit 0
fi

log_info "Installing AWS CLI v2 (official installer)..."
ensure_sudo

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$AWS_CLI_ZIP"
rm -rf /tmp/aws
unzip -qo "$AWS_CLI_ZIP" -d /tmp
sudo "$AWS_CLI_INSTALLER" --update
rm -rf "$AWS_CLI_ZIP" /tmp/aws

log_ok "AWS CLI installed: $(aws --version 2>&1 | head -1)"
log_info "Configure credentials with: aws configure"
