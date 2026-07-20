#!/usr/bin/env sh
set -eu

# Read-only preflight. Helpers run from the installed skill; no local helper
# installation directory is supported.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
GITHUB_MODE=0
ISSUE=""

usage() {
  printf '%s\n' 'Usage: doctor.sh [--github] [--issue <N|URL>]'
  exit "${1:-1}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --github) GITHUB_MODE=1; shift ;;
    --issue) [ "$#" -ge 2 ] || usage; ISSUE="$2"; GITHUB_MODE=1; shift 2 ;;
    --help|-h) usage 0 ;;
    *) usage ;;
  esac
done

failed=0
check_command() { command -v "$1" >/dev/null 2>&1 && printf 'PASS %s\n' "$1" || { printf 'FAIL %s is required\n' "$1" >&2; failed=1; }; }
check_file() { [ -f "$SCRIPT_DIR/$1" ] && printf 'PASS %s\n' "$1" || { printf 'FAIL missing %s\n' "$1" >&2; failed=1; }; }

check_command git
check_command sh
check_command bash
for helper in review-package doctor transition-issue; do check_file "$helper.sh"; done
check_file source-set-digest.py
check_command python3

if [ -f "$SCRIPT_DIR/visual-companion/server.cjs" ]; then
  check_command node
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git worktree list >/dev/null 2>&1 && printf 'PASS git-worktree\n' || { printf 'FAIL git-worktree\n' >&2; failed=1; }
else
  printf 'WARN current directory is not a Git worktree\n' >&2
fi

if [ "$GITHUB_MODE" -eq 1 ]; then
  check_command gh
  check_command jq
  if command -v gh >/dev/null 2>&1; then
    gh auth status >/dev/null 2>&1 && printf 'PASS gh-auth\n' || { printf 'FAIL gh authentication\n' >&2; failed=1; }
    gh repo view --json nameWithOwner >/dev/null 2>&1 && printf 'PASS gh-repository\n' || { printf 'FAIL gh repository access\n' >&2; failed=1; }
    gh label list --limit 1 >/dev/null 2>&1 && printf 'PASS gh-labels-read\n' || printf 'WARN cannot list repository labels\n' >&2
    if [ -n "$ISSUE" ]; then
      issue_json=$(gh issue view "$ISSUE" --json number,url,labels) || { printf 'FAIL gh issue access: %s\n' "$ISSUE" >&2; failed=1; continue; }
      printf 'PASS gh-issue %s\n' "$ISSUE"

      stage_count=$(printf '%s' "$issue_json" | jq '[.labels[].name | select(startswith("stage:"))] | length')
      has_blocked=$(printf '%s' "$issue_json" | jq '[.labels[].name | select(. == "stage:blocked")] | length')
      has_human=$(printf '%s' "$issue_json" | jq '[.labels[].name | select(. == "needs-human")] | length')

      if [ "$stage_count" -gt 1 ]; then
        printf 'FAIL drift: multiple stage:* labels on #%s\n' "$ISSUE" >&2
        failed=1
      fi
      if [ "$has_blocked" -gt 0 ] && [ "$has_human" -eq 0 ]; then
        printf 'WARN stage:blocked without needs-human on #%s\n' "$ISSUE" >&2
      fi

      "$SCRIPT_DIR/transition-issue.sh" "$ISSUE" --to stage:needs-plan --allow-repair --dry-run >/dev/null 2>&1 \
        && printf 'PASS transition-issue-dry-run\n' \
        || printf 'WARN transition-issue dry-run failed\n' >&2
    fi
  fi
fi

[ "$failed" -eq 0 ]
