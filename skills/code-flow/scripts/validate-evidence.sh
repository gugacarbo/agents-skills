#!/usr/bin/env sh
set -eu

# Validate code-flow evidence against the current issue state.
# Checks: activity-start comment exists when stage:in-progress is present;
# run_id/agent/state_before in the comment match the current labels; reviewer
# independence (reviewer did not produce issue/architect/code/evidence earlier);
# protocol_version compatibility; lease TTL expiry.

USAGE='Usage: validate-evidence.sh <N|URL> [--json]'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
STATES_FILE="$SCRIPT_DIR/../references/workflow-states.json"

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
SCHEMA_VERSION=$(jq -r '.schema_version' "$STATES_FILE")

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
START_PROTO=''
START_LEASE=''
START_TS=''
START_AUTHOR=''

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
    START_PROTO=$(printf '%s' "$LAST_START_JSON" | jq -r '.body | try capture("protocol_version:\\s*(?<value>\\S+)").value catch empty' 2> /dev/null || printf '')
    START_LEASE=$(printf '%s' "$LAST_START_JSON" | jq -r '.body | try capture("lease_ttl:\\s*(?<value>\\S+)").value catch empty' 2> /dev/null || printf '')
    START_TS=$(printf '%s' "$LAST_START_JSON" | jq -r '.createdAt // empty')
    START_AUTHOR=$(printf '%s' "$LAST_START_JSON" | jq -r '.author.login // empty')

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

    # Validate protocol_version compatibility.
    if [ -n "$START_PROTO" ] && [ "$START_PROTO" != "$SCHEMA_VERSION" ]; then
      ERRORS="$ERRORS\nactivity-start protocol_version '$START_PROTO' differs from registry '$SCHEMA_VERSION'"
    fi

    # Check lease TTL expiry.
    if [ -n "$START_LEASE" ]; then
      case "$START_LEASE" in
        *[!0-9]* | '') ERRORS="$ERRORS\nactivity-start lease_ttl must be a non-negative integer" ;;
        *)
          if [ -n "$START_TS" ]; then
            NOW_EPOCH=$(date +%s)
            START_EPOCH=$(date -d "$START_TS" +%s 2> /dev/null || printf '')
            if [ -z "$START_EPOCH" ]; then
              ERRORS="$ERRORS\nactivity-start has an invalid createdAt timestamp"
            else
              EXPIRY=$((START_EPOCH + START_LEASE))
              if [ "$NOW_EPOCH" -gt "$EXPIRY" ]; then
                WARNINGS="$WARNINGS\nlease expired (started $START_TS, TTL ${START_LEASE}s); use 'activity reset' to recover"
              fi
            fi
          fi
          ;;
      esac
    fi
  fi
else
  if [ -n "$LAST_START_JSON" ] && [ "$LAST_START_JSON" != "null" ]; then
    WARNINGS="$WARNINGS\nactivity-start comment exists but stage:in-progress is absent (stale evidence)"
  fi
fi

# Reviewer independence is demonstrable only from GitHub comment authorship.
# A reviewer without a distinct author must stop for an external human review.
if [ "$HAS_ACTIVITY" = true ] && [ "$PRIMARY_ACTOR" = reviewer ]; then
  [ -n "$START_AUTHOR" ] || ERRORS="$ERRORS\nreviewer activity-start has no GitHub author; request external human review"
  if [ -n "$START_AUTHOR" ]; then
    PRIOR_SAME_AUTHOR=$(printf '%s' "$ISSUE_JSON" | jq -r --arg author "$START_AUTHOR" '
      [.comments[]
       | select(.author.login? == $author)
       | select(.body | test("agent:\\s*(issue-writer|architect|executor)"))]
       | length
    ' 2> /dev/null || printf '0')
    if [ "$PRIOR_SAME_AUTHOR" -gt 0 ]; then
      ERRORS="$ERRORS\nreviewer GitHub author '$START_AUTHOR' also produced issue/architect/executor artifacts; request external human review"
    fi
  fi
fi

# Build result.
if [ "$JSON_OUT" -eq 1 ]; then
  printf '{"issue":%s,"schema_version":%s,"primary":%s,"has_activity":%s,"errors":%s,"warnings":%s}\n' \
    "$ISSUE_NUMBER" "$SCHEMA_VERSION" \
    "$(printf '%s' "${PRIMARY:-null}" | jq -R 'if . == "null" then null else . end')" \
    "$HAS_ACTIVITY" \
    "$(printf '%s' "${ERRORS:-}" | jq -R -s 'rtrimstr("\n") | split("\n") | map(select(length > 0))')" \
    "$(printf '%s' "${WARNINGS:-}" | jq -R -s 'rtrimstr("\n") | split("\n") | map(select(length > 0))')"
else
  printf 'issue: %s\n' "$ISSUE_NUMBER"
  printf 'schema_version: %s\n' "$SCHEMA_VERSION"
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
