#!/usr/bin/env sh
set -eu

# Validate code-flow evidence against the current issue state.
# Checks: activity-start comment exists when stage:in-progress is present;
# run_id/agent/state_before in the comment match the current labels; and a
# code-reviewer run ID does not collide with producer runs.

USAGE='Usage: validate-evidence.sh <N|URL> [--json]'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
STATES_FILE="$SCRIPT_DIR/../workflow-states.json"

ISSUE=""
JSON_OUT=0

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json)
      JSON_OUT=1
      shift
      ;;
    --help | -h)
      printf '%s\n' "$USAGE"
      exit 0
      ;;
    -*) die "Unknown flag: $1\n$USAGE" ;;
    *)
      [ -z "$ISSUE" ] || die "$USAGE"
      ISSUE="$1"
      shift
      ;;
  esac
done

[ -n "$ISSUE" ] || die "$USAGE"

command -v gh > /dev/null 2>&1 || die 'Error: gh is required'
command -v jq > /dev/null 2>&1 || die 'Error: jq is required'
[ -f "$STATES_FILE" ] || die "Error: missing workflow registry: $STATES_FILE"

ACTIVATION=$(jq -r '.activation_label' "$STATES_FILE")
ACTIVITY=$(jq -r '.activity_label' "$STATES_FILE")

ISSUE_JSON=$(gh issue view "$ISSUE" --json number,url,labels,comments)
ISSUE_NUMBER=$(printf '%s' "$ISSUE_JSON" | jq -r '.number')
ISSUE_REPO=$(printf '%s' "$ISSUE_JSON" | jq -r '.url | capture("^https?://(?<host>[^/]+)/(?<path>[^/]+/[^/]+)/issues/[0-9]+$") | "\(.host)/\(.path)"')
[ -n "$ISSUE_NUMBER" ] && [ "$ISSUE_NUMBER" != null ] || die "Error: could not resolve issue: $ISSUE"

HAS_ACTIVE=$(printf '%s' "$ISSUE_JSON" | jq --arg n "$ACTIVATION" '[.labels[].name] | index($n) != null')
HAS_ACTIVITY=$(printf '%s' "$ISSUE_JSON" | jq --arg n "$ACTIVITY" '[.labels[].name] | index($n) != null')
HAS_HUMAN=$(printf '%s' "$ISSUE_JSON" | jq '[.labels[].name] | index("needs-human") != null')
PRIMARY=$(printf '%s' "$ISSUE_JSON" | jq -r --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $n | ($cfg[0].states | map(.label) | index($n)) != null)] | .[0] // empty')
PRIMARY_ACTOR=$(jq -r --arg label "$PRIMARY" '.states[] | select(.label == $label) | .actor' "$STATES_FILE" 2> /dev/null || printf '')

WARNINGS=''
ERRORS=''
START_RUN_ID=''
START_AGENT=''
START_STATE=''

# Extract the latest activity-start comment (event: activity-start).
# Comments are returned oldest-first; pick the last one matching.
LAST_START_JSON=$(printf '%s' "$ISSUE_JSON" | jq -c --arg activity "$ACTIVITY" '
  [.comments[] | select(.body | test("event:\\s*activity-start"))] | last // empty
')

if [ "$HAS_ACTIVITY" = true ]; then
  if [ -z "$LAST_START_JSON" ] || [ "$LAST_START_JSON" = "null" ]; then
    ERRORS="$ERRORS\noverlay stage:in-progress present but no activity-start comment found"
  else
    START_RUN_ID=$(printf '%s' "$LAST_START_JSON" | jq -r '.body | try capture("run_id:\\s*(?<value>\\S+)").value catch empty' 2> /dev/null || printf '')
    START_AGENT=$(printf '%s' "$LAST_START_JSON" | jq -r '.body | try capture("agent:\\s*(?<value>\\S+)").value catch empty' 2> /dev/null || printf '')
    START_STATE=$(printf '%s' "$LAST_START_JSON" | jq -r '.body | try capture("state_before:\\s*(?<value>\\S+)").value catch empty' 2> /dev/null || printf '')

    [ -n "$START_RUN_ID" ] || ERRORS="$ERRORS\nactivity-start missing run_id"
    [ -n "$START_AGENT" ] || ERRORS="$ERRORS\nactivity-start missing agent"
    [ -n "$START_STATE" ] || ERRORS="$ERRORS\nactivity-start missing state_before"

    # Validate agent matches the actor of the current primary state.
    if [ -n "$PRIMARY_ACTOR" ] && [ -n "$START_AGENT" ] && [ "$START_AGENT" != "$PRIMARY_ACTOR" ]; then
      ERRORS="$ERRORS\nactivity-start agent '$START_AGENT' does not match primary state actor '$PRIMARY_ACTOR'"
    fi

    # Validate state_before matches current primary (overlay preserves primary).
    if [ -n "$PRIMARY" ] && [ -n "$START_STATE" ] && [ "$START_STATE" != "$PRIMARY" ]; then
      ERRORS="$ERRORS\nactivity-start state_before '$START_STATE' does not match current primary '$PRIMARY'"
    fi

  fi
else
  if [ -n "$LAST_START_JSON" ] && [ "$LAST_START_JSON" != "null" ]; then
    WARNINGS="$WARNINGS\nactivity-start comment exists but stage:in-progress is absent (stale evidence)"
  fi
fi

# Same GitHub author is allowed; a code-reviewer run ID must be fresh.
if [ "$HAS_ACTIVITY" = true ] && [ "$PRIMARY_ACTOR" = code-reviewer ] && [ -n "$START_RUN_ID" ]; then
  PRODUCER_COLLISION=$(printf '%s' "$ISSUE_JSON" | jq -r --arg run "$START_RUN_ID" '
    [.comments[]
     | select(.body | test("agent:\\s*(dispatcher|architect|executor)"))
     | select(.body | test("run_id:\\s*" + $run + "([[:space:]]|$)"))]
     | length
  ' 2> /dev/null || printf '0')
  [ "$PRODUCER_COLLISION" -eq 0 ] || ERRORS="$ERRORS\ncode-reviewer run_id '$START_RUN_ID' collides with a producer run"
fi

# Build result.
if [ "$JSON_OUT" -eq 1 ]; then
  printf '{"issue":%s,"primary":%s,"has_activity":%s,"errors":%s,"warnings":%s}\n' \
    "$ISSUE_NUMBER" \
    "$(printf '%s' "${PRIMARY:-null}" | jq -R 'if . == "null" then null else . end')" \
    "$HAS_ACTIVITY" \
    "$(printf '%s' "${ERRORS:-}" | jq -R -s 'rtrimstr("\n") | split("\n") | map(select(length > 0))')" \
    "$(printf '%s' "${WARNINGS:-}" | jq -R -s 'rtrimstr("\n") | split("\n") | map(select(length > 0))')"
  [ -z "$ERRORS" ] || exit 1
else
  printf 'issue: %s\n' "$ISSUE_NUMBER"
  printf 'primary: %s\n' "${PRIMARY:-none}"
  printf 'has_activity: %s\n' "$HAS_ACTIVITY"
  if [ -n "$WARNINGS" ]; then
    printf 'warnings:\n'
    printf '%b\n' "$WARNINGS" | sed '/^$/d' | sed 's/^/  - /'
  fi
  if [ -n "$ERRORS" ]; then
    printf 'errors:\n'
    printf '%b\n' "$ERRORS" | sed '/^$/d' | sed 's/^/  - /'
    exit 1
  fi
  printf 'PASS: evidence valid\n'
fi
