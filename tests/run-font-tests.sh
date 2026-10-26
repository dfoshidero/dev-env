#!/usr/bin/env bash
# run-font-tests.sh — tests for the font, editor and Windows Terminal setup (no WSL or Windows needed)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=../scripts/setup-powerlevel10k.sh
source "${REPO_ROOT}/scripts/setup-powerlevel10k.sh"

TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dev-env-font-tests-XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

PASS=0
FAIL=0
SKIP=0

# Each test runs in a subshell so errexit applies and overrides stay local.
run_test() {
  local name="$1"
  local status
  shift
  log_info "Testing $name..."
  set +e
  (set -e; "$@")
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    log_ok "$name passed"
    PASS=$((PASS + 1))
  else
    log_error "$name FAILED"
    FAIL=$((FAIL + 1))
  fi
}

skip_test() {
  log_warn "Skipping $1 ($2)"
  SKIP=$((SKIP + 1))
}

assert_eq() {
  if [[ "$1" != "$2" ]]; then
    log_error "$3: expected '$2', got '$1'"
    return 1
  fi
}

make_font_archive() {
  local src="${TEST_DIR}/archive-src"
  local files=("${FONTS[@]}" "JetBrainsMonoNerdFontPropo-Regular.ttf" "OFL.txt")
  mkdir -p "$src"
  for font in "${files[@]}"; do
    echo "fake ${font}" > "${src}/${font}"
  done
  # Same layout as the release archive: files at the top level, no ./ prefix.
  tar -cJf "${TEST_DIR}/JetBrainsMono.tar.xz" -C "$src" "${files[@]}"
  echo "file://${TEST_DIR}/JetBrainsMono.tar.xz"
}

use_fake_windows() {
  WINDOWS_USERS_ROOT="${TEST_DIR}/Users"
  windows_username() { echo "tester"; }
}

test_shell_syntax() {
  local f
  for f in "${REPO_ROOT}"/*.sh "${REPO_ROOT}"/scripts/*.sh "${REPO_ROOT}"/tests/*.sh; do
    bash -n "$f"
  done
}

test_shellcheck() {
  shellcheck -S warning -x \
    "${REPO_ROOT}/scripts/setup-powerlevel10k.sh" \
    "${REPO_ROOT}/tests/run-font-tests.sh"
}

test_color_schemes() {
  local f
  local keys='["name","cursorColor","selectionBackground","background","foreground",
    "black","red","green","yellow","blue","purple","cyan","white",
    "brightBlack","brightRed","brightGreen","brightYellow","brightBlue","brightPurple","brightCyan","brightWhite"]'

  for f in "${REPO_ROOT}"/config/windows-terminal/*.json; do
    jq -e --argjson keys "$keys" '(keys - $keys) == [] and ($keys - keys) == []' "$f" >/dev/null
    jq -e '[.[] | select(startswith("#") | not)] == [.name]' "$f" >/dev/null
  done

  assert_eq "$(jq -r .name "${REPO_ROOT}/config/windows-terminal/catppuccin-latte.json")" "Catppuccin Latte" "latte name"
  assert_eq "$(jq -r .name "${REPO_ROOT}/config/windows-terminal/catppuccin-mocha.json")" "Catppuccin Mocha" "mocha name"
}

test_linux_font_install() {
  local font
  HOME="${TEST_DIR}/home"
  local archive
  FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMono-NF"
  archive="$(make_font_archive)"

  FONT_ARCHIVE_URL="$archive" install_fonts_linux >/dev/null
  for font in "${FONTS[@]}"; do
    [[ -f "${FONT_DIR}/${font}" ]]
  done
  assert_eq "$(find "$FONT_DIR" -type f -name '*.ttf' | wc -l | tr -d ' ')" "${#FONTS[@]}" "only the wanted fonts are extracted"
  [[ ! -e "${FONT_DIR}/OFL.txt" ]]

  # Already installed: no download, so a broken URL must not matter.
  FONT_ARCHIVE_URL="file://${TEST_DIR}/missing.tar.xz" install_fonts_linux >/dev/null

  # One font missing: only that one is fetched again.
  rm "${FONT_DIR}/${FONTS[0]}"
  FONT_ARCHIVE_URL="$archive" install_fonts_linux >/dev/null
  [[ -f "${FONT_DIR}/${FONTS[0]}" ]]
}

test_linux_font_install_fails_loudly() {
  HOME="${TEST_DIR}/home-fail"
  FONT_DIR="${HOME}/fonts"

  if (FONT_ARCHIVE_URL="file://${TEST_DIR}/missing.tar.xz" install_fonts_linux >/dev/null 2>&1); then
    log_error "expected install_fonts_linux to fail for a missing archive"
    return 1
  fi
}

test_real_font_archive() {
  local font
  HOME="${TEST_DIR}/home-real"
  FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMono-NF"

  install_fonts_linux >/dev/null
  for font in "${FONTS[@]}"; do
    [[ -s "${FONT_DIR}/${font}" ]]
  done
}

test_editor_fonts() {
  local settings
  use_fake_windows
  settings="${WINDOWS_USERS_ROOT}/tester/AppData/Roaming/Code/User/settings.json"
  mkdir -p "$(dirname "$settings")"
  echo '{"editor.fontSize": 14, "terminal.integrated.fontFamily": "MesloLGS NF"}' > "$settings"

  configure_editor_fonts >/dev/null

  assert_eq "$(jq -r '.["editor.fontFamily"]' "$settings")" "$EDITOR_FONT_FAMILY" "editor font"
  assert_eq "$(jq -r '.["terminal.integrated.fontFamily"]' "$settings")" "$EDITOR_FONT_FAMILY" "terminal font"
  assert_eq "$(jq -r '.["editor.fontSize"]' "$settings")" "14" "other settings kept"
  [[ ! -e "${WINDOWS_USERS_ROOT}/tester/AppData/Roaming/Cursor" ]]
}

test_editor_fonts_creates_settings() {
  local settings
  use_fake_windows
  settings="${WINDOWS_USERS_ROOT}/tester/AppData/Roaming/Cursor/User/settings.json"
  mkdir -p "$(dirname "$settings")"

  configure_editor_fonts >/dev/null

  assert_eq "$(jq -r '.["editor.fontFamily"]' "$settings")" "$EDITOR_FONT_FAMILY" "editor font"
}

test_editor_fonts_leaves_comments_alone() {
  local settings before
  use_fake_windows
  settings="${WINDOWS_USERS_ROOT}/tester/AppData/Roaming/Code/User/settings.json"
  mkdir -p "$(dirname "$settings")"
  printf '{\n  // keep me\n  "editor.fontSize": 14\n}\n' > "$settings"
  before="$(cat "$settings")"

  configure_editor_fonts >/dev/null

  assert_eq "$(cat "$settings")" "$before" "settings.json with comments is untouched"
}

test_windows_terminal() {
  pwsh -NoProfile -File "${REPO_ROOT}/tests/windows/test-configure-windows-terminal.ps1"
}

echo ""
log_info "Running font and terminal tests in $TEST_DIR"
echo ""

run_test "shell syntax" test_shell_syntax
if command_exists shellcheck; then
  run_test "shellcheck" test_shellcheck
else
  skip_test "shellcheck" "shellcheck not installed"
fi
run_test "Catppuccin colour schemes" test_color_schemes
run_test "Linux font install" test_linux_font_install
run_test "Linux font install fails loudly" test_linux_font_install_fails_loudly
if [[ "${DEV_ENV_TEST_NETWORK:-0}" == 1 ]]; then
  run_test "real Nerd Fonts archive" test_real_font_archive
else
  skip_test "real Nerd Fonts archive" "set DEV_ENV_TEST_NETWORK=1 to download it"
fi
run_test "VS Code fonts" test_editor_fonts
run_test "Cursor settings created" test_editor_fonts_creates_settings
run_test "settings.json with comments" test_editor_fonts_leaves_comments_alone
if command_exists pwsh; then
  run_test "Windows Terminal (pwsh)" test_windows_terminal
else
  skip_test "Windows Terminal (pwsh)" "pwsh not installed"
fi

echo ""
echo "----------------------------------------"
echo "  Font tests passed: $PASS  |  failed: $FAIL  |  skipped: $SKIP"
echo "----------------------------------------"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

log_ok "All font tests passed"
