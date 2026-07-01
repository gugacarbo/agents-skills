#!/usr/bin/env bash
set -euo pipefail

# Append-only task progress logger with file locking.
# Usage:
#   log-task.sh \
#     --plan 0003-auth-middleware \
#     --task Task-A-0001 \
#     --event started|completed|failed|blocked \
#     [--try 1] \
#     [--max-tries 3] \
#     [--message "optional message"]
#
# The log file is docs/tasks/<plan>/progress.log

PLAN=""
TASK=""
EVENT=""
TRY=""
MAX_TRIES=""
MESSAGE=""

usage() {
  echo "Usage: log-task.sh --plan <plan-ref> --task <task-id> --event <started|completed|failed|blocked> [--try N] [--max-tries N] [--message \"text\"]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      PLAN="$2"
      shift 2
      ;;
    --task)
      TASK="$2"
      shift 2
      ;;
    --event)
      EVENT="$2"
      shift 2
      ;;
    --try)
      TRY="$2"
      shift 2
      ;;
    --max-tries)
      MAX_TRIES="$2"
      shift 2
      ;;
    --message)
      MESSAGE="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$PLAN" || -z "$TASK" || -z "$EVENT" ]]; then
  usage
fi

case "$EVENT" in
  started|completed|failed|blocked)
    ;;
  *)
    echo "Invalid event: $EVENT"
    usage
    ;;
esac

TASKS_DIR="${AGENTS_SKILLS_TASKS_DIR:-docs/tasks}"
LOG_DIR="$TASKS_DIR/$PLAN"
LOG_FILE="$LOG_DIR/progress.log"

mkdir -p "$LOG_DIR"

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

try_count() {
  if [[ -n "$TRY" ]]; then
    printf '%s' "$TRY"
  else
    printf 'null'
  fi
}

max_tries() {
  if [[ -n "$MAX_TRIES" ]]; then
    printf '%s' "$MAX_TRIES"
  else
    printf 'null'
  fi
}

message_json() {
  if [[ -n "$MESSAGE" ]]; then
    printf '%s' "$(jq -R -s . <<< "$MESSAGE" || printf '"%s"' "$MESSAGE")"
  else
    printf 'null'
  fi
}

LOCK_FILE="$LOG_FILE.lock"

# Acquire exclusive lock; wait up to 10 seconds
exec 200>"$LOCK_FILE"
flock -x -w 10 200 || { echo "Could not acquire lock for $LOG_FILE" >&2; exit 1; }

printf '{"timestamp":"%s","task":"%s","event":"%s","try":%s,"maxTries":%s,"message":%s}\n' \
  "$TIMESTAMP" "$TASK" "$EVENT" "$(try_count)" "$(max_tries)" "$(message_json)" >> "$LOG_FILE"

# Release lock by closing descriptor
exec 200>&-
