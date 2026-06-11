#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
UPDATER="$REPO_ROOT/.scripts/update.sh"
FIXTURE_SKILL="update-test-fixture-skill"

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

create_archive() {
  local tmp="$1"
  local version="$2"
  local archive_root archive_path

  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"

  mkdir -p "$archive_root/$FIXTURE_SKILL" "$archive_root/.scripts"
  printf '%s\n' '---' "name: $FIXTURE_SKILL" "---" "version: $version" >"$archive_root/$FIXTURE_SKILL/SKILL.md"
  printf '%s\n' "#!/usr/bin/env sh" "printf '%s\n' remote-$version" >"$archive_root/skills.sh"
  printf '%s\n' "remote readme $version" >"$archive_root/README.md"
  printf '%s\n' "#!/usr/bin/env sh" "printf '%s\n' install-$version" >"$archive_root/.scripts/install.sh"

  tar -czf "$archive_path" -C "$tmp/archive-src" agents-skills-main
  printf '%s\n' "$archive_path"
}

seed_target_from_archive() {
  local archive_path="$1"
  local target="$2"
  local tmp

  tmp=$(mktemp -d)
  mkdir -p "$target"
  tar -xzf "$archive_path" -C "$tmp"
  cp -R "$tmp/agents-skills-main/." "$target/"
}

test_update_reports_already_current_when_files_match() {
  local tmp archive_path target
  tmp=$(mktemp -d)
  target="$tmp/skills"
  archive_path=$(create_archive "$tmp" "remote")
  seed_target_from_archive "$archive_path" "$target"

  run_capture "$tmp/output.log" env AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" "$UPDATER" --path "$target"

  assert_contains "ja esta atualizada"
}

test_update_prompts_before_overwriting_changed_files() {
  local tmp archive_path target
  tmp=$(mktemp -d)
  target="$tmp/skills"
  archive_path=$(create_archive "$tmp" "remote")
  mkdir -p "$target/$FIXTURE_SKILL"
  printf '%s\n' 'local version' >"$target/$FIXTURE_SKILL/SKILL.md"
  printf 'y\n' >"$tmp/tty-input"

  run_capture "$tmp/output.log" env AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" \
    AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" \
    "$UPDATER" --path "$target" < /dev/null

  LAST_OUTPUT=$(cat "$tmp/output.log")
  grep -q 'version: remote' "$target/$FIXTURE_SKILL/SKILL.md"
  assert_contains "Atualizacao concluida"
}

test_update_cancels_without_confirmation() {
  local tmp archive_path target
  tmp=$(mktemp -d)
  target="$tmp/skills"
  archive_path=$(create_archive "$tmp" "remote")
  mkdir -p "$target/$FIXTURE_SKILL"
  printf '%s\n' 'local version' >"$target/$FIXTURE_SKILL/SKILL.md"
  printf 'n\n' >"$tmp/tty-input"

  if run_capture "$tmp/output.log" env AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" \
    AGENTS_SKILLS_PROMPT_INPUT="$tmp/tty-input" \
    "$UPDATER" --path "$target" < /dev/null; then
    fail "expected update without confirmation to fail"
  fi

  LAST_OUTPUT=$(cat "$tmp/output.log")
  grep -qx 'local version' "$target/$FIXTURE_SKILL/SKILL.md"
  assert_contains "Atualizacao cancelada"
}

test_update_yes_overwrites_without_prompt() {
  local tmp archive_path target
  tmp=$(mktemp -d)
  target="$tmp/skills"
  archive_path=$(create_archive "$tmp" "remote")
  mkdir -p "$target/$FIXTURE_SKILL"
  printf '%s\n' 'local version' >"$target/$FIXTURE_SKILL/SKILL.md"

  run_capture "$tmp/output.log" env AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" "$UPDATER" --path "$target" --yes < /dev/null

  grep -q 'version: remote' "$target/$FIXTURE_SKILL/SKILL.md"
}

test_update_fails_when_target_does_not_exist() {
  local tmp archive_path target
  tmp=$(mktemp -d)
  target="$tmp/missing-skills"
  archive_path=$(create_archive "$tmp" "remote")

  if run_capture "$tmp/output.log" env AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" "$UPDATER" --path "$target" --yes; then
    fail "expected missing target update to fail"
  fi

  LAST_OUTPUT=$(cat "$tmp/output.log")
  assert_contains "Destino de update nao existe"
}

main() {
  assert_exists "$UPDATER"

  test_update_reports_already_current_when_files_match
  test_update_prompts_before_overwriting_changed_files
  test_update_cancels_without_confirmation
  test_update_yes_overwrites_without_prompt
  test_update_fails_when_target_does_not_exist

  printf 'PASS: update.sh\n'
}

main "$@"
