#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
BOOTSTRAP="$REPO_ROOT/install.sh"
ORCHESTRATOR="$REPO_ROOT/skills.sh"
FIXTURE_SKILL="sample-skill"

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
  local path="$1"
  local needle="$2"

  if ! grep -q "$needle" "$path"; then
    fail "expected $path to contain: $needle"
  fi
}

test_bootstrap_uses_archive_and_runs_install() {
  local tmp archive_root archive_path
  tmp=$(mktemp -d)
  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"

  mkdir -p "$archive_root"
  cp -R "$REPO_ROOT/.scripts" "$archive_root/.scripts"
  cp "$REPO_ROOT/skills.sh" "$archive_root/skills.sh"
  mkdir -p "$archive_root/$FIXTURE_SKILL"
  printf '%s\n' '---' 'name: sample-skill' '---' >"$archive_root/$FIXTURE_SKILL/SKILL.md"

  tar -czf "$archive_path" -C "$tmp/archive-src" agents-skills-main

  (
    cd "$tmp"
    cat "$ORCHESTRATOR" | \
    AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" \
    AGENTS_SKILLS_ARCHIVE_URL_FORCE=1 \
      sh -s -- install --path "$tmp/custom-skills" >"$tmp/output.log" 2>&1
  )

  assert_exists "$tmp/custom-skills/$FIXTURE_SKILL/SKILL.md"
}

test_bootstrap_uses_archive_and_runs_update() {
  local tmp archive_root archive_path target
  tmp=$(mktemp -d)
  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"
  target="$tmp/custom-skills"

  mkdir -p "$archive_root" "$target/$FIXTURE_SKILL"
  cp -R "$REPO_ROOT/.scripts" "$archive_root/.scripts"
  cp "$REPO_ROOT/skills.sh" "$archive_root/skills.sh"
  mkdir -p "$archive_root/$FIXTURE_SKILL"
  printf '%s\n' '---' 'name: sample-skill' '---' 'version: remote' >"$archive_root/$FIXTURE_SKILL/SKILL.md"
  printf '%s\n' 'version: local' >"$target/$FIXTURE_SKILL/SKILL.md"

  tar -czf "$archive_path" -C "$tmp/archive-src" agents-skills-main

  (
    cd "$tmp"
    cat "$ORCHESTRATOR" | \
    AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" \
    AGENTS_SKILLS_ARCHIVE_URL_FORCE=1 \
      sh -s -- update --path "$target" --yes >"$tmp/output-update.log" 2>&1
  )

  grep -q 'version: remote' "$target/$FIXTURE_SKILL/SKILL.md"
}

test_bootstrap_missing_command_does_not_loop() {
  local tmp archive_root archive_path status download_count
  tmp=$(mktemp -d)
  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"

  mkdir -p "$archive_root"
  cp "$REPO_ROOT/skills.sh" "$archive_root/skills.sh"
  tar -czf "$archive_path" -C "$tmp/archive-src" agents-skills-main

  set +e
  (
    cd "$tmp"
    cat "$ORCHESTRATOR" | \
    AGENTS_SKILLS_ARCHIVE_URL="file://$archive_path" \
    AGENTS_SKILLS_ARCHIVE_URL_FORCE=1 \
      timeout 5 sh -s -- install --path "$tmp/custom-skills" >"$tmp/output-missing.log" 2>&1
  )
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    fail "expected bootstrap with missing install command to fail"
  fi

  download_count=$(grep -c "Baixando pacote de bootstrap" "$tmp/output-missing.log" || true)
  if [ "$download_count" -ne 1 ]; then
    fail "expected one bootstrap download, got $download_count"
  fi

  assert_contains "$tmp/output-missing.log" "Comando install nao encontrado"
}

main() {
  assert_exists "$ORCHESTRATOR"

  test_bootstrap_uses_archive_and_runs_install
  test_bootstrap_uses_archive_and_runs_update
  test_bootstrap_missing_command_does_not_loop

  printf 'PASS: bootstrap.sh\n'
}

main "$@"
