# Dev environment dotfiles — managed by dev-env repo
# Do not edit on a new machine; update the repo and re-run install.sh

# Local overrides (secrets, work config) — must stay above instant prompt if interactive
[[ -f "$HOME/.dev-env-local.zsh" ]] && source "$HOME/.dev-env-local.zsh"

# Enable Powerlevel10k instant prompt. Keep this block near the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DEV_ENV_REPO="${DEV_ENV_REPO:-$HOME/dev-env}"

# Exports before tool activation (PATH, GOPATH, etc.)
[[ -f "$HOME/.exports.zsh" ]] && source "$HOME/.exports.zsh"

# Tool env shims (uv, mise, etc.)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# mise (version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Powerlevel10k / Windows Terminal: fix right-prompt spacing and glyph alignment
ZLE_RPROMPT_INDENT=0

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
  git
  docker
  kubectl
  aws
  sudo
  fzf
  z
  colored-man-pages
)

source "$ZSH/oh-my-zsh.sh"

# Repo-managed shell config
[[ -f "$HOME/.aliases.zsh" ]] && source "$HOME/.aliases.zsh"
[[ -f "$HOME/.functions.zsh" ]] && source "$HOME/.functions.zsh"

# Powerlevel10k prompt config (generated once per machine by `p10k configure`).
# If it doesn't exist yet, launch the wizard automatically on the first
# interactive session — i.e. after the post-install terminal restart.
if [[ -f ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
elif [[ -o interactive ]] && [[ -t 0 ]] && (( $+functions[p10k] )); then
  echo "No Powerlevel10k config found — starting the prompt setup wizard (p10k configure)..."
  p10k configure
fi

# fzf key bindings
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Completion
autoload -Uz compinit && compinit

# Key bindings
bindkey -e

setopt PROMPT_SUBST

# WSL: start in home instead of /mnt/c (Windows Terminal default)
if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  if [[ -o login ]] || [[ "$PWD" == /mnt/c/* ]]; then
    builtin cd ~ 2>/dev/null || true
  fi
fi
