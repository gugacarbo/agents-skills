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

test_dev_uses_default_output_when_reply_is_empty() {
  local tmp prompt_input build_output
  tmp=$(mktemp -d)
  prompt_input="$tmp/prompt-input"
  build_output="$tmp/build-output"
  printf '\n' >"$prompt_input"

  env \
    HOME="$tmp/home" \
    AGENTS_SKILLS_PROMPT_INPUT="$prompt_input" \
    AGENTS_SKILLS_BUILD_OUTPUT="$build_output" \
    AGENTS_SKILLS_WATCH_ONCE=1 \
    sh "$DEV_SCRIPT" >"$tmp/output.log" 2>&1

  assert_exists "$build_output/commit-changes/SKILL.md"
  assert_exists "$tmp/home/.agents/skills/commit-changes/SKILL.md"
}

test_dev_uses_the_prompted_output_path() {
  local tmp prompt_input build_output target
  tmp=$(mktemp -d)
  prompt_input="$tmp/prompt-input"
  build_output="$tmp/build-output"
  target="$tmp/published-skills"
  printf '%s\n' "$target" >"$prompt_input"

  env \
    AGENTS_SKILLS_PROMPT_INPUT="$prompt_input" \
    AGENTS_SKILLS_BUILD_OUTPUT="$build_output" \
    AGENTS_SKILLS_WATCH_ONCE=1 \
    sh "$DEV_SCRIPT" >"$tmp/output.log" 2>&1

  assert_exists "$target/code-toolbox/SKILL.md"
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
  local tmp project prompt_input target dev_pid
  tmp=$(mktemp -d)
  project="$tmp/project"
  prompt_input="$tmp/prompt-input"
  target="$tmp/published-skills"
  mkdir -p "$project/src" "$project/skills/example-skill"
  cp "$REPO_ROOT/src/build.sh" "$project/src/build.sh"
  cp "$REPO_ROOT/src/dev.sh" "$project/src/dev.sh"
  chmod +x "$project/src/build.sh"
  printf '%s\n' '---' 'name: example-skill' 'version: initial' '---' >"$project/skills/example-skill/SKILL.md"
  printf '%s\n' "$target" >"$prompt_input"

  env AGENTS_SKILLS_PROMPT_INPUT="$prompt_input" sh "$project/src/dev.sh" >"$tmp/output.log" 2>&1 &
  dev_pid=$!

  wait_for_content "$target/example-skill/SKILL.md" 'version: initial'
  printf '%s\n' 'version: updated' >>"$project/skills/example-skill/SKILL.md"
  wait_for_content "$target/example-skill/SKILL.md" 'version: updated'

  kill -TERM "$dev_pid"
  wait "$dev_pid"
}

main() {
  assert_exists "$DEV_SCRIPT"
  test_dev_uses_default_output_when_reply_is_empty
  test_dev_uses_the_prompted_output_path
  test_dev_rebuilds_after_a_source_change

  printf 'PASS: dev.sh\n'
}

main "$@"
