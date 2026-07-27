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
BUILD_TARGET=''

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
  "$@" > "$output_file" 2>&1
  local status=$?
  set -e

  LAST_OUTPUT=$(cat "$output_file")
  return "$status"
}

setup_fixture_skill() {
  mkdir -p "$FIXTURE_DIR"
  printf '%s\n' '---' 'name: install-test-fixture-skill' '---' > "$FIXTURE_DIR/SKILL.md"
  BUILD_TARGET=$(mktemp -d)
  AGENTS_SKILLS_BUILD_TARGET="$BUILD_TARGET" sh "$BUILD_SCRIPT" > /dev/null
}

cleanup_fixture_skill() {
  rm -rf "$FIXTURE_DIR"
  rm -rf "$BUILT_FIXTURE_DIR"
  [ -z "$BUILD_TARGET" ] || rm -rf "$BUILD_TARGET"
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

test_offers_installation_in_claude_after_primary_destination() {
  local tmp primary claude_target
  tmp=$(mktemp -d)
  primary="$tmp/custom-skills"
  claude_target="$tmp/home/.claude/skills"
  printf 'y\n' > "$tmp/tty-input"

  run_capture "$tmp/output.log" env HOME="$tmp/home" \
    AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" \
    "$INSTALLER" --path "$primary" < /dev/null

  assert_exists "$primary/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$claude_target/$FIXTURE_SKILL/SKILL.md"
  assert_contains "Também deseja instalar as skills em $claude_target"
}

test_declining_claude_installation_preserves_primary_destination() {
  local tmp primary claude_target
  tmp=$(mktemp -d)
  primary="$tmp/custom-skills"
  claude_target="$tmp/home/.claude/skills"
  printf 'n\n' > "$tmp/tty-input"

  run_capture "$tmp/output.log" env HOME="$tmp/home" \
    AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" \
    "$INSTALLER" --path "$primary" < /dev/null

  assert_exists "$primary/$FIXTURE_SKILL/SKILL.md"
  assert_not_exists "$claude_target"
  assert_contains "Instalação em $claude_target não solicitada"
}

test_does_not_offer_claude_when_it_is_the_primary_destination() {
  local tmp claude_target
  tmp=$(mktemp -d)
  claude_target="$tmp/home/.claude/skills"

  run_capture "$tmp/output.log" env HOME="$tmp/home" \
    "$INSTALLER" --path "$claude_target" < /dev/null

  assert_exists "$claude_target/$FIXTURE_SKILL/SKILL.md"
  case "$LAST_OUTPUT" in
    *"Também deseja instalar as skills"*) fail 'Claude installation prompt appeared for the primary destination' ;;
  esac
}

test_installs_one_selected_skill() {
  local tmp
  tmp=$(mktemp -d)

  run_capture "$tmp/output.log" "$INSTALLER" "$FIXTURE_SKILL" --path "$tmp/custom-skills"

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
  assert_not_exists "$tmp/custom-skills/commit-changes"
  assert_contains "Instalação concluída com 1 skill(s)"
}

test_installs_multiple_selected_skills() {
  local tmp
  tmp=$(mktemp -d)

  run_capture "$tmp/output.log" "$INSTALLER" "$FIXTURE_SKILL" commit-changes --path "$tmp/custom-skills"

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$tmp/custom-skills/commit-changes/SKILL.md"
  assert_not_exists "$tmp/custom-skills/find-docs"
  assert_contains "Instalação concluída com 2 skill(s)"
}

test_rejects_unknown_skill_before_copying() {
  local tmp
  tmp=$(mktemp -d)

  if run_capture "$tmp/output.log" "$INSTALLER" "$FIXTURE_SKILL" missing-skill --path "$tmp/custom-skills"; then
    fail "expected unknown skill selection to fail"
  fi

  assert_not_exists "$tmp/custom-skills"
  assert_contains "Skill não encontrada: missing-skill"
}

test_duplicate_selection_is_installed_once() {
  local tmp
  tmp=$(mktemp -d)

  run_capture "$tmp/output.log" "$INSTALLER" "$FIXTURE_SKILL" "$FIXTURE_SKILL" --path "$tmp/custom-skills"

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
  assert_contains "Instalação concluída com 1 skill(s)"
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

test_fresh_removes_existing_skills_and_preserves_non_skill_files() {
  local tmp target
  tmp=$(mktemp -d)
  target="$tmp/custom-skills"
  mkdir -p "$target/old-skill" "$target/.hidden-old-skill"
  printf '%s\n' '---' 'name: old-skill' '---' > "$target/old-skill/SKILL.md"
  printf '%s\n' '---' 'name: hidden-old-skill' '---' > "$target/.hidden-old-skill/SKILL.md"
  printf 'keep me\n' > "$target/README.md"

  run_capture "$tmp/output.log" "$INSTALLER" --fresh --path "$target"

  assert_not_exists "$target/old-skill"
  assert_not_exists "$target/.hidden-old-skill"
  assert_exists "$target/$FIXTURE_SKILL/SKILL.md"
  grep -qx 'keep me' "$target/README.md"
  assert_contains "--fresh removeu 2 skill(s)"
}

test_fresh_with_selection_preserves_other_skills() {
  local tmp target
  tmp=$(mktemp -d)
  target="$tmp/custom-skills"
  mkdir -p "$target/$FIXTURE_SKILL" "$target/other-skill"
  printf '%s\n' '---' "name: $FIXTURE_SKILL" '---' 'stale' > "$target/$FIXTURE_SKILL/SKILL.md"
  printf '%s\n' '---' 'name: other-skill' '---' > "$target/other-skill/SKILL.md"

  run_capture "$tmp/output.log" "$INSTALLER" --fresh "$FIXTURE_SKILL" --path "$target"

  assert_exists "$target/$FIXTURE_SKILL/SKILL.md"
  assert_exists "$target/other-skill/SKILL.md"
  if grep -q 'stale' "$target/$FIXTURE_SKILL/SKILL.md"; then
    fail "expected selected skill to be replaced"
  fi
  assert_contains "--fresh removeu 1 skill(s)"
}

test_fresh_rejects_init() {
  local tmp
  tmp=$(mktemp -d)

  if run_capture "$tmp/output.log" "$INSTALLER" --fresh --init --path "$tmp/custom-skills"; then
    fail "expected --fresh with --init to fail"
  fi

  assert_contains "--fresh não pode ser usado com --init"
}

test_selection_rejects_init() {
  local tmp
  tmp=$(mktemp -d)

  if run_capture "$tmp/output.log" "$INSTALLER" "$FIXTURE_SKILL" --init --path "$tmp/custom-skills"; then
    fail "expected skill selection with --init to fail"
  fi

  assert_contains "A seleção de skills não pode ser usada com --init"
}

test_non_skills_directory_defaults_to_global_target() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/project/work"
  printf 'y\n' > "$tmp/tty-input"
  git -C "$tmp/project" init > /dev/null 2>&1

  (
    cd "$tmp/project/work"
    run_capture "$tmp/output.log" env HOME="$tmp/home" AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" "$INSTALLER" < /dev/null
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL/SKILL.md"
  assert_not_exists "$tmp/project/.agents/skills/$FIXTURE_SKILL"
  assert_contains "destino padrão global"
}

test_non_skills_directory_decline_does_not_install() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/work"
  printf 'n\n' > "$tmp/tty-input"

  (
    cd "$tmp/work"
    if run_capture "$tmp/output.log" env HOME="$tmp/home" AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" "$INSTALLER" < /dev/null; then
      fail "expected declined global installation to fail"
    fi
  )

  assert_not_exists "$tmp/work/$FIXTURE_SKILL/SKILL.md"
  assert_not_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL"
}

test_global_flag_prompts_even_with_yes() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/work"

  (
    cd "$tmp/work"
    printf 'y\n' | env HOME="$tmp/home" "$INSTALLER" --global --yes > "$tmp/output.log" 2>&1
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_exists "$tmp/home/.agents/skills/$FIXTURE_SKILL/SKILL.md"
  assert_contains "global"
}

setup_fixture_git_source() {
  local source_dir="$1"

  git -C "$source_dir" init -b main > /dev/null 2>&1
  cp -R "$REPO_ROOT/src" "$source_dir/src"
  cp "$REPO_ROOT/skills.sh" "$source_dir/skills.sh"
  mkdir -p "$source_dir/dist/skills/$FIXTURE_SKILL"
  printf '%s\n' '---' 'name: install-test-fixture-skill' '---' > "$source_dir/dist/skills/$FIXTURE_SKILL/SKILL.md"
  git -C "$source_dir" add . > /dev/null 2>&1
  git -C "$source_dir" -c user.email=test@example.com -c user.name=test commit -m "fixture" > /dev/null 2>&1
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
  git -C "$clone_dest" rev-parse --is-inside-work-tree > /dev/null
}

test_init_merges_nonempty_destination_with_confirmation() {
  local tmp source_dir clone_dest
  tmp=$(mktemp -d)
  source_dir="$tmp/source"
  clone_dest="$tmp/cloned-skills"
  mkdir -p "$tmp/work" "$source_dir" "$clone_dest"
  printf 'occupied\n' > "$clone_dest/existing.txt"
  printf 'y\n' > "$tmp/tty-input"

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
  printf 'custom readme\n' > "$tmp/custom-skills/README.md"

  (
    cd "$tmp/work"
    run_capture "$tmp/output.log" "$INSTALLER" --instructions -p "$tmp/custom-skills"
  )

  LAST_OUTPUT=$(cat "$tmp/output.log")
  grep -qx 'custom readme' "$tmp/custom-skills/README.md"
  assert_contains "README.md já existe"
}

test_init_nonempty_without_confirmation_cancels() {
  local tmp source_dir clone_dest
  tmp=$(mktemp -d)
  source_dir="$tmp/source"
  clone_dest="$tmp/cloned-skills"
  mkdir -p "$tmp/work" "$source_dir" "$clone_dest"
  printf 'occupied\n' > "$clone_dest/existing.txt"
  printf 'n\n' > "$tmp/tty-input"

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
  printf 'y\n' > "$tmp/tty-input"

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
  test_offers_installation_in_claude_after_primary_destination
  test_declining_claude_installation_preserves_primary_destination
  test_does_not_offer_claude_when_it_is_the_primary_destination
  test_installs_one_selected_skill
  test_installs_multiple_selected_skills
  test_rejects_unknown_skill_before_copying
  test_duplicate_selection_is_installed_once
  test_cwd_skills_installs_in_place
  test_fresh_removes_existing_skills_and_preserves_non_skill_files
  test_fresh_with_selection_preserves_other_skills
  test_fresh_rejects_init
  test_selection_rejects_init
  test_non_skills_directory_defaults_to_global_target
  test_non_skills_directory_decline_does_not_install
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
