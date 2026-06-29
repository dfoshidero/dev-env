#!/usr/bin/env bash
# new-project.sh — scaffold a project from templates
# Usage: ./scripts/new-project.sh <type> <name> [category]
# Example: ./scripts/new-project.sh python my-api personal
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap.sh"

usage() {
  cat <<EOF
Usage: new-project.sh <type> <name> [category]

Types:
  python      -> ~/code/<category>/<name>
  react       -> ~/code/<category>/<name>
  go          -> ~/code/go/<name>
  java        -> ~/code/java/<name>
  c           -> ~/code/c/<name>

Category defaults to 'personal' for python/react.

Examples:
  ./scripts/new-project.sh python my-api personal
  ./scripts/new-project.sh react dashboard work
  ./scripts/new-project.sh go scraper
  ./scripts/new-project.sh java spring-api
  ./scripts/new-project.sh c parser
EOF
  exit 1
}

[[ $# -ge 2 ]] || usage

TYPE="$1"
NAME="$2"
CATEGORY="${3:-personal}"

declare -A TEMPLATE_MAP=(
  [python]="python"
  [react]="react-vite"
  [go]="go-cli"
  [java]="java-gradle"
  [c]="c-cmake"
)

[[ -n "${TEMPLATE_MAP[$TYPE]:-}" ]] || usage

TEMPLATE="${DEV_ENV_TEMPLATES}/${TEMPLATE_MAP[$TYPE]}"
[[ -d "$TEMPLATE" ]] || die "Template not found: $TEMPLATE"

case "$TYPE" in
  go)    DEST="${HOME}/code/go/${NAME}" ;;
  java)  DEST="${HOME}/code/java/${NAME}" ;;
  c)     DEST="${HOME}/code/c/${NAME}" ;;
  *)     DEST="${HOME}/code/${CATEGORY}/${NAME}" ;;
esac

[[ ! -e "$DEST" ]] || die "Destination already exists: $DEST"

mkdir -p "$(dirname "$DEST")"
cp -a "$TEMPLATE/." "$DEST"

# Rename placeholders in python template
if [[ "$TYPE" == "python" && -d "${DEST}/src/my_api" ]]; then
  mv "${DEST}/src/my_api" "${DEST}/src/${NAME//-/_}"
  find "$DEST" -type f -exec sed -i "s/my-api/${NAME}/g; s/my_api/${NAME//-/_}/g" {} +
fi

if [[ "$TYPE" == "react" ]]; then
  find "$DEST" -type f -exec sed -i "s/my-app/${NAME}/g" {} +
fi

log_ok "Created $TYPE project at $DEST"
echo ""
echo "Next steps:"
case "$TYPE" in
  python)
    echo "  cd $DEST && mise install && uv sync && uv run python -m ${NAME//-/_}.main"
    ;;
  react)
    echo "  cd $DEST && mise install && npm install && npm run dev"
    ;;
  go)
    echo "  cd $DEST && mise install && go run ./cmd/my-cli"
    ;;
  java)
    echo "  cd $DEST && mise install && ./gradlew run"
    ;;
  c)
    echo "  cd $DEST && cmake -S . -B build && cmake --build build && ./build/my_app"
    ;;
esac
