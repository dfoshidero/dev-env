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

  # 2. Shell (zsh, Oh My Zsh, Powerlevel10k theme)
  run_script "${DEV_ENV_SCRIPTS}/install-ohmyzsh.sh"

  # 3. Dotfiles (link ~/.p10k.zsh before p10k setup)
  run_script "${DEV_ENV_SCRIPTS}/install-dotfiles.sh"

  # 4. Meslo font, Windows Terminal font, and p10k activation
  run_script "${DEV_ENV_SCRIPTS}/setup-powerlevel10k.sh"

  # 5. mise + tool versions
  run_script "${DEV_ENV_SCRIPTS}/install-mise.sh"

  # 6. uv (Python project environments)
  run_script "${DEV_ENV_SCRIPTS}/install-uv.sh"

  # 7. AWS CLI
  run_script "${DEV_ENV_SCRIPTS}/install-aws.sh"

  # 8. Kubernetes tools (via mise)
  run_script "${DEV_ENV_SCRIPTS}/install-kubernetes.sh"

  # 9. Docker CLI helpers
  run_script "${DEV_ENV_SCRIPTS}/install-docker-tools.sh"

  # 10. Folder structure
  run_script "${DEV_ENV_SCRIPTS}/create-folders.sh"

  # 11. Git + SSH (interactive)
  run_script "${DEV_ENV_SCRIPTS}/configure-git.sh"

  # 12. Verify installations
  run_script "${DEV_ENV_SCRIPTS}/verify.sh"

  # 13. Optional smoke tests
  echo ""
  if prompt_yes_no "Run language smoke tests now?" "y"; then
    run_script "${DEV_ENV_TESTS}/run-smoke-tests.sh"
  fi

  echo ""
  log_ok "Installation complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Open a project:      cd ~/code/personal && code ."
  echo "  2. Change prompt:       p10k configure   # optional — only if you want a different style"
  echo "  3. Re-run anytime:      ./install.sh"
  echo ""
  if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    log_info "Close and reopen Windows Terminal tabs if prompt icons look wrong"
  fi
  log_info "Restarting shell..."
  exec zsh -l
}

main "$@"
