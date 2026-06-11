#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
ORCHESTRATOR="$REPO_ROOT/skills.sh"
FIXTURE_SKILL="orchestrator-test-fixture-skill"
FIXTURE_DIR="$REPO_ROOT/$FIXTURE_SKILL"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_exists() {
  local path="$1"

  if [ ! -e "$path" ]; then
    fail "expected path to exist: $path"
  fi
}

setup_fixture_skill() {
  mkdir -p "$FIXTURE_DIR"
  printf '%s\n' '---' 'name: orchestrator-test-fixture-skill' '---' >"$FIXTURE_DIR/SKILL.md"
}

cleanup_fixture_skill() {
  rm -rf "$FIXTURE_DIR"
}

test_install_subcommand_delegates_to_inner_script() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/work"

  (
    cd "$tmp/work"
    "$ORCHESTRATOR" install --path "$tmp/custom-skills" >"$tmp/output.log" 2>&1
  )

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
}

main() {
  trap cleanup_fixture_skill EXIT
  setup_fixture_skill

  assert_exists "$REPO_ROOT/.scripts/install.sh"
  assert_exists "$ORCHESTRATOR"

  test_install_subcommand_delegates_to_inner_script

  printf 'PASS: orchestrator.sh\n'
}

main "$@"
