#!/usr/bin/env sh
set -eu

# Validate code-flow evidence against the current issue state.
# Checks protocol history and, when supplied, ensures a code-reviewer run ID
# does not collide with producer runs. Activity starts are intentionally silent.

USAGE='Usage: validate-evidence.sh <N|URL> [--run-id RUN_ID] [--json]'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
STATES_FILE="$SCRIPT_DIR/../workflow-states.json"

ISSUE=""
JSON_OUT=0
RUN_ID=''

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
    --run-id)
      [ "$#" -ge 2 ] || die "$USAGE"
      RUN_ID="$2"
      shift 2
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
# Worker comments carry a one-line, hidden protocol event. Keep parsing the
# legacy Markdown fields below so interactive runs remain compatible, but make
# an active issue without a v1 event explicitly migratable rather than silently
# treating it as a trustworthy worker history.
EVENTS=$(printf '%s' "$ISSUE_JSON" | jq -c '
  [.comments[] | .body as $body |
   try ($body | capture("<!-- code-flow:event:v1 (?<event>\\{.*\\}) -->").event | fromjson) catch empty]
')
EVENT_COUNT=$(printf '%s' "$EVENTS" | jq 'length')
if [ "$HAS_ACTIVE" = true ] && [ "$HAS_ACTIVITY" = false ] && [ "$EVENT_COUNT" -eq 0 ]; then
  ERRORS="$ERRORS\nmigration_required: active issue has no code-flow:event:v1 history"
fi

# Same GitHub author is allowed; a code-reviewer run ID must be fresh.
if [ "$PRIMARY_ACTOR" = code-reviewer ] && [ -n "$RUN_ID" ]; then
  PRODUCER_COLLISION=$(printf '%s' "$ISSUE_JSON" | jq -r --arg run "$RUN_ID" '
    [.comments[]
     | select(.body | test("agent:\\s*(dispatcher|architect|executor)"))
     | select(.body | test("run_id:\\s*" + $run + "([[:space:]]|$)"))]
     | length
  ' 2> /dev/null || printf '0')
  [ "$PRODUCER_COLLISION" -eq 0 ] || ERRORS="$ERRORS\ncode-reviewer run_id '$RUN_ID' collides with a producer run"
fi

if [ "$PRIMARY_ACTOR" = code-reviewer ] && [ -n "$RUN_ID" ] && [ "$EVENT_COUNT" -gt 0 ]; then
  PRODUCER_COLLISION=$(printf '%s' "$EVENTS" | jq --arg run "$RUN_ID" '[.[] | select(.role | IN("dispatcher", "architect", "executor")) | select(.run_id == $run)] | length')
  [ "$PRODUCER_COLLISION" -eq 0 ] || ERRORS="$ERRORS\ncode-reviewer run_id '$RUN_ID' collides with a producer event"
fi

# Build result.
if [ "$JSON_OUT" -eq 1 ]; then
  printf '{"issue":%s,"primary":%s,"has_activity":%s,"event_count":%s,"errors":%s,"warnings":%s}\n' \
    "$ISSUE_NUMBER" \
    "$(printf '%s' "${PRIMARY:-null}" | jq -R 'if . == "null" then null else . end')" \
    "$HAS_ACTIVITY" \
    "$EVENT_COUNT" \
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
