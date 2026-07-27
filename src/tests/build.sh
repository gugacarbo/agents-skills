#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
BUILD_SCRIPT="$REPO_ROOT/src/build.sh"
TEST_FIXTURE=''

cleanup() {
  [ -z "$TEST_FIXTURE" ] || rm -rf "$TEST_FIXTURE"
}

trap cleanup EXIT

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
  local tmp output target fixture fixture_name ignored_path
  tmp=$(mktemp -d)
  output="$tmp/generated-skills"
  target="$tmp/installed-skills"
  fixture="$REPO_ROOT/skills/build-test-fixture-$$"
  fixture_name=${fixture##*/}
  TEST_FIXTURE=$fixture

  mkdir -p \
    "$fixture/node_modules/package" \
    "$fixture/.pnpm-store" \
    "$fixture/build" \
    "$fixture/out" \
    "$fixture/.next" \
    "$fixture/.nuxt" \
    "$fixture/.idea" \
    "$fixture/logs" \
    "$fixture/coverage" \
    "$fixture/.cache" \
    "$fixture/__pycache__" \
    "$fixture/.turbo" \
    "$fixture/.code-flow"
  printf 'fixture\n' > "$fixture/SKILL.md"
  printf 'keep\n' > "$fixture/.gitignore"
  printf 'keep\n' > "$fixture/.env.example"
  printf 'ignored\n' > "$fixture/.env"
  printf 'ignored\n' > "$fixture/.env.local"
  printf 'ignored\n' > "$fixture/swap.swp"
  printf 'ignored\n' > "$fixture/swap.swo"
  printf 'ignored\n' > "$fixture/backup~"
  printf 'ignored\n' > "$fixture/.DS_Store"
  printf 'ignored\n' > "$fixture/Thumbs.db"
  printf 'ignored\n' > "$fixture/build.log"
  printf 'ignored\n' > "$fixture/state.tsbuildinfo"
  printf 'ignored\n' > "$fixture/__pycache__/module.pyc"
  mkdir -p "$output/stale-skill"
  printf 'stale\n' > "$output/stale-skill/SKILL.md"

  AGENTS_SKILLS_BUILD_OUTPUT="$output" \
    AGENTS_SKILLS_BUILD_TARGET="$target" \
    sh "$BUILD_SCRIPT"

  assert_exists "$output/commit-changes/SKILL.md"
  assert_exists "$output/code-flow/SKILL.md"
  assert_not_exists "$output/stale-skill"
  assert_not_exists "$output/skill-master/dev"
  assert_not_exists "$output/code-flow/tests"
  assert_not_exists "$output/task-completion-notifier/tests"
  assert_not_exists "$output/skill-master/package.json"
  assert_not_exists "$output/code-flow/package.json"
  assert_not_exists "$output/task-completion-notifier/package.json"
  assert_exists "$output/$fixture_name/SKILL.md"
  assert_exists "$output/$fixture_name/.gitignore"
  assert_exists "$output/$fixture_name/.env.example"
  for ignored_path in \
    node_modules .pnpm-store build out .next .nuxt .idea logs coverage .cache \
    __pycache__ .turbo .code-flow .env .env.local swap.swp swap.swo backup~ \
    .DS_Store Thumbs.db build.log state.tsbuildinfo; do
    assert_not_exists "$output/$fixture_name/$ignored_path"
  done
  assert_exists "$target/commit-changes/SKILL.md"
  mkdir -p "$target/code-toolbox"
  printf 'legacy\n' > "$target/code-toolbox/SKILL.md"
  mkdir -p "$target/code-flow/templates"
  printf 'stale\n' > "$target/code-flow/templates/obsolete-template.md"
  mkdir -p "$target/external-skill"
  printf 'external\n' > "$target/external-skill/SKILL.md"
  printf 'hidden\n' > "$target/.external-config"

  AGENTS_SKILLS_BUILD_OUTPUT="$output" \
    AGENTS_SKILLS_BUILD_TARGET="$target" \
    sh "$BUILD_SCRIPT"

  assert_exists "$target/code-flow/SKILL.md"
  assert_not_exists "$target/code-toolbox"
  assert_not_exists "$target/code-flow/templates/obsolete-template.md"
  assert_not_exists "$target/external-skill"
  assert_not_exists "$target/.external-config"
  assert_not_exists "$target/skill-master/dev"
  assert_not_exists "$target/code-flow/tests"
  assert_not_exists "$target/task-completion-notifier/tests"
  assert_not_exists "$target/skill-master/package.json"
  assert_not_exists "$target/code-flow/package.json"
  assert_not_exists "$target/task-completion-notifier/package.json"
  assert_not_exists "$target/$fixture_name/__pycache__"
}

test_build_rejects_output_as_deployment_target() {
  local tmp output
  tmp=$(mktemp -d)
  output="$tmp/skills"

  if AGENTS_SKILLS_BUILD_OUTPUT="$output" \
    AGENTS_SKILLS_BUILD_TARGET="$output" \
    sh "$BUILD_SCRIPT" > /dev/null 2>&1; then
    fail 'build accepted the output directory as its deployment target'
  fi
}

main() {
  assert_exists "$BUILD_SCRIPT"
  test_build_copies_skills_and_removes_stale_output
  test_build_rejects_output_as_deployment_target

  printf 'PASS: build.sh\n'
}

main "$@"
