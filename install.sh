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

  # 3. Dotfiles
  run_script "${DEV_ENV_SCRIPTS}/install-dotfiles.sh"

  # 4. Meslo font and Windows Terminal font (run `p10k configure` manually)
  run_script "${DEV_ENV_SCRIPTS}/setup-powerlevel10k.sh"

  # 5. mise + tool versions
  run_script "${DEV_ENV_SCRIPTS}/install-mise.sh"

  # 6. uv (Python project environments)
  run_script "${DEV_ENV_SCRIPTS}/install-uv.sh"

  # 6b. Homebrew (Linux CLI formulae)
  run_script "${DEV_ENV_SCRIPTS}/install-homebrew.sh"

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
  echo "  1. Restart your terminal: close this window and open a new one"
  echo "  2. Open a project:        cd ~/code/personal && code ."
  echo "  3. Re-run anytime:        ./install.sh"
  echo ""
  echo -e "${BOLD}========================================================${NC}"
  echo -e "${BOLD}  ⚠  RESTART YOUR TERMINAL NOW${NC}"
  echo -e "${BOLD}========================================================${NC}"
  echo ""
  echo -e "${BOLD}Close this window completely and open a new terminal.${NC}"
  echo "This reloads your shell, fonts, PATH, and terminal settings so"
  echo "new commands, prompt glyphs, icons, and completions render correctly."
  echo ""
  echo "To re-open your WSL environment, open a new terminal and run:"
  echo "  wsl -d Ubuntu"
  echo ""
}

main "$@"
