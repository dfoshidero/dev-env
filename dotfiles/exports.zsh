# Environment exports — managed by dev-env repo

# Repo path (override in ~/.dev-env-local.zsh if cloned elsewhere)
export DEV_ENV_REPO="${DEV_ENV_REPO:-$HOME/dev-env}"

# UTF-8 locale (required for Powerlevel10k icons and glyphs)
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

export EDITOR="${EDITOR:-code --wait}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"

# Default code directory
export CODE_DIR="$HOME/code"

# Go
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"

# Java (mise sets JAVA_HOME when active)
if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# uv — use mise-managed Python
export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-only-managed}"

# Less
export LESS='-R'

# fzf defaults
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# AWS CLI pager
export AWS_PAGER=""

# Kubernetes
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
