#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

# Link dotfiles from repo into $HOME
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/.zshrc"       "${HOME}/.zshrc"
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/aliases.zsh"  "${HOME}/.aliases.zsh"
link_or_copy_dotfile "${DEV_ENV_DOTFILES}/exports.zsh"  "${HOME}/.exports.zsh"

# Local override for repo path and secrets (not tracked in git)
LOCAL_ENV_FILE="${HOME}/.dev-env-local.zsh"

if [[ "$DEV_ENV_ROOT" != "${HOME}/dev-env" ]]; then
  echo "export DEV_ENV_REPO=\"${DEV_ENV_ROOT}\"" > "$LOCAL_ENV_FILE"
  log_ok "Wrote repo path override -> $LOCAL_ENV_FILE"
fi

log_ok "Dotfiles linked"
