#!/usr/bin/env bash
# setup-powerlevel10k.sh — Meslo font, terminal font config, and p10k activation
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

P10K_MEDIA_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
FONT_DIR="${HOME}/.local/share/fonts/MesloLGS-NF"
FONTS=(
  "MesloLGS NF Regular.ttf"
  "MesloLGS NF Bold.ttf"
  "MesloLGS NF Italic.ttf"
  "MesloLGS NF Bold Italic.ttf"
)

wsl_detected() {
  [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null
}

windows_username() {
  powershell.exe -NoProfile -Command '[Environment]::UserName' 2>/dev/null | tr -d '\r'
}

install_meslo_fonts_linux() {
  mkdir -p "$FONT_DIR"

  for font in "${FONTS[@]}"; do
    local dest="${FONT_DIR}/${font}"
    local url_encoded="${font// /%20}"

    if [[ -f "$dest" ]]; then
      log_ok "Already have ${font}"
      continue
    fi

    log_info "Downloading ${font}..."
    curl -fsSL -o "$dest" "${P10K_MEDIA_BASE}/${url_encoded}"
    log_ok "Installed ${font}"
  done

  if command_exists fc-cache; then
    fc-cache -f "${HOME}/.local/share/fonts" 2>/dev/null || true
  fi

  log_ok "Meslo Nerd Font installed -> $FONT_DIR"
}

install_meslo_fonts_windows() {
  local win_user win_fonts ps_install

  win_user="$(windows_username)" || true
  [[ -n "${win_user:-}" ]] || {
    log_warn "Could not detect Windows username; skipping Windows font install"
    return 0
  }

  win_fonts="/mnt/c/Users/${win_user}/AppData/Local/Microsoft/Windows/Fonts"
  if [[ ! -d "/mnt/c/Users/${win_user}" ]]; then
    log_warn "Windows profile not found at /mnt/c/Users/${win_user}; skipping Windows font install"
    return 0
  fi

  if ! command_exists powershell.exe; then
    log_warn "powershell.exe not found; copying fonts without Windows registration"
    mkdir -p "$win_fonts"
    for font in "${FONTS[@]}"; do
      local src="${FONT_DIR}/${font}"
      [[ -f "$src" ]] || continue
      cp -f "$src" "${win_fonts}/${font}"
    done
    return 0
  fi

  ps_install="${DEV_ENV_SCRIPTS}/install-windows-fonts.ps1"
  [[ -f "$ps_install" ]] || die "Missing script: $ps_install"

  log_info "Registering Meslo Nerd Font on Windows (required for Windows Terminal glyphs)..."
  if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps_install")" -FontsDir "$(wslpath -w "$FONT_DIR")"; then
    log_ok "Meslo Nerd Font registered on Windows"
  else
    log_warn "Windows font registration failed — glyphs may show as boxes until font is installed"
  fi
}

configure_windows_terminal() {
  local ps1="${DEV_ENV_SCRIPTS}/configure-windows-terminal-font.ps1"

  [[ -f "$ps1" ]] || die "Missing script: $ps1"

  if ! command_exists powershell.exe; then
    log_warn "powershell.exe not found; set Windows Terminal font to MesloLGS NF manually"
    return 0
  fi

  log_info "Configuring Windows Terminal font..."
  if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps1")"; then
    log_ok "Windows Terminal font configured"
  else
    log_warn "Windows Terminal font config failed — set font face to MesloLGS NF in Settings → Defaults → Appearance"
  fi
}

configure_vscode_terminal_font() {
  local win_user settings tmp

  if ! command_exists jq; then
    return 0
  fi

  win_user="$(windows_username)" || true
  [[ -n "${win_user:-}" ]] || return 0

  settings="/mnt/c/Users/${win_user}/AppData/Roaming/Code/User/settings.json"
  mkdir -p "$(dirname "$settings")"

  if [[ ! -f "$settings" ]]; then
    echo '{}' > "$settings"
  fi

  tmp="$(mktemp)"
  if jq '.["terminal.integrated.fontFamily"] = "MesloLGS NF, MesloLGS NF Regular, monospace"' \
    "$settings" > "$tmp"; then
    mv "$tmp" "$settings"
    log_ok "VS Code terminal font set to MesloLGS NF"
  else
    rm -f "$tmp"
    log_warn "Could not update VS Code terminal font"
  fi
}

install_meslo_fonts_linux

if wsl_detected; then
  install_meslo_fonts_windows
  configure_windows_terminal
  configure_vscode_terminal_font
  log_info "Close and reopen Windows Terminal tabs for font changes to take effect"
else
  log_info "Not running in WSL — Linux fonts installed; configure your terminal font to MesloLGS NF"
fi

log_ok "Powerlevel10k font setup complete"

# Preload instant prompt and apply repo-managed ~/.p10k.zsh (non-interactive)
if command_exists zsh && [[ -f "${HOME}/.p10k.zsh" ]]; then
  log_info "Activating Powerlevel10k configuration..."
  POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true zsh -lic 'exit' 2>/dev/null || true
  log_ok "Powerlevel10k configuration active"
elif [[ ! -f "${HOME}/.p10k.zsh" ]]; then
  log_warn "~/.p10k.zsh not found — link dotfiles before setup-powerlevel10k.sh"
fi
