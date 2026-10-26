#!/usr/bin/env bash
# setup-powerlevel10k.sh — JetBrains Mono Nerd Font, Catppuccin terminal colours and editor fonts (run `p10k configure` manually)
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

NERD_FONTS_VERSION="v3.5.1"
FONT_ARCHIVE_URL="${FONT_ARCHIVE_URL:-https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/JetBrainsMono.tar.xz}"
FONT_DIR="${FONT_DIR:-${HOME}/.local/share/fonts/JetBrainsMono-NF}"
WINDOWS_USERS_ROOT="${WINDOWS_USERS_ROOT:-/mnt/c/Users}"
FONTS=(
  "JetBrainsMonoNerdFont-Regular.ttf"
  "JetBrainsMonoNerdFont-Bold.ttf"
  "JetBrainsMonoNerdFont-Italic.ttf"
  "JetBrainsMonoNerdFont-BoldItalic.ttf"
  "JetBrainsMonoNerdFontMono-Regular.ttf"
  "JetBrainsMonoNerdFontMono-Bold.ttf"
  "JetBrainsMonoNerdFontMono-Italic.ttf"
  "JetBrainsMonoNerdFontMono-BoldItalic.ttf"
)

# The legacy console only lists strictly monospaced fonts, so it gets the Mono variant.
TERMINAL_FONT_FACE="JetBrainsMono Nerd Font"
CONSOLE_FONT_FACE="JetBrainsMono NFM"
EDITOR_FONT_FAMILY="'JetBrainsMono Nerd Font', 'JetBrainsMono NF', Consolas, monospace"

wsl_detected() {
  [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null
}

windows_username() {
  powershell.exe -NoProfile -Command '[Environment]::UserName' 2>/dev/null | tr -d '\r'
}

install_fonts_linux() {
  local font tmp
  local missing=()

  mkdir -p "$FONT_DIR"

  for font in "${FONTS[@]}"; do
    [[ -f "${FONT_DIR}/${font}" ]] || missing+=("$font")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_ok "JetBrains Mono Nerd Font already installed -> $FONT_DIR"
    return 0
  fi

  tmp="$(mktemp -d)"
  log_info "Downloading JetBrains Mono Nerd Font ${NERD_FONTS_VERSION}..."
  if ! curl -fsSL -o "${tmp}/JetBrainsMono.tar.xz" "$FONT_ARCHIVE_URL" \
    || ! tar -xJf "${tmp}/JetBrainsMono.tar.xz" -C "$FONT_DIR" "${missing[@]}"; then
    rm -rf "$tmp"
    die "Could not install JetBrains Mono Nerd Font from $FONT_ARCHIVE_URL"
  fi
  rm -rf "$tmp"

  if command_exists fc-cache; then
    fc-cache -f "${HOME}/.local/share/fonts" 2>/dev/null || true
  fi

  log_ok "JetBrains Mono Nerd Font installed -> $FONT_DIR"
}

install_fonts_windows() {
  local win_user ps_install

  win_user="$(windows_username)" || true
  [[ -n "${win_user:-}" ]] || {
    log_warn "Could not detect Windows username; skipping Windows font install"
    return 0
  }

  if [[ ! -d "${WINDOWS_USERS_ROOT}/${win_user}" ]]; then
    log_warn "Windows profile not found at ${WINDOWS_USERS_ROOT}/${win_user}; skipping Windows font install"
    return 0
  fi

  if ! command_exists powershell.exe; then
    log_warn "powershell.exe not found; skipping Windows font registration"
    return 0
  fi

  ps_install="${DEV_ENV_SCRIPTS_WINDOWS}/install-windows-fonts.ps1"
  [[ -f "$ps_install" ]] || die "Missing script: $ps_install"

  log_info "Registering JetBrains Mono Nerd Font on Windows (required for Windows Terminal glyphs)..."
  if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps_install")" -FontsDir "$(wslpath -w "$FONT_DIR")"; then
    log_ok "JetBrains Mono Nerd Font registered on Windows"
  else
    log_warn "Windows font registration failed — glyphs may show as boxes until font is installed"
  fi
}

configure_windows_terminal() {
  local ps1="${DEV_ENV_SCRIPTS_WINDOWS}/configure-windows-terminal.ps1"

  [[ -f "$ps1" ]] || die "Missing script: $ps1"

  if ! command_exists powershell.exe; then
    log_warn "powershell.exe not found; set Windows Terminal font to ${TERMINAL_FONT_FACE} manually"
    return 0
  fi

  log_info "Configuring Windows Terminal font and Catppuccin colour schemes..."
  if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps1")" \
    -FontFace "$TERMINAL_FONT_FACE" -SchemesDir "$(wslpath -w "${DEV_ENV_CONFIG}/windows-terminal")"; then
    log_ok "Windows Terminal configured"
  else
    log_warn "Windows Terminal config failed — set font face to ${TERMINAL_FONT_FACE} in Settings → Defaults → Appearance"
  fi
}

configure_windows_console_font() {
  local ps1="${DEV_ENV_SCRIPTS_WINDOWS}/configure-windows-console-font.ps1"

  [[ -f "$ps1" ]] || die "Missing script: $ps1"

  if ! command_exists powershell.exe; then
    log_warn "powershell.exe not found; set your PowerShell/cmd console font to ${CONSOLE_FONT_FACE} manually"
    return 0
  fi

  log_info "Configuring Windows console (PowerShell/cmd) font..."
  if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps1")" -FontFace "$CONSOLE_FONT_FACE"; then
    log_ok "Windows console font set to ${CONSOLE_FONT_FACE} (affects new console windows)"
  else
    log_warn "Windows console font config failed — set it via the console title-bar → Properties → Font"
  fi
}

# Set the editor and integrated-terminal fonts for editors that store settings
# under AppData/Roaming (VS Code -> Code, Cursor -> Cursor). Only touches
# editors that are actually installed.
configure_editor_fonts() {
  local win_user editor user_dir settings tmp
  local editors=("Code" "Cursor")

  if ! command_exists jq; then
    log_warn "jq not found; skipping editor font config (VS Code / Cursor)"
    return 0
  fi

  win_user="$(windows_username)" || true
  [[ -n "${win_user:-}" ]] || return 0

  for editor in "${editors[@]}"; do
    user_dir="${WINDOWS_USERS_ROOT}/${win_user}/AppData/Roaming/${editor}/User"
    settings="${user_dir}/settings.json"

    # Skip editors that are not installed (no User dir).
    [[ -d "$user_dir" ]] || continue

    if [[ ! -f "$settings" ]]; then
      echo '{}' > "$settings"
    fi

    tmp="$(mktemp)"
    if jq --arg font "$EDITOR_FONT_FAMILY" \
      '.["editor.fontFamily"] = $font | .["terminal.integrated.fontFamily"] = $font' \
      "$settings" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$settings"
      log_ok "${editor} editor and terminal font set to ${TERMINAL_FONT_FACE}"
    else
      rm -f "$tmp"
      log_warn "Could not update ${editor} fonts (settings.json may contain comments) — set them manually"
    fi
  done
}

main() {
  install_fonts_linux

  if wsl_detected; then
    install_fonts_windows
    configure_windows_terminal
    configure_windows_console_font
    configure_editor_fonts
    log_info "Close and reopen Windows Terminal / PowerShell / VS Code / Cursor for font changes to take effect"
  else
    log_info "Not running in WSL — Linux fonts installed; configure your terminal font to ${TERMINAL_FONT_FACE}"
  fi

  log_ok "Powerlevel10k font setup complete"

  if [[ ! -f "${HOME}/.p10k.zsh" ]]; then
    log_info "No ~/.p10k.zsh found — run 'p10k configure' to set up your prompt"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
