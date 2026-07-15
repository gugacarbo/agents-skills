#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_SCRIPT="$(cd "$SCRIPT_DIR" && cd "../../../../skills/super-planning/scripts" && pwd)/log-task.sh"

exec bash "$ROOT_SCRIPT" \
  --plan "docs/jobs/0002-codex-continuation-watchdog/super-plan.json" \
  --task "Task-A-1" \
  --log-dir "$SCRIPT_DIR" \
  "$@"
