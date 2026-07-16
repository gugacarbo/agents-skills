#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
SKILL_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P)
TARGET_DIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift 2 ;;
    *) echo "usage: materialize-watchdogs.sh --target-dir <repo>" >&2; exit 2 ;;
  esac
done
[ -n "$TARGET_DIR" ] || { echo "--target-dir is required" >&2; exit 2; }

DEST="$TARGET_DIR/.code-toolbox/watchdogs"
mkdir -p "$DEST/prompts"
cp "$SKILL_DIR/platforms/continuation/codex/watchdogs.template.json" "$DEST/codex-watchdogs.json"
cp "$SKILL_DIR/prompts/watchdogs/continue-interrupted-task.md" "$DEST/prompts/continue-interrupted-task.md"
cp "$SKILL_DIR/prompts/watchdogs/report-execution-status.md" "$DEST/prompts/report-execution-status.md"
