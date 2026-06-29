#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

FOLDERS_FILE="${DEV_ENV_CONFIG}/folders.txt"
[[ -f "$FOLDERS_FILE" ]] || die "Missing folders file: $FOLDERS_FILE"

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"
  [[ -n "$line" ]] || continue
  target="${HOME}/${line}"
  if [[ -d "$target" ]]; then
    log_ok "Folder exists: $target"
  else
    mkdir -p "$target"
    log_ok "Created folder: $target"
  fi
done < "$FOLDERS_FILE"

log_ok "Folder structure ready"
