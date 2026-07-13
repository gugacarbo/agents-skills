#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P
)
BUILD_SCRIPT="$REPO_ROOT/src/build.sh"

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
  local tmp output target
  tmp=$(mktemp -d)
  output="$tmp/generated-skills"
  target="$tmp/installed-skills"
  mkdir -p "$output/stale-skill"
  printf 'stale\n' >"$output/stale-skill/SKILL.md"

  AGENTS_SKILLS_BUILD_OUTPUT="$output" \
    AGENTS_SKILLS_BUILD_TARGET="$target" \
    sh "$BUILD_SCRIPT"

  assert_exists "$output/commit-changes/SKILL.md"
  assert_exists "$output/super-planning/SKILL.md"
  assert_not_exists "$output/stale-skill"
  assert_not_exists "$output/skill-master/dev"
  assert_not_exists "$output/super-planning/dev"
  assert_not_exists "$output/task-completion-notifier/tests"
  assert_exists "$target/commit-changes/SKILL.md"
  assert_exists "$target/super-planning/SKILL.md"
  assert_not_exists "$target/skill-master/dev"
  assert_not_exists "$target/super-planning/dev"
  assert_not_exists "$target/task-completion-notifier/tests"
}

main() {
  assert_exists "$BUILD_SCRIPT"
  test_build_copies_skills_and_removes_stale_output

  printf 'PASS: build.sh\n'
}

main "$@"
