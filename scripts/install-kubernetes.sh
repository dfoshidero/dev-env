#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

export PATH="${HOME}/.local/bin:${PATH}"

# Ensure k8s tools are installed via mise
if ! command_exists kubectl || ! command_exists helm || ! command_exists k9s; then
  log_info "Installing Kubernetes tools via mise..."
  mise install kubectl helm k9s 2>/dev/null || mise install --yes
fi

TOOLS=(kubectl helm k9s)

for tool in "${TOOLS[@]}"; do
  if command_exists "$tool"; then
    log_ok "$tool already available: $($tool version 2>/dev/null | head -1 || $tool --version 2>/dev/null | head -1 || echo 'ok')"
  else
    log_warn "$tool not found after mise install — run: mise install"
  fi
done

mkdir -p "${HOME}/.kube"
log_ok "Kubernetes tools check complete"
log_info "Place kubeconfig at ~/.kube/config"
