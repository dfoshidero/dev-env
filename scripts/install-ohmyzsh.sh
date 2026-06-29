#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
P10K_DIR="${ZSH_CUSTOM:-${OH_MY_ZSH_DIR}/custom}/themes/powerlevel10k"

# Ensure zsh is default shell
if [[ "${SHELL:-}" != *zsh* ]]; then
  if command_exists zsh; then
    log_info "Setting zsh as default shell (requires password)"
    chsh -s "$(command -v zsh)" || log_warn "Could not change default shell. Run: chsh -s $(command -v zsh)"
  fi
fi

# Install Oh My Zsh
if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  log_ok "Oh My Zsh already installed"
else
  log_info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log_ok "Oh My Zsh installed"
fi

# Install Powerlevel10k
if [[ -d "$P10K_DIR" ]]; then
  log_ok "Powerlevel10k already installed"
else
  log_info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  log_ok "Powerlevel10k installed"
fi

# Install fzf if not present via apt plugin hook
if [[ ! -f "${HOME}/.fzf.zsh" ]] && command_exists fzf; then
  if [[ -d /usr/share/doc/fzf/examples ]]; then
    log_info "Setting up fzf key bindings..."
    /usr/share/doc/fzf/examples/key-bindings.zsh > "${HOME}/.fzf.zsh" 2>/dev/null || true
  fi
fi

log_ok "Shell setup complete"
