#!/usr/bin/env sh
set -eu

# Best-effort label protocol helper. GitHub label edits are not atomic; every
# operation confirms the remote result and reports drift instead of claiming a lock.

USAGE='Usage: transition-issue.sh <N|URL> (--activate | --start-work --role ROLE | --finish-to STAGE | --gate-to STAGE | --reset-activity | --complete | --migrate-to STAGE) [--require-from STAGE] [--dry-run] [--allow-repair] [--provision-labels] [--run-id UUID] [--lease-ttl SECONDS]'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
STATES_FILE="$SCRIPT_DIR/../references/workflow-states.json"

ISSUE=""
OP=""
TARGET=""
ROLE=""
REQUIRE_FROM=""
DRY_RUN=0
ALLOW_REPAIR=0
PROVISION_LABELS=0
RUN_ID=""
LEASE_TTL=""

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

set_op() {
  [ -z "$OP" ] || die "Error: choose exactly one operation\n$USAGE"
  OP="$1"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --activate)
      set_op activate
      shift
      ;;
    --start-work)
      set_op start
      shift
      ;;
    --finish-to)
      [ "$#" -ge 2 ] || die "$USAGE"
      set_op finish
      TARGET="$2"
      shift 2
      ;;
    --gate-to)
      [ "$#" -ge 2 ] || die "$USAGE"
      set_op gate
      TARGET="$2"
      shift 2
      ;;
    --reset-activity)
      set_op reset
      shift
      ;;
    --complete)
      set_op complete
      shift
      ;;
    --migrate-to)
      [ "$#" -ge 2 ] || die "$USAGE"
      set_op migrate
      TARGET="$2"
      shift 2
      ;;
    --role)
      [ "$#" -ge 2 ] || die "$USAGE"
      ROLE="$2"
      shift 2
      ;;
    --require-from)
      [ "$#" -ge 2 ] || die "$USAGE"
      REQUIRE_FROM="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --allow-repair)
      ALLOW_REPAIR=1
      shift
      ;;
    --provision-labels)
      PROVISION_LABELS=1
      shift
      ;;
    --run-id)
      [ "$#" -ge 2 ] || die "$USAGE"
      RUN_ID="$2"
      shift 2
      ;;
    --lease-ttl)
      [ "$#" -ge 2 ] || die "$USAGE"
      LEASE_TTL="$2"
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

[ -n "$ISSUE" ] && [ -n "$OP" ] || die "$USAGE"
[ "$OP" = start ] || [ -z "$ROLE" ] || die 'Error: --role is only valid with --start-work'
[ "$OP" != start ] || [ -n "$ROLE" ] || die 'Error: --start-work requires --role'
[ -z "$LEASE_TTL" ] || [ "$OP" = start ] || die 'Error: --lease-ttl is only valid with --start-work'
[ -z "$LEASE_TTL" ] || [ -n "$RUN_ID" ] || die 'Error: --lease-ttl requires --run-id'
[ -z "$RUN_ID" ] || [ "$OP" = start ] || die 'Error: --run-id is only valid with --start-work'

command -v gh > /dev/null 2>&1 || die 'Error: gh is required'
command -v jq > /dev/null 2>&1 || die 'Error: jq is required'
[ -f "$STATES_FILE" ] || die "Error: missing workflow registry: $STATES_FILE"
jq -e '
  .schema_version == 2 and
  (.activation_label | type == "string") and
  (.activity_label | type == "string") and
  (.states | type == "array" and length > 0) and
  ([.states[].label] | length == (unique | length)) and
  all(.states[]; (.label | test("^stage:[a-z-]+$")) and
    (.actor | type == "string") and (.kind == "agent" or .kind == "human") and
    (.next | type == "array"))
' "$STATES_FILE" > /dev/null || die "Error: invalid workflow registry: $STATES_FILE"

ACTIVATION=$(jq -r '.activation_label' "$STATES_FILE")
ACTIVITY=$(jq -r '.activity_label' "$STATES_FILE")

is_primary() { jq -e --arg label "$1" '.states | map(.label) | index($label) != null' "$STATES_FILE" > /dev/null; }
target_kind() { jq -r --arg label "$1" '.states[] | select(.label == $label) | .kind' "$STATES_FILE"; }
target_actor() { jq -r --arg label "$1" '.states[] | select(.label == $label) | .actor' "$STATES_FILE"; }
transition_allowed() {
  jq -e --arg from "$1" --arg to "$2" '.states[] | select(.label == $from) | .next | index($to) != null' "$STATES_FILE" > /dev/null
}

[ -z "$TARGET" ] || is_primary "$TARGET" || die "Error: invalid target state '$TARGET'"
[ -z "$REQUIRE_FROM" ] || is_primary "$REQUIRE_FROM" || die "Error: invalid --require-from '$REQUIRE_FROM'"

ISSUE_JSON=$(gh issue view "$ISSUE" --json number,labels,url)
ISSUE_NUMBER=$(printf '%s' "$ISSUE_JSON" | jq -r '.number')
ISSUE_REPO=$(printf '%s' "$ISSUE_JSON" | jq -r '.url | capture("^https?://(?<host>[^/]+)/(?<path>[^/]+/[^/]+)/issues/[0-9]+$") | "\(.host)/\(.path)"')
[ -n "$ISSUE_NUMBER" ] && [ "$ISSUE_NUMBER" != null ] || die "Error: could not resolve issue: $ISSUE"
[ -n "$ISSUE_REPO" ] || die "Error: could not resolve repository: $ISSUE"

labels_json() { printf '%s' "$1" | jq -c '[.labels[].name]'; }
ALL_BEFORE=$(labels_json "$ISSUE_JSON")
PRIMARY_LIST=$(printf '%s' "$ISSUE_JSON" | jq -r --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $n | ($cfg[0].states | map(.label) | index($n)) != null)] | join("\n")')
PRIMARY_COUNT=$(printf '%s' "$ISSUE_JSON" | jq --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $n | ($cfg[0].states | map(.label) | index($n)) != null)] | length')
CURRENT=$(printf '%s' "$PRIMARY_LIST" | sed -n '1p')
HAS_ACTIVE=$(printf '%s' "$ISSUE_JSON" | jq --arg n "$ACTIVATION" '[.labels[].name] | index($n) != null')
HAS_ACTIVITY=$(printf '%s' "$ISSUE_JSON" | jq --arg n "$ACTIVITY" '[.labels[].name] | index($n) != null')
HAS_HUMAN=$(printf '%s' "$ISSUE_JSON" | jq '[.labels[].name] | index("needs-human") != null')
UNKNOWN_STAGES=$(printf '%s' "$ISSUE_JSON" | jq -r --slurpfile cfg "$STATES_FILE" --arg activity "$ACTIVITY" '[.labels[].name | select(startswith("stage:")) | select(. != $activity) | select(. as $n | ($cfg[0].states | map(.label) | index($n)) == null)] | join("\n")')
ALL_STATE_LABELS=$(printf '%s' "$ISSUE_JSON" | jq -r --arg activity "$ACTIVITY" '[.labels[].name | select(startswith("stage:")) | select(. != $activity)] | join("\n")')

[ -z "$REQUIRE_FROM" ] || [ "$CURRENT" = "$REQUIRE_FROM" ] || die "Error: expected '$REQUIRE_FROM'; found '${CURRENT:-none}'"

if [ "$HAS_ACTIVE" = true ] && [ -n "$UNKNOWN_STAGES" ] && { [ "$OP" != complete ] || [ "$ALLOW_REPAIR" -eq 0 ]; }; then
  die "Error: active issue has unknown stage labels: $UNKNOWN_STAGES"
fi

case "$OP" in
  activate)
    [ "$HAS_ACTIVE" = false ] || die 'Error: code-flow is already active'
    [ "$PRIMARY_COUNT" -eq 0 ] && [ "$HAS_ACTIVITY" = false ] && [ "$HAS_HUMAN" = false ] && [ -z "$UNKNOWN_STAGES" ] \
      || die 'Error: activation requires no workflow labels; migrate or repair explicitly'
    TARGET='stage:needs-triage'
    ;;
  migrate)
    [ "$HAS_ACTIVE" = false ] || die 'Error: migration requires inactive issue'
    [ -n "$ALL_STATE_LABELS" ] || die 'Error: no legacy stage found'
    [ "$(printf '%s\n' "$ALL_STATE_LABELS" | sed '/^$/d' | wc -l)" -eq 1 ] || die 'Error: migration requires exactly one legacy stage'
    LEGACY=$(printf '%s' "$ALL_STATE_LABELS" | sed -n '1p')
    EXPECTED=$(jq -r --arg legacy "$LEGACY" '.legacy[$legacy] // empty' "$STATES_FILE")
    [ -n "$EXPECTED" ] || die "Error: legacy state '$LEGACY' is ambiguous"
    [ "$TARGET" = "$EXPECTED" ] || die "Error: legacy '$LEGACY' must migrate to '$EXPECTED'"
    ;;
  start)
    [ "$HAS_ACTIVE" = true ] || die 'Error: missing code-flow:active'
    [ "$PRIMARY_COUNT" -eq 1 ] && [ -z "$UNKNOWN_STAGES" ] || die 'Error: expected exactly one canonical primary state'
    [ "$HAS_ACTIVITY" = false ] || die 'Error: activity already in progress; resume the proven activity from the last evidence or use a human reset'
    [ "$HAS_HUMAN" = false ] || die 'Error: cannot start work while needs-human is present'
    [ "$(target_kind "$CURRENT")" = agent ] || die "Error: '$CURRENT' is a human state"
    [ "$(target_actor "$CURRENT")" = "$ROLE" ] || die "Error: state '$CURRENT' belongs to $(target_actor "$CURRENT"), not $ROLE"
    ;;
  finish)
    [ "$HAS_ACTIVE" = true ] && [ "$PRIMARY_COUNT" -eq 1 ] || die 'Error: finish requires one active primary state'
    [ "$HAS_ACTIVITY" = true ] || die 'Error: finish requires stage:in-progress'
    [ "$HAS_HUMAN" = false ] || die 'Error: activity and needs-human cannot coexist'
    transition_allowed "$CURRENT" "$TARGET" || die "Error: transition '$CURRENT' -> '$TARGET' is not allowed"
    ;;
  gate)
    [ "$HAS_ACTIVE" = true ] && [ "$PRIMARY_COUNT" -eq 1 ] || die 'Error: gate requires one active primary state'
    [ "$HAS_ACTIVITY" = false ] || die 'Error: gate cannot run during active work'
    [ "$HAS_HUMAN" = true ] || die 'Error: gate requires needs-human'
    [ "$(target_kind "$CURRENT")" = human ] || die "Error: '$CURRENT' is not a human state"
    transition_allowed "$CURRENT" "$TARGET" || die "Error: gate transition '$CURRENT' -> '$TARGET' is not allowed"
    ;;
  reset)
    [ "$HAS_ACTIVE" = true ] && [ "$PRIMARY_COUNT" -eq 1 ] || die 'Error: reset requires one active primary state'
    [ "$HAS_ACTIVITY" = true ] || die 'Error: no activity to reset'
    [ "$HAS_HUMAN" = false ] || die 'Error: invalid activity + needs-human drift'
    ;;
  complete)
    [ "$HAS_ACTIVE" = true ] || die 'Error: completion requires code-flow:active'
    if [ "$ALLOW_REPAIR" -eq 0 ]; then
      [ "$PRIMARY_COUNT" -eq 1 ] && [ -z "$UNKNOWN_STAGES" ] || die 'Error: completion found workflow drift; use --allow-repair after evidence'
    fi
    ;;
esac

if [ "$DRY_RUN" -eq 1 ]; then
  printf '{"issue":%s,"operation":"%s","from":%s,"to":%s,"labels_before":%s,"dry_run":true}\n' \
    "$ISSUE_NUMBER" "$OP" "$(printf '%s' "${CURRENT:-null}" | jq -R 'if . == "null" then null else . end')" \
    "$(printf '%s' "${TARGET:-null}" | jq -R 'if . == "null" then null else . end')" "$ALL_BEFORE"
  exit 0
fi

label_exists() { gh label view "$1" --repo "$ISSUE_REPO" > /dev/null 2>&1; }
provision_label() {
  name="$1"
  color="$2"
  description="$3"
  label_exists "$name" || gh label create "$name" --repo "$ISSUE_REPO" --color "$color" --description "$description" > /dev/null
}
require_label() {
  name="$1"
  label_exists "$name" || MISSING_LABELS="$MISSING_LABELS $name"
}
add_label() { gh issue edit "$ISSUE_NUMBER" --repo "$ISSUE_REPO" --add-label "$1" > /dev/null; }
remove_label() { gh issue edit "$ISSUE_NUMBER" --repo "$ISSUE_REPO" --remove-label "$1" > /dev/null; }

if [ "$PROVISION_LABELS" -eq 1 ]; then
  provision_label "$ACTIVATION" '5319E7' 'code-flow workflow active'
  provision_label "$ACTIVITY" 'FBCA04' 'code-flow agent activity in progress'
  provision_label 'needs-human' 'D93F0B' 'human decision required'
  [ -z "$TARGET" ] || provision_label "$TARGET" '1D76DB' 'code-flow primary state'
  # Provision all primary states from the registry so subsequent transitions
  # do not need --provision-labels again.
  for state_label in $(jq -r '.states[].label' "$STATES_FILE"); do
    provision_label "$state_label" '1D76DB' 'code-flow primary state'
  done
else
  MISSING_LABELS=''
  require_label "$ACTIVATION"
  require_label "$ACTIVITY"
  require_label 'needs-human'
  [ -z "$TARGET" ] || require_label "$TARGET"
  if [ -n "$MISSING_LABELS" ]; then
    die "Error: required labels missing in $ISSUE_REPO:$MISSING_LABELS\nProvision them first or rerun with --provision-labels."
  fi
fi

case "$OP" in
  activate)
    add_label "$ACTIVATION"
    add_label "$TARGET"
    ;;
  migrate)
    remove_label "$LEGACY"
    add_label "$ACTIVATION"
    add_label "$TARGET"
    if [ "$(target_kind "$TARGET")" = human ]; then
      add_label 'needs-human'
    elif [ "$HAS_HUMAN" = true ]; then
      remove_label 'needs-human'
    fi
    ;;
  start)
    add_label "$ACTIVITY"
    ;;
  finish)
    remove_label "$CURRENT"
    remove_label "$ACTIVITY"
    add_label "$TARGET"
    if [ "$(target_kind "$TARGET")" = human ]; then add_label 'needs-human'; else [ "$HAS_HUMAN" = false ] || remove_label 'needs-human'; fi
    ;;
  gate)
    [ "$TARGET" = "$CURRENT" ] || {
      remove_label "$CURRENT"
      add_label "$TARGET"
    }
    if [ "$(target_kind "$TARGET")" = human ]; then add_label 'needs-human'; else remove_label 'needs-human'; fi
    ;;
  reset)
    remove_label "$ACTIVITY"
    ;;
  complete)
    for label in $(printf '%s\n%s\n' "$PRIMARY_LIST" "$UNKNOWN_STAGES"); do [ -z "$label" ] || remove_label "$label"; done
    [ "$HAS_ACTIVITY" = false ] || remove_label "$ACTIVITY"
    [ "$HAS_HUMAN" = false ] || remove_label 'needs-human'
    remove_label "$ACTIVATION"
    ;;
esac

CONFIRM=$(gh issue view "$ISSUE_NUMBER" --repo "$ISSUE_REPO" --json labels)
LABELS_AFTER=$(labels_json "$CONFIRM")
AFTER_PRIMARY=$(printf '%s' "$CONFIRM" | jq --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $n | ($cfg[0].states | map(.label) | index($n)) != null)]')
AFTER_COUNT=$(printf '%s' "$AFTER_PRIMARY" | jq 'length')
AFTER_ACTIVE=$(printf '%s' "$CONFIRM" | jq --arg n "$ACTIVATION" '[.labels[].name] | index($n) != null')
AFTER_ACTIVITY=$(printf '%s' "$CONFIRM" | jq --arg n "$ACTIVITY" '[.labels[].name] | index($n) != null')
AFTER_HUMAN=$(printf '%s' "$CONFIRM" | jq '[.labels[].name] | index("needs-human") != null')

if [ "$OP" = complete ]; then
  [ "$AFTER_ACTIVE" = false ] && [ "$AFTER_COUNT" -eq 0 ] && [ "$AFTER_ACTIVITY" = false ] && [ "$AFTER_HUMAN" = false ] \
    || die "Error: completion confirmation failed: $LABELS_AFTER"
else
  [ "$AFTER_ACTIVE" = true ] && [ "$AFTER_COUNT" -eq 1 ] || die "Error: expected active workflow with one primary state: $LABELS_AFTER"
  if [ "$OP" = start ]; then [ "$AFTER_ACTIVITY" = true ] || die 'Error: activity label missing after start'; fi
  if [ "$OP" = reset ] || [ "$OP" = finish ] || [ "$OP" = gate ] || [ "$OP" = migrate ] || [ "$OP" = activate ]; then
    [ "$AFTER_ACTIVITY" = false ] || die 'Error: unexpected activity label after operation'
  fi
  FINAL_PRIMARY=$(printf '%s' "$AFTER_PRIMARY" | jq -r '.[0]')
  FINAL_KIND=$(target_kind "$FINAL_PRIMARY")
  if [ "$AFTER_ACTIVITY" = true ]; then
    [ "$AFTER_HUMAN" = false ] || die 'Error: activity and needs-human coexist'
  elif [ "$FINAL_KIND" = human ]; then
    [ "$AFTER_HUMAN" = true ] || die "Error: human state '$FINAL_PRIMARY' lacks needs-human"
  else
    [ "$AFTER_HUMAN" = false ] || die "Error: agent state '$FINAL_PRIMARY' has needs-human"
  fi
fi

printf '{"issue":%s,"operation":"%s","from":%s,"to":%s,"labels":%s,"dry_run":false}\n' \
  "$ISSUE_NUMBER" "$OP" "$(printf '%s' "${CURRENT:-null}" | jq -R 'if . == "null" then null else . end')" \
  "$(printf '%s' "${TARGET:-null}" | jq -R 'if . == "null" then null else . end')" "$LABELS_AFTER"
