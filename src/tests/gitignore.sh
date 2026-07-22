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

  if git -C "$REPO_ROOT" check-ignore --no-index -q "$path"; then
    fail "expected path to be tracked by git rules: $path"
  fi
}

assert_ignored() {
  local path="$1"

  if ! git -C "$REPO_ROOT" check-ignore --no-index -q "$path"; then
    fail "expected path to be ignored by git rules: $path"
  fi
}

main() {
  assert_not_ignored ".scripts"
  assert_not_ignored "AGENTS.md"
  assert_not_ignored ".scripts/AGENTS.md"
  assert_not_ignored ".scripts/README.md"
  assert_not_ignored "skills/commit-changes/SKILL.md"
  assert_ignored "dist/skills/commit-changes/SKILL.md"
  assert_not_ignored "src/install.sh"
  assert_not_ignored "src/update.sh"
  assert_not_ignored "src/tests/install.sh"
  assert_not_ignored "src/tests/update.sh"
  assert_not_ignored "skills/skill-master/AGENTS.md"

  printf 'PASS: gitignore.sh\n'
}

main "$@"
