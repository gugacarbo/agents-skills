#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
DEV_SCRIPT="$REPO_ROOT/src/dev.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_exists() {
  local path="$1"

  [ -e "$path" ] || fail "expected path to exist: $path"
}

test_dev_builds_without_publishing_globally() {
  local tmp build_output
  tmp=$(mktemp -d)
  build_output="$tmp/build-output"

  env \
    HOME="$tmp/home" \
    AGENTS_SKILLS_BUILD_OUTPUT="$build_output" \
    AGENTS_SKILLS_WATCH_ONCE=1 \
    sh "$DEV_SCRIPT" > "$tmp/output.log" 2>&1

  assert_exists "$build_output/commit-changes/SKILL.md"
  [ ! -e "$tmp/home/.agents/skills" ] || fail 'dev must not publish to ~/.agents/skills'
}

wait_for_content() {
  local path="$1"
  local expected="$2"
  local attempt

  for attempt in $(seq 1 50); do
    if [ -f "$path" ] && grep -Fq "$expected" "$path"; then
      return 0
    fi
    sleep 0.1
  done

  fail "timed out waiting for $path to contain: $expected"
}

test_dev_rebuilds_after_a_source_change() {
  local tmp project build_output dev_pid
  tmp=$(mktemp -d)
  project="$tmp/project"
  build_output="$tmp/build-output"
  mkdir -p "$project/src" "$project/skills/example-skill"
  cp "$REPO_ROOT/src/build.sh" "$project/src/build.sh"
  cp "$REPO_ROOT/src/dev.sh" "$project/src/dev.sh"
  chmod +x "$project/src/build.sh"
  printf '%s\n' '---' 'name: example-skill' 'version: initial' '---' > "$project/skills/example-skill/SKILL.md"
  env AGENTS_SKILLS_BUILD_OUTPUT="$build_output" sh "$project/src/dev.sh" > "$tmp/output.log" 2>&1 &
  dev_pid=$!

  wait_for_content "$build_output/example-skill/SKILL.md" 'version: initial'
  printf '%s\n' 'version: updated' >> "$project/skills/example-skill/SKILL.md"
  wait_for_content "$build_output/example-skill/SKILL.md" 'version: updated'

  kill -TERM "$dev_pid"
  wait "$dev_pid"
}

main() {
  assert_exists "$DEV_SCRIPT"
  test_dev_builds_without_publishing_globally
  test_dev_rebuilds_after_a_source_change

  printf 'PASS: dev.sh\n'
}

main "$@"
