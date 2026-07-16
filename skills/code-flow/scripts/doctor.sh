#!/usr/bin/env sh
set -eu

# Read-only preflight for a vendored skill or flat .code-flow install.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
TARGET_DIR="$SCRIPT_DIR"
GITHUB_MODE=0
ISSUE=""

usage() {
  printf '%s\n' 'Usage: doctor.sh [--target-dir <code-flow|.code-flow>] [--github] [--issue <N|URL>]'
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift 2 ;;
    --github) GITHUB_MODE=1; shift ;;
    --issue) ISSUE="$2"; GITHUB_MODE=1; shift 2 ;;
    --help|-h) usage ;;
    *) usage ;;
  esac
done

failed=0
check_command() { command -v "$1" >/dev/null 2>&1 && printf 'PASS %s\n' "$1" || { printf 'FAIL %s is required\n' "$1" >&2; failed=1; }; }
check_file() { [ -f "$TARGET_DIR/$1" ] && printf 'PASS %s\n' "$1" || { printf 'FAIL missing %s\n' "$1" >&2; failed=1; }; }

check_command git
check_command sh
check_command bash
for file in review-package.sh doctor.sh bootstrap.sh; do check_file "$file"; done

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git worktree list >/dev/null 2>&1 && printf 'PASS git-worktree\n' || { printf 'FAIL git-worktree\n' >&2; failed=1; }
else
  printf 'WARN current directory is not a Git worktree\n' >&2
fi

if [ "$GITHUB_MODE" -eq 1 ]; then
  check_command gh
  if command -v gh >/dev/null 2>&1; then
    gh auth status >/dev/null 2>&1 && printf 'PASS gh-auth\n' || { printf 'FAIL gh authentication\n' >&2; failed=1; }
    gh repo view --json nameWithOwner >/dev/null 2>&1 && printf 'PASS gh-repository\n' || { printf 'FAIL gh repository access\n' >&2; failed=1; }
    if [ -n "$ISSUE" ]; then
      gh issue view "$ISSUE" --json number,url >/dev/null 2>&1 && printf 'PASS gh-issue %s\n' "$ISSUE" || { printf 'FAIL gh issue access: %s\n' "$ISSUE" >&2; failed=1; }
    fi
  fi
fi

[ "$failed" -eq 0 ]
