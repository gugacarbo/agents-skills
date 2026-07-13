#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
BUILD_SCRIPT="$REPO_ROOT/.scripts/build.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_exists() {
  local path="$1"

  [ -e "$path" ] || fail "expected path to exist: $path"
}

assert_not_exists() {
  local path="$1"

  [ ! -e "$path" ] || fail "expected path to be absent: $path"
}

test_build_copies_skills_and_removes_stale_output() {
  local tmp output
  tmp=$(mktemp -d)
  output="$tmp/generated-skills"
  mkdir -p "$output/stale-skill"
  printf 'stale\n' >"$output/stale-skill/SKILL.md"

  AGENTS_SKILLS_BUILD_OUTPUT="$output" sh "$BUILD_SCRIPT"

  assert_exists "$output/commit-changes/SKILL.md"
  assert_exists "$output/super-planning/SKILL.md"
  assert_not_exists "$output/stale-skill"
}

main() {
  assert_exists "$BUILD_SCRIPT"
  test_build_copies_skills_and_removes_stale_output

  printf 'PASS: build.sh\n'
}

main "$@"
