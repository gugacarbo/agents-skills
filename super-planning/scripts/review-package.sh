#!/usr/bin/env sh

# Write the commits, stat, and contextual diff for a task review.
#
# Usage: review-package.sh BASE HEAD [OUTFILE]
#
# When OUTFILE is omitted, the package is written to the active repository's
# short-lived .super-planning/sdd-workspace, named for the commit range.
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  printf '%s\n' 'usage: review-package.sh BASE HEAD [OUTFILE]' >&2
  exit 2
fi

base=$1
head=$2

if ! base_commit=$(git rev-parse --verify --quiet "${base}^{commit}"); then
  printf 'bad BASE: %s\n' "$base" >&2
  exit 2
fi

if ! head_commit=$(git rev-parse --verify --quiet "${head}^{commit}"); then
  printf 'bad HEAD: %s\n' "$head" >&2
  exit 2
fi

if [ "$#" -eq 3 ]; then
  out=$3
else
  repo_root=$(git rev-parse --show-toplevel)
  workspace="$repo_root/.super-planning/sdd-workspace"
  out="$workspace/review-$base_commit..$head_commit.diff"
fi

mkdir -p "$(dirname "$out")"

{
  printf '# Review package: %s..%s\n\n' "$base" "$head"
  printf '## Commits\n'
  git log --oneline --decorate "${base}..${head}"
  printf '\n## Files changed\n'
  git diff --stat "${base}..${head}"
  printf '\n## Diff\n'
  git diff --find-renames --find-copies --function-context "${base}..${head}"
} > "$out"

commits=$(git rev-list --count "${base}..${head}")
bytes=$(wc -c < "$out" | tr -d '[:space:]')
printf 'wrote %s: %s commit(s), %s bytes\n' "$out" "$commits" "$bytes"
