#!/usr/bin/env sh
set -eu

# Read-only preflight for a vendored skill or a flat .super-planning install.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
TARGET_DIR="$SCRIPT_DIR"
VISUAL=false

usage() {
  printf '%s\n' 'Usage: doctor.sh [--target-dir <super-planning|.super-planning>] [--visual]'
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift 2 ;;
    --visual) VISUAL=true; shift ;;
    --help|-h) usage ;;
    *) usage ;;
  esac
done

failed=0
check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'PASS %s\n' "$1"
  else
    printf 'FAIL %s is required\n' "$1" >&2
    failed=1
  fi
}
check_file() {
  if [ -f "$TARGET_DIR/$1" ]; then
    printf 'PASS %s\n' "$1"
  else
    printf 'FAIL missing %s\n' "$1" >&2
    failed=1
  fi
}

check_command git
check_command python3
check_command sh
check_command bash

for file in super-plan.sh super-update.sh render-progress-ledger.sh log-task.sh review-package.sh render-task-md.sh summarize-all-tasks.sh doctor.sh bootstrap.sh super-plan.schema.json; do
  check_file "$file"
done

if [ -f "$TARGET_DIR/super-planning-reference.json" ]; then
  printf 'PASS super-planning-reference.json\n'
else
  printf 'WARN missing super-planning-reference.json; updates require explicit source metadata\n' >&2
fi

if [ "$VISUAL" = true ]; then
  check_command node
  for file in visual-companion/start-server.sh visual-companion/stop-server.sh visual-companion/server.cjs visual-companion/helper.js visual-companion/frame-template.html; do
    check_file "$file"
  done
fi

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git worktree list >/dev/null 2>&1 && printf 'PASS git-worktree\n' || { printf 'FAIL git-worktree\n' >&2; failed=1; }
else
  printf 'WARN current directory is not a Git worktree\n' >&2
fi

[ "$failed" -eq 0 ]
