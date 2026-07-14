#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
INSTALLER="$REPO_ROOT/src/install.sh"
BUILD_SCRIPT="$REPO_ROOT/src/build.sh"
FIXTURE_SKILL="install-test-fixture-skill"
FIXTURE_DIR="$REPO_ROOT/skills/$FIXTURE_SKILL"
BUILT_FIXTURE_DIR="$REPO_ROOT/dist/skills/$FIXTURE_SKILL"

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
  sh "$BUILD_SCRIPT" >/dev/null
}

cleanup_fixture_skill() {
  rm -rf "$FIXTURE_DIR"
  rm -rf "$BUILT_FIXTURE_DIR"
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

test_non_repo_cwd_prompt_installs_with_yes() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/work"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" "$INSTALLER" --yes
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_exists "$tmp/work/$FIXTURE_SKILL/SKILL.md"
  assert_contains "diretorio atual"
}

test_non_repo_cwd_without_confirmation_does_not_install() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/work"
  printf 'n\n' >"$tmp/tty-input"

  (
    cd "$tmp/work"
    if run_capture "$tmp/output.log" env HOME="$tmp/home" AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" "$INSTALLER" < /dev/null; then
      fail "expected cwd prompt without confirmation to fail"
    fi
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_not_exists "$tmp/work/$FIXTURE_SKILL/SKILL.md"
  assert_not_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL"
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

setup_fixture_git_source() {
  local source_dir="$1"

  git -C "$source_dir" init -b main >/dev/null 2>&1
  cp -R "$REPO_ROOT/src" "$source_dir/src"
  cp "$REPO_ROOT/skills.sh" "$source_dir/skills.sh"
  mkdir -p "$source_dir/dist/skills/$FIXTURE_SKILL"
  printf '%s\n' '---' 'name: install-test-fixture-skill' '---' >"$source_dir/dist/skills/$FIXTURE_SKILL/SKILL.md"
  git -C "$source_dir" add . >/dev/null 2>&1
  git -C "$source_dir" -c user.email=test@example.com -c user.name=test commit -m "fixture" >/dev/null 2>&1
}

test_init_clones_repo_to_target() {
  local tmp source_dir clone_dest
  tmp=$(mktemp -d)
  source_dir="$tmp/source"
  clone_dest="$tmp/cloned-skills"
  mkdir -p "$tmp/work" "$source_dir"

  setup_fixture_git_source "$source_dir"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" env AGENTS_SKILLS_REPO_URL="file://$source_dir" AGENTS_SKILLS_REF=main \
      "$INSTALLER" --init --path "$clone_dest"
  )

  assert_exists "$clone_dest/dist/skills/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$clone_dest/.git"
  git -C "$clone_dest" rev-parse --is-inside-work-tree >/dev/null
}

test_init_merges_nonempty_destination_with_confirmation() {
  local tmp source_dir clone_dest
  tmp=$(mktemp -d)
  source_dir="$tmp/source"
  clone_dest="$tmp/cloned-skills"
  mkdir -p "$tmp/work" "$source_dir" "$clone_dest"
  printf 'occupied\n' >"$clone_dest/existing.txt"
  printf 'y\n' >"$tmp/tty-input"

  setup_fixture_git_source "$source_dir"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" env AGENTS_SKILLS_REPO_URL="file://$source_dir" AGENTS_SKILLS_REF=main \
      AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" \
      "$INSTALLER" --init --path "$clone_dest" < /dev/null
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_exists "$clone_dest/existing.txt"
  assert_exists "$clone_dest/dist/skills/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$clone_dest/.git"
  assert_contains "mantendo os arquivos existentes na worktree"
  grep -qx 'occupied' "$clone_dest/existing.txt"
}

test_instructions_copies_readme_to_target() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/work"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" "$INSTALLER" --instructions -p "$tmp/custom-skills"
  )

  assert_exists "$tmp/custom-skills/README.md"
  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
  grep -q 'agents-skills' "$tmp/custom-skills/README.md"
}

test_instructions_keeps_existing_readme() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/work" "$tmp/custom-skills"
  printf 'custom readme\n' >"$tmp/custom-skills/README.md"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" "$INSTALLER" --instructions -p "$tmp/custom-skills"
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  grep -qx 'custom readme' "$tmp/custom-skills/README.md"
  assert_contains "README.md ja existe"
}

test_init_nonempty_without_confirmation_cancels() {
  local tmp source_dir clone_dest
  tmp=$(mktemp -d)
  source_dir="$tmp/source"
  clone_dest="$tmp/cloned-skills"
  mkdir -p "$tmp/work" "$source_dir" "$clone_dest"
  printf 'occupied\n' >"$clone_dest/existing.txt"
  printf 'n\n' >"$tmp/tty-input"

  setup_fixture_git_source "$source_dir"

  (
    cd "$tmp/work"
    if run_capture "$tmp/output.log" env AGENTS_SKILLS_REPO_URL="file://$source_dir" AGENTS_SKILLS_REF=main \
      AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" \
      "$INSTALLER" --init --path "$clone_dest" < /dev/null; then
      fail "expected non-empty --init without confirmation to fail"
    fi
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_exists "$clone_dest/existing.txt"
  assert_not_exists "$clone_dest/.git"
  assert_not_exists "$clone_dest/dist/skills/$FIXTURE_SKILL/SKILL.md"
}

test_confirmation_reads_from_terminal_when_stdin_is_pipe() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/work"
  printf 'y\n' >"$tmp/tty-input"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" env HOME="$tmp/home" AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" "$INSTALLER" --global < /dev/null
  )

  assert_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL/SKILL.md"
}

main() {
  trap cleanup_fixture_skill EXIT
  setup_fixture_skill

  assert_exists "$REPO_ROOT/dist/skills/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$INSTALLER"

  test_explicit_path_installs_to_target
  test_cwd_skills_installs_in_place
  test_repo_flag_yes_installs_local_default
  test_non_repo_cwd_prompt_installs_with_yes
  test_non_repo_cwd_without_confirmation_does_not_install
  test_global_flag_prompts_even_with_yes
  test_init_clones_repo_to_target
  test_instructions_copies_readme_to_target
  test_instructions_keeps_existing_readme
  test_init_merges_nonempty_destination_with_confirmation
  test_init_nonempty_without_confirmation_cancels
  test_confirmation_reads_from_terminal_when_stdin_is_pipe

  printf 'PASS: install.sh\n'
}

main "$@"
