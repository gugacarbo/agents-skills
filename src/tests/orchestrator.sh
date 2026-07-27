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
FIXTURE_DIR="$REPO_ROOT/skills/$FIXTURE_SKILL"
BUILD_TARGET=''

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
  printf '%s\n' '---' 'name: orchestrator-test-fixture-skill' '---' > "$FIXTURE_DIR/SKILL.md"
  BUILD_TARGET=$(mktemp -d)
  AGENTS_SKILLS_BUILD_TARGET="$BUILD_TARGET" sh "$REPO_ROOT/src/build.sh" > /dev/null
}

cleanup_fixture_skill() {
  rm -rf "$FIXTURE_DIR"
  [ -z "$BUILD_TARGET" ] || rm -rf "$BUILD_TARGET"
}

test_install_subcommand_delegates_to_inner_script() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/work"

  (
    cd "$tmp/work"
    "$ORCHESTRATOR" install --path "$tmp/custom-skills" > "$tmp/output.log" 2>&1
  )

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
}

test_build_subcommand_delegates_to_inner_script() {
  local tmp output target
  tmp=$(mktemp -d)
  output="$tmp/generated-skills"
  target="$tmp/installed-skills"

  AGENTS_SKILLS_BUILD_OUTPUT="$output" \
    AGENTS_SKILLS_BUILD_TARGET="$target" \
    "$ORCHESTRATOR" build > "$tmp/output.log" 2>&1

  assert_exists "$output/commit-changes/SKILL.md"
  assert_exists "$target/commit-changes/SKILL.md"
}

test_dev_subcommand_builds_once_without_publishing() {
  local tmp build_output
  tmp=$(mktemp -d)
  build_output="$tmp/build-output"

  env \
    AGENTS_SKILLS_BUILD_OUTPUT="$build_output" \
    AGENTS_SKILLS_WATCH_ONCE=1 \
    "$ORCHESTRATOR" dev > "$tmp/output.log" 2>&1

  assert_exists "$build_output/commit-changes/SKILL.md"
}

test_update_subcommand_delegates_to_inner_script() {
  local tmp archive_root archive_path target
  tmp=$(mktemp -d)
  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"
  target="$tmp/custom-skills"

  mkdir -p "$archive_root/dist/skills/$FIXTURE_SKILL" "$archive_root/src" "$target/dist/skills/$FIXTURE_SKILL" "$tmp/work"
  printf '%s\n' '---' 'name: orchestrator-test-fixture-skill' '---' 'version: remote' > "$archive_root/dist/skills/$FIXTURE_SKILL/SKILL.md"
  printf '%s\n' "#!/usr/bin/env sh" > "$archive_root/skills.sh"
  printf '%s\n' "#!/usr/bin/env sh" > "$archive_root/src/install.sh"
  printf '%s\n' 'version: local' > "$target/dist/skills/$FIXTURE_SKILL/SKILL.md"
  tar -czf "$archive_path" -C "$tmp/archive-src" agents-skills-main

  (
    cd "$tmp/work"
    AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" "$ORCHESTRATOR" update --path "$target" --yes > "$tmp/output.log" 2>&1
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
  test_dev_subcommand_builds_once_without_publishing
  test_update_subcommand_delegates_to_inner_script

  printf 'PASS: orchestrator.sh\n'
}

main "$@"
