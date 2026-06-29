# Shell aliases — managed by dev-env repo

# Shell
alias reload='source ~/.zshrc'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alhF'
alias la='ls -A'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gpu='git push'
alias gpl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Python via uv (project-local)
alias py='uv run python'
alias pytest='uv run pytest'

# Docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'

# AWS
alias awsl='aws configure list'
alias awsp='aws sts get-caller-identity'

# mise
alias mls='mise list'
alias min='mise install'
alias mup='mise upgrade'

# Dev environment
alias dev-update='cd ~/dev-env && git pull && ./install.sh'
alias dev-verify='~/dev-env/scripts/verify.sh'
alias dev-test='~/dev-env/tests/run-smoke-tests.sh'

# Open VS Code in WSL
alias c.='code .'
