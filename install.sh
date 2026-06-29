#!/usr/bin/env bash
# install.sh — single entrypoint for dev-env provisioning
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap.sh
source "${SCRIPT_DIR}/bootstrap.sh"

main() {
  echo ""
  echo "========================================"
  echo "  dev-env — Development Environment IaC"
  echo "========================================"
  echo ""

  require_linux
  require_wsl2

  prompt_language_selection

  # 1. Apt packages
  run_script "${DEV_ENV_SCRIPTS}/install-apt-packages.sh"

  # 2. Shell (zsh, Oh My Zsh, Powerlevel10k)
  run_script "${DEV_ENV_SCRIPTS}/install-ohmyzsh.sh"

  # 2b. Meslo Nerd Font + Windows Terminal / VS Code font config
  run_script "${DEV_ENV_SCRIPTS}/install-p10k-fonts.sh"

  # 3. mise + tool versions
  run_script "${DEV_ENV_SCRIPTS}/install-mise.sh"

  # 4. uv (Python project environments)
  run_script "${DEV_ENV_SCRIPTS}/install-uv.sh"

  # 5. AWS CLI
  run_script "${DEV_ENV_SCRIPTS}/install-aws.sh"

  # 6. Kubernetes tools (via mise)
  run_script "${DEV_ENV_SCRIPTS}/install-kubernetes.sh"

  # 7. Docker CLI helpers
  run_script "${DEV_ENV_SCRIPTS}/install-docker-tools.sh"

  # 8. Dotfiles
  run_script "${DEV_ENV_SCRIPTS}/install-dotfiles.sh"

  # 9. Folder structure
  run_script "${DEV_ENV_SCRIPTS}/create-folders.sh"

  # 10. Git + SSH (interactive)
  run_script "${DEV_ENV_SCRIPTS}/configure-git.sh"

  # 11. Verify installations
  run_script "${DEV_ENV_SCRIPTS}/verify.sh"

  # 12. Optional smoke tests
  echo ""
  if prompt_yes_no "Run language smoke tests now?" "y"; then
    run_script "${DEV_ENV_TESTS}/run-smoke-tests.sh"
  fi

  echo ""
  log_ok "Installation complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Tweak prompt:        p10k configure"
  echo "  2. Open a project:      cd ~/code/personal && code ."
  echo "  3. Re-run anytime:      ./install.sh"
  echo ""
  log_info "Restarting shell..."
  exec zsh -l
}

main "$@"
