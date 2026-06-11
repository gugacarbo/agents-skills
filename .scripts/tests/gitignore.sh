#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_not_ignored() {
  local path="$1"

  if git -C "$REPO_ROOT" check-ignore -q "$path"; then
    fail "expected path to be tracked by git rules: $path"
  fi
}

main() {
  assert_not_ignored ".scripts"
  assert_not_ignored "AGENTS.md"
  assert_not_ignored ".scripts/AGENTS.md"
  assert_not_ignored ".scripts/README.md"
  assert_not_ignored ".scripts/install.sh"
  assert_not_ignored ".scripts/update.sh"
  assert_not_ignored ".scripts/tests/install.sh"
  assert_not_ignored ".scripts/tests/update.sh"
  assert_not_ignored "skill-creator/AGENTS.md"

  printf 'PASS: gitignore.sh\n'
}

main "$@"
