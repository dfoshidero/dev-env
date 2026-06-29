#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

# Link dotfiles from repo into $HOME
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/.zshrc"       "${HOME}/.zshrc"
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/aliases.zsh"  "${HOME}/.aliases.zsh"
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/exports.zsh"  "${HOME}/.exports.zsh"
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/.p10k.zsh"    "${HOME}/.p10k.zsh"
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/functions.zsh" "${HOME}/.functions.zsh"

# Local override for repo path and secrets (not tracked in git)
LOCAL_ENV_FILE="${HOME}/.dev-env-local.zsh"
EXAMPLE_LOCAL="${DEV_ENV_DOTFILES}/dev-env-local.example.zsh"

if [[ "$DEV_ENV_ROOT" != "${HOME}/dev-env" ]]; then
  echo "export DEV_ENV_REPO=\"${DEV_ENV_ROOT}\"" > "$LOCAL_ENV_FILE"
  log_ok "Wrote repo path override -> $LOCAL_ENV_FILE"
elif [[ ! -f "$LOCAL_ENV_FILE" && -f "$EXAMPLE_LOCAL" ]]; then
  cp "$EXAMPLE_LOCAL" "${HOME}/.dev-env-local.example.zsh"
  log_info "Copied secrets template -> ~/.dev-env-local.example.zsh"
  log_info "Copy and edit: cp ~/.dev-env-local.example.zsh ~/.dev-env-local.zsh"
fi

log_ok "Dotfiles linked"
