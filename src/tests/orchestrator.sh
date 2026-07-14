#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
ORCHESTRATOR="$REPO_ROOT/skills.sh"
BUILD_SCRIPT="$REPO_ROOT/src/build.sh"
FIXTURE_SKILL="orchestrator-test-fixture-skill"
FIXTURE_DIR="$REPO_ROOT/skills/$FIXTURE_SKILL"
BUILT_FIXTURE_DIR="$REPO_ROOT/dist/skills/$FIXTURE_SKILL"

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
  sh "$BUILD_SCRIPT" >/dev/null
}

cleanup_fixture_skill() {
  rm -rf "$FIXTURE_DIR"
  rm -rf "$BUILT_FIXTURE_DIR"
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

test_build_subcommand_delegates_to_inner_script() {
  local tmp output
  tmp=$(mktemp -d)
  output="$tmp/generated-skills"

  AGENTS_SKILLS_BUILD_OUTPUT="$output" "$ORCHESTRATOR" build >"$tmp/output.log" 2>&1

  assert_exists "$output/commit-changes/SKILL.md"
}

test_dev_subcommand_publishes_once() {
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
    "$ORCHESTRATOR" dev >"$tmp/output.log" 2>&1

  assert_exists "$target/commit-changes/SKILL.md"
}

test_update_subcommand_delegates_to_inner_script() {
  local tmp archive_root archive_path target
  tmp=$(mktemp -d)
  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"
  target="$tmp/custom-skills"

  mkdir -p "$archive_root/dist/skills/$FIXTURE_SKILL" "$archive_root/src" "$target/dist/skills/$FIXTURE_SKILL" "$tmp/work"
  printf '%s\n' '---' 'name: orchestrator-test-fixture-skill' '---' 'version: remote' >"$archive_root/dist/skills/$FIXTURE_SKILL/SKILL.md"
  printf '%s\n' "#!/usr/bin/env sh" >"$archive_root/skills.sh"
  printf '%s\n' "#!/usr/bin/env sh" >"$archive_root/src/install.sh"
  printf '%s\n' 'version: local' >"$target/dist/skills/$FIXTURE_SKILL/SKILL.md"
  tar -czf "$archive_path" -C "$tmp/archive-src" agents-skills-main

  (
    cd "$tmp/work"
    AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" "$ORCHESTRATOR" update --path "$target" --yes >"$tmp/output.log" 2>&1
  )

  grep -q 'version: remote' "$target/dist/skills/$FIXTURE_SKILL/SKILL.md"
}

main() {
  trap cleanup_fixture_skill EXIT
  setup_fixture_skill

  assert_exists "$REPO_ROOT/src/install.sh"
  assert_exists "$REPO_ROOT/src/update.sh"
  assert_exists "$ORCHESTRATOR"

  test_install_subcommand_delegates_to_inner_script
  test_build_subcommand_delegates_to_inner_script
  test_dev_subcommand_publishes_once
  test_update_subcommand_delegates_to_inner_script

  printf 'PASS: orchestrator.sh\n'
}

main "$@"
