#!/usr/bin/env sh

# Write commits, stat, and a contextual diff for an ephemeral code review.
#
# Usage:
#   review-package.sh BASE HEAD [OUTFILE]
#   review-package.sh --pr <N|URL> [OUTFILE]
set -eu

usage() {
  printf '%s\n' 'usage: review-package.sh BASE HEAD [OUTFILE] | review-package.sh --pr <N|URL> [OUTFILE]' >&2
  exit 2
}

pr_url=""
if [ "$#" -ge 2 ] && [ "$1" = "--pr" ]; then
  [ "$#" -le 3 ] || usage
  command -v gh >/dev/null 2>&1 || { printf '%s\n' 'gh is required for --pr' >&2; exit 2; }
  command -v jq >/dev/null 2>&1 || { printf '%s\n' 'jq is required for --pr' >&2; exit 2; }
  pr_url=$2
  pr_json=$(gh pr view "$pr_url" --json baseRefOid,headRefOid,url)
  base=$(printf '%s' "$pr_json" | jq -r '.baseRefOid')
  head=$(printf '%s' "$pr_json" | jq -r '.headRefOid')
  resolved_pr_url=$(printf '%s' "$pr_json" | jq -r '.url')
  [ -n "$base" ] && [ "$base" != "null" ] || { printf '%s\n' 'unable to resolve PR base commit' >&2; exit 2; }
  [ -n "$head" ] && [ "$head" != "null" ] || { printf '%s\n' 'unable to resolve PR head commit' >&2; exit 2; }
  [ -z "$resolved_pr_url" ] || [ "$resolved_pr_url" = "null" ] || pr_url=$resolved_pr_url
  out=${3:-}
elif [ "$#" -ge 2 ] && [ "$#" -le 3 ]; then
  base=$1
  head=$2
  out=${3:-}
else
  usage
fi

if ! base_commit=$(git rev-parse --verify --quiet "${base}^{commit}"); then
  printf 'bad BASE (fetch or check out the PR base first): %s\n' "$base" >&2
  exit 2
fi

if ! head_commit=$(git rev-parse --verify --quiet "${head}^{commit}"); then
  printf 'bad HEAD (fetch or check out the PR head first): %s\n' "$head" >&2
  exit 2
fi

if ! merge_base=$(git merge-base "$base_commit" "$head_commit"); then
  printf 'BASE and HEAD do not have a merge base: %s %s\n' "$base" "$head" >&2
  exit 2
fi

if [ -z "$out" ]; then
  out=$(mktemp "${TMPDIR:-/tmp}/code-flow-review.XXXXXX.md")
else
  mkdir -p "$(dirname "$out")"
fi

{
  printf '> **Process:** `code-flow` — ephemeral review package.\n\n'
  printf '# Review package: %s..%s\n\n' "$merge_base" "$head_commit"
  [ -z "$pr_url" ] || printf 'PR: %s\n\n' "$pr_url"
  printf 'Requested base: %s\n\n' "$base_commit"
  printf '## Commits\n'
  git log --oneline --decorate "${merge_base}..${head_commit}"
  printf '\n## Files changed\n'
  git diff --stat "${merge_base}..${head_commit}"
  printf '\n## Diff\n'
  git diff --find-renames --find-copies --function-context "${merge_base}..${head_commit}"
} > "$out"

commits=$(git rev-list --count "${merge_base}..${head_commit}")
bytes=$(wc -c < "$out" | tr -d '[:space:]')
printf 'wrote %s: %s commit(s), %s bytes\n' "$out" "$commits" "$bytes"
