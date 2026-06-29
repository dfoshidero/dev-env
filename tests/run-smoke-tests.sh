#!/usr/bin/env bash
# run-smoke-tests.sh — end-to-end language toolchain smoke tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../bootstrap.sh
source "${SCRIPT_DIR}/../bootstrap.sh"

export PATH="${HOME}/.local/bin:${PATH}"
[[ -f "${HOME}/.config/mise/config.toml" ]] && eval "$(mise activate bash 2>/dev/null)" || true

TEST_DIR="$(mktemp -d /tmp/dev-env-smoke-XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

PASS=0
FAIL=0

run_test() {
  local name="$1"
  shift
  log_info "Testing $name..."
  if "$@"; then
    log_ok "$name passed"
    PASS=$((PASS + 1))
  else
    log_error "$name FAILED"
    FAIL=$((FAIL + 1))
  fi
}

test_python() {
  local dir="${TEST_DIR}/python"
  mkdir -p "$dir/src"
  cd "$dir"

  cat > pyproject.toml <<'EOF'
[project]
name = "smoke-test"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
EOF

  cat > src/smoke_test/__init__.py <<'EOF'
def hello() -> str:
    return "python-ok"
EOF

  cat > src/smoke_test/__main__.py <<'EOF'
from smoke_test import hello
print(hello())
EOF

  uv sync --quiet
  output="$(uv run python -m smoke_test)"
  [[ "$output" == "python-ok" ]]
}

test_node() {
  local dir="${TEST_DIR}/node"
  mkdir -p "$dir"
  cd "$dir"

  cat > index.js <<'EOF'
console.log('node-ok');
EOF

  output="$(node index.js)"
  [[ "$output" == "node-ok" ]]
  command -v npm &>/dev/null
}

test_go() {
  local dir="${TEST_DIR}/go"
  mkdir -p "$dir"
  cd "$dir"

  go mod init smoke-test
  cat > main.go <<'EOF'
package main
import "fmt"
func main() { fmt.Println("go-ok") }
EOF

  output="$(go run main.go)"
  [[ "$output" == "go-ok" ]]
}

test_java() {
  local dir="${TEST_DIR}/java"
  mkdir -p "$dir"
  cd "$dir"

  cat > Main.java <<'EOF'
public class Main {
    public static void main(String[] args) {
        System.out.println("java-ok");
    }
}
EOF

  javac Main.java
  output="$(java Main)"
  [[ "$output" == "java-ok" ]]
}

test_c() {
  local dir="${TEST_DIR}/c"
  mkdir -p "$dir"
  cd "$dir"

  cat > main.c <<'EOF'
#include <stdio.h>
int main(void) {
    printf("c-ok\n");
    return 0;
}
EOF

  gcc -o main main.c
  output="$(./main)"
  [[ "$output" == "c-ok" ]]
}

test_cpp() {
  local dir="${TEST_DIR}/cpp"
  mkdir -p "$dir"
  cd "$dir"

  cat > main.cpp <<'EOF'
#include <iostream>
int main() {
    std::cout << "cpp-ok" << std::endl;
    return 0;
}
EOF

  if command -v clang++ &>/dev/null; then
    clang++ -o main main.cpp
  else
    g++ -o main main.cpp
  fi
  output="$(./main)"
  [[ "$output" == "cpp-ok" ]]
}

echo ""
log_info "Running language smoke tests in $TEST_DIR"
echo ""

run_test "Python (uv + mise)" test_python
run_test "Node.js" test_node
run_test "Go" test_go
run_test "Java" test_java
run_test "C (gcc)" test_c
run_test "C++ (clang++/g++)" test_cpp

echo ""
echo "----------------------------------------"
echo "  Smoke tests passed: $PASS  |  failed: $FAIL"
echo "----------------------------------------"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

log_ok "All smoke tests passed"
exit 0
