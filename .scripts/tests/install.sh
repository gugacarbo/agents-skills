#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
INSTALLER="$REPO_ROOT/.scripts/install.sh"
FIXTURE_SKILL="install-test-fixture-skill"
FIXTURE_DIR="$REPO_ROOT/$FIXTURE_SKILL"

LAST_OUTPUT=''

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

assert_not_exists() {
  local path="$1"

  if [ -e "$path" ]; then
    fail "expected path to be absent: $path"
  fi
}

assert_contains() {
  local needle="$1"

  case "$LAST_OUTPUT" in
    *"$needle"*) ;;
    *)
      fail "expected output to contain: $needle"
      ;;
  esac
}

run_capture() {
  local output_file="$1"
  shift

  set +e
  "$@" >"$output_file" 2>&1
  local status=$?
  set -e

  LAST_OUTPUT=$(cat "$output_file")
  return "$status"
}

setup_fixture_skill() {
  mkdir -p "$FIXTURE_DIR"
  printf '%s\n' '---' 'name: install-test-fixture-skill' '---' >"$FIXTURE_DIR/SKILL.md"
}

cleanup_fixture_skill() {
  rm -rf "$FIXTURE_DIR"
}

test_explicit_path_installs_to_target() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/work"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" "$INSTALLER" -p "$tmp/custom-skills"
  )

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
}

test_cwd_skills_installs_in_place() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/skills"

  (
    cd "$tmp/skills"
    run_capture "$tmp/output.log" "$INSTALLER"
  )

  assert_exists "$tmp/skills/$FIXTURE_SKILL/SKILL.md"
}

test_repo_flag_yes_installs_local_default() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/project/work"
  git -C "$tmp/project" init >/dev/null 2>&1

  (
    cd "$tmp/project/work"
    run_capture "$tmp/output.log" "$INSTALLER" --yes
  )

  assert_exists "$tmp/project/.agents/skills/$FIXTURE_SKILL/SKILL.md"
}

test_global_fallback_still_requires_confirmation_with_yes() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/work"

  (
    cd "$tmp/work"
    if run_capture "$tmp/output.log" env HOME="$tmp/home" "$INSTALLER" --yes; then
      fail "expected global fallback without confirmation to fail"
    fi
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_not_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL"
  assert_contains "global"
}

test_global_flag_prompts_even_with_yes() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/work"

  (
    cd "$tmp/work"
    printf 'y\n' | env HOME="$tmp/home" "$INSTALLER" --global --yes >"$tmp/output.log" 2>&1
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL/SKILL.md"
  assert_contains "global"
}

main() {
  trap cleanup_fixture_skill EXIT
  setup_fixture_skill

  assert_exists "$REPO_ROOT/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$INSTALLER"

  test_explicit_path_installs_to_target
  test_cwd_skills_installs_in_place
  test_repo_flag_yes_installs_local_default
  test_global_fallback_still_requires_confirmation_with_yes
  test_global_flag_prompts_even_with_yes

  printf 'PASS: install.sh\n'
}

main "$@"
