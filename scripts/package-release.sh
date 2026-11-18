#!/usr/bin/env sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
output=${1:-$REPO_ROOT/dist/agents-skills.tar.gz}
[ -d "$REPO_ROOT/dist/skills" ] || {
  printf '%s\n' 'Run bun run build before packaging a release.' >&2
  exit 1
}
mkdir -p "$(dirname -- "$output")"
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT INT TERM
package=$staging/agents-skills
mkdir -p "$package/src" "$package/dist"
cp "$REPO_ROOT/skills.sh" "$REPO_ROOT/README.md" "$package/"
cp "$REPO_ROOT/src/install.sh" "$REPO_ROOT/src/update.sh" "$package/src/"
cp -R "$REPO_ROOT/dist/skills" "$package/dist/skills"
tar -czf "$output" -C "$staging" agents-skills
printf '[OK] Release package: %s\n' "$output"
