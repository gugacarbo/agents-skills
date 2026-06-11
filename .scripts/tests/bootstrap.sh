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
FIXTURE_SKILL="commit-changes"

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

test_bootstrap_uses_archive_and_runs_install() {
  local tmp archive_root archive_path
  tmp=$(mktemp -d)
  archive_root="$tmp/archive-src/agents-skills-main"
  archive_path="$tmp/agents-skills-main.tar.gz"

  mkdir -p "$archive_root"
  cp -R "$REPO_ROOT/.scripts" "$archive_root/.scripts"
  cp "$REPO_ROOT/skills.sh" "$archive_root/skills.sh"
  cp -R "$REPO_ROOT/$FIXTURE_SKILL" "$archive_root/$FIXTURE_SKILL"

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

main() {
  assert_exists "$ORCHESTRATOR"

  test_bootstrap_uses_archive_and_runs_install

  printf 'PASS: bootstrap.sh\n'
}

main "$@"
