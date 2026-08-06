#!/usr/bin/env sh
set -eu

USAGE='Usage: apply-event.sh <N|URL> <start|finish|gate|complete> --event FILE [--provision-labels]'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
STATES_FILE="$SCRIPT_DIR/../workflow-states.json"
ISSUE=''
OPERATION=''
EVENT_FILE=''
PROVISION=0

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --event)
      [ "$#" -ge 2 ] || die "$USAGE"
      EVENT_FILE="$2"
      shift 2
      ;;
    --provision-labels)
      PROVISION=1
      shift
      ;;
    -h | --help)
      printf '%s\n' "$USAGE"
      exit 0
      ;;
    -*) die "Unknown option: $1\n$USAGE" ;;
    *)
      if [ -z "$ISSUE" ]; then
        ISSUE="$1"
      elif [ -z "$OPERATION" ]; then
        OPERATION="$1"
      else die "$USAGE"; fi
      shift
      ;;
  esac
done

[ -n "$ISSUE" ] && [ -n "$EVENT_FILE" ] || die "$USAGE"
case "$OPERATION" in start | finish | gate | complete) ;; *) die "$USAGE" ;; esac
[ -f "$EVENT_FILE" ] || die "Error: event file not found: $EVENT_FILE"
command -v gh > /dev/null 2>&1 || die 'Error: gh is required'
command -v jq > /dev/null 2>&1 || die 'Error: jq is required'

EVENT=$(jq -c . "$EVENT_FILE") || die 'Error: event must be valid JSON'
jq -e '
  type == "object" and
  (["event_id","run_id","role","event","state_before","state_after","observed_issue","sources_evidence","project_guidance","base_head","result"] - keys | length == 0) and
  (.event_id|type == "string" and length > 0) and (.run_id|type == "string" and length > 0) and
  (.role|IN("dispatcher","architect","executor","code-reviewer","integrator","gate")) and
  (.state_before|type == "string") and (.state_after|type == "string") and
  (.observed_issue.number|type == "number") and (.observed_issue.url|type == "string") and
  (.sources_evidence|type == "array") and (.project_guidance|type == "array") and
  (.base_head.base|type == "string") and (.base_head.head|type == "string") and
  (.result.status|IN("completed","waiting_human","blocked","retryable_failure","invalid_state"))
' "$EVENT_FILE" > /dev/null || die 'Error: invalid protocol event v1'

ISSUE_JSON=$(gh issue view "$ISSUE" --json number,url,labels,state,updatedAt)
ISSUE_NUMBER=$(printf '%s' "$ISSUE_JSON" | jq -r '.number')
ISSUE_URL=$(printf '%s' "$ISSUE_JSON" | jq -r '.url')
ISSUE_REPO=$(printf '%s' "$ISSUE_URL" | sed -n 's#https\?://[^/]*/\([^/]*/[^/]*/\)issues/[0-9][0-9]*#\1#p' | sed 's#/$##')
[ -n "$ISSUE_REPO" ] || die 'Error: could not resolve issue repository'
EVENT_NUMBER=$(printf '%s' "$EVENT" | jq -r '.observed_issue.number')
[ "$EVENT_NUMBER" = "$ISSUE_NUMBER" ] || die 'Error: event issue number does not match remote issue'

CURRENT=$(printf '%s' "$ISSUE_JSON" | jq -r --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $name | ($cfg[0].states | map(.label) | index($name)) != null)] | if length == 1 then .[0] else empty end')
[ -n "$CURRENT" ] || die 'Error: remote issue has no unique primary state'
BEFORE=$(printf '%s' "$EVENT" | jq -r '.state_before')
[ "$CURRENT" = "$BEFORE" ] || die "Error: remote state '$CURRENT' does not match event state_before '$BEFORE'"

if [ "$OPERATION" = gate ]; then
  DECISION=$(printf '%s' "$EVENT" | jq -r '.gate.decision // empty')
  AUTHOR=$(printf '%s' "$EVENT" | jq -r '.gate.author // empty')
  [ -n "$DECISION" ] && [ -n "$AUTHOR" ] || die 'Error: gate event requires decision and author'
  if [ "$DECISION" = reset ]; then
    HAS_ACTIVITY=$(printf '%s' "$ISSUE_JSON" | jq '[.labels[].name] | index("stage:in-progress") != null')
    [ "$HAS_ACTIVITY" = true ] || die 'Error: reset gate requires stage:in-progress'
    TARGET="$CURRENT"
  else
    TARGET=$(jq -r --arg state "$CURRENT" --arg decision "$DECISION" '.states[] | select(.label == $state) | .outcomes[$decision] // empty' "$STATES_FILE")
    if [ "$TARGET" = recorded ]; then
      TARGET=$(printf '%s' "$EVENT" | jq -r '.state_after')
      jq -e --arg from "$CURRENT" --arg to "$TARGET" '.states[] | select(.label == $from) | .next | index($to) != null' "$STATES_FILE" > /dev/null \
        || die "Error: recorded gate target '$TARGET' is not a valid resume state"
    fi
    [ -n "$TARGET" ] || die "Error: gate decision '$DECISION' is not applicable to '$CURRENT'"
  fi
  PERMISSION=$(gh api "repos/$ISSUE_REPO/collaborators/$AUTHOR/permission" --jq .permission 2> /dev/null || true)
  case "$PERMISSION" in write | maintain | admin) ;; *) die "Error: gate author '$AUTHOR' lacks write permission" ;; esac
fi

# Starting work only acquires the activity overlay. Results, gates, and
# completion remain public protocol events; starts intentionally stay silent.
if [ "$OPERATION" != start ]; then
  SUMMARY=$(printf '%s' "$EVENT" | jq -r '.result.summary')
  BODY=$(printf '### code-flow %s\n\n%s\n\n<!-- code-flow:event:v1 %s -->' "$OPERATION" "$SUMMARY" "$EVENT")
  gh issue comment "$ISSUE_NUMBER" --repo "$ISSUE_REPO" --body "$BODY" > /dev/null
fi

case "$OPERATION" in
  start)
    ROLE=$(printf '%s' "$EVENT" | jq -r '.role')
    ARGS="--start-work --role $ROLE --require-from $CURRENT"
    ;;
  finish)
    TARGET=$(printf '%s' "$EVENT" | jq -r '.state_after')
    ARGS="--finish-to $TARGET --require-from $CURRENT"
    ;;
  gate)
    if [ "$DECISION" = reset ]; then
      ARGS="--reset-activity --require-from $CURRENT"
    else ARGS="--gate-to $TARGET --require-from $CURRENT"; fi
    ;;
  complete)
    ARGS='--complete'
    ;;
esac

if [ "$PROVISION" -eq 1 ]; then ARGS="$ARGS --provision-labels"; fi
# shellcheck disable=SC2086 -- arguments are generated only from validated registry/event values.
TRANSITION=$($SCRIPT_DIR/transition-issue.sh "$ISSUE" $ARGS)
CONFIRMED=$(printf '%s' "$TRANSITION" | jq -r '.primary_state // .to // empty')
[ -n "$CONFIRMED" ] || CONFIRMED="$CURRENT"
printf '{"event_id":%s,"operation":%s,"confirmed_state":%s,"transition":%s}\n' \
  "$(printf '%s' "$EVENT" | jq -r '.event_id' | jq -R .)" "$(printf '%s' "$OPERATION" | jq -R .)" \
  "$(printf '%s' "$CONFIRMED" | jq -R .)" "$TRANSITION"
