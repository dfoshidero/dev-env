#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

GITCONFIG_TEMPLATE="${DEV_ENV_CONFIG}/gitconfig"
SSH_DIR="${HOME}/.ssh"
GIT_INCLUDE="${HOME}/.config/git/dev-env.defaults"

mkdir -p "$SSH_DIR" "$(dirname "$GIT_INCLUDE")"
chmod 700 "$SSH_DIR"

# Apply non-secret git defaults via include
if [[ -f "$GITCONFIG_TEMPLATE" ]]; then
  cp "$GITCONFIG_TEMPLATE" "$GIT_INCLUDE"
  if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$GIT_INCLUDE"; then
    git config --global --add include.path "$GIT_INCLUDE"
  fi
  log_ok "Applied git defaults via include.path -> $GIT_INCLUDE"
fi

# Interactive identity
current_name="$(git config --global user.name 2>/dev/null || true)"
current_email="$(git config --global user.email 2>/dev/null || true)"

if [[ -z "$current_name" ]]; then
  read -r -p "Git user.name: " git_name
  [[ -n "$git_name" ]] && git config --global user.name "$git_name"
else
  log_ok "Git user.name already set: $current_name"
fi

if [[ -z "$current_email" ]]; then
  read -r -p "Git user.email: " git_email
  [[ -n "$git_email" ]] && git config --global user.email "$git_email"
else
  log_ok "Git user.email already set: $current_email"
fi

# SSH key generation
KEY_FILE="${SSH_DIR}/id_ed25519"
if [[ -f "${KEY_FILE}" ]]; then
  log_ok "SSH key already exists: ${KEY_FILE}.pub"
else
  if prompt_yes_no "Generate a new ed25519 SSH key?" "y"; then
    read -r -p "SSH key comment (usually your email): " key_comment
    ssh-keygen -t ed25519 -C "${key_comment:-$(git config --global user.email)}" -f "$KEY_FILE" -N ""
    log_ok "SSH key generated"
  fi
fi

if [[ -f "${KEY_FILE}.pub" ]]; then
  echo ""
  log_info "Your public SSH key (add to GitHub -> Settings -> SSH keys):"
  echo "----------------------------------------"
  cat "${KEY_FILE}.pub"
  echo "----------------------------------------"
  echo ""
  read -r -p "Press Enter after adding the key to GitHub (or skip)..."
fi

# Optional: paste additional public keys for authorized_keys
if prompt_yes_no "Paste additional public SSH key(s) for authorized_keys?" "n"; then
  AUTH_KEYS="${SSH_DIR}/authorized_keys"
  touch "$AUTH_KEYS"
  chmod 600 "$AUTH_KEYS"
  echo "Paste public key(s), one per line. Empty line to finish:"
  while IFS= read -r pubkey; do
    [[ -z "$pubkey" ]] && break
    if [[ "$pubkey" =~ ^ssh- ]]; then
      if ! grep -qF "$pubkey" "$AUTH_KEYS" 2>/dev/null; then
        echo "$pubkey" >> "$AUTH_KEYS"
        log_ok "Added key to authorized_keys"
      else
        log_ok "Key already in authorized_keys"
      fi
    else
      log_warn "Skipped invalid key line (must start with ssh-)"
    fi
  done
  chmod 600 "$AUTH_KEYS"
fi

chmod 600 "${KEY_FILE}" 2>/dev/null || true
chmod 644 "${KEY_FILE}.pub" 2>/dev/null || true

log_ok "Git and SSH configuration complete"
