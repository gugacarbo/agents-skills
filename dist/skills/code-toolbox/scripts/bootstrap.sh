#!/usr/bin/env sh
set -eu

# Vendor the portable execution helpers from a known code-toolbox skill.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR=""

usage() {
  printf '%s\n' 'Usage: bootstrap.sh --target-dir <project/.code-toolbox> [--source-dir <code-toolbox-dir>]'
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift 2 ;;
    --source-dir) SOURCE_DIR="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) usage ;;
  esac
done

[ -n "$TARGET_DIR" ] || usage
[ -f "$SOURCE_DIR/scripts/review-package.sh" ] || { printf '%s\n' "Error: source is not a code-toolbox skill" >&2; exit 1; }

mkdir -p "$TARGET_DIR"
for file in review-package.sh doctor.sh bootstrap.sh; do
  cp "$SOURCE_DIR/scripts/$file" "$TARGET_DIR/$file"
done
chmod +x "$TARGET_DIR"/*.sh
printf '%s\n' "$TARGET_DIR"
