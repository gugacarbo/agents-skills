#!/usr/bin/env sh
set -eu

# Best-effort mutate code-flow stage:* / needs-human labels on a GitHub issue.
# Not a single atomic API call: remove-then-add can leave zero stage:* if a
# later gh edit fails — confirm after and repair with --allow-repair if needed.
# Does not post comments or choose the next stage — the orchestrator decides.

USAGE='Usage: transition-issue.sh <N|URL> [--to stage:…] [--needs-human|--clear-needs-human] [--clear-stage] [--require-from stage:…] [--dry-run] [--allow-repair]'

VALID_STAGES='
stage:spec-approval
stage:needs-plan
stage:needs-plan-review
stage:approved
stage:in-progress
stage:needs-delivery-review
stage:needs-changes
stage:ready-to-merge
stage:blocked
'

ISSUE=""
TO=""
REQUIRE_FROM=""
NEEDS_HUMAN=""
CLEAR_NEEDS_HUMAN=0
CLEAR_STAGE=0
DRY_RUN=0
ALLOW_REPAIR=0

die() { printf '%s\n' "$1" >&2; exit 1; }

is_valid_stage() {
  printf '%s' "$VALID_STAGES" | grep -Fxq -- "$1"
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --to)
      [ "$#" -ge 2 ] || die "$USAGE"
      TO="$2"
      shift 2
      ;;
    --require-from)
      [ "$#" -ge 2 ] || die "$USAGE"
      REQUIRE_FROM="$2"
      shift 2
      ;;
    --needs-human) NEEDS_HUMAN=1; shift ;;
    --clear-needs-human) CLEAR_NEEDS_HUMAN=1; shift ;;
    --clear-stage) CLEAR_STAGE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --allow-repair) ALLOW_REPAIR=1; shift ;;
    --help|-h) printf '%s\n' "$USAGE"; exit 0 ;;
    -*)
      die "Unknown flag: $1
$USAGE"
      ;;
    *)
      [ -z "$ISSUE" ] || die "$USAGE"
      ISSUE="$1"
      shift
      ;;
  esac
done

[ -n "$ISSUE" ] || die "$USAGE"
[ -n "$TO" ] || [ "$CLEAR_STAGE" -eq 1 ] || die "Error: provide --to stage:… or --clear-stage
$USAGE"
[ -z "$TO" ] || [ "$CLEAR_STAGE" -eq 0 ] || die "Error: --to and --clear-stage are mutually exclusive"
[ -z "$NEEDS_HUMAN" ] || [ "$CLEAR_NEEDS_HUMAN" -eq 0 ] || die "Error: --needs-human and --clear-needs-human are mutually exclusive"

command -v gh >/dev/null 2>&1 || die "Error: gh is required"
command -v jq >/dev/null 2>&1 || die "Error: jq is required"

if [ -n "$TO" ]; then
  is_valid_stage "$TO" || die "Error: invalid stage '$TO'"
fi
if [ -n "$REQUIRE_FROM" ]; then
  is_valid_stage "$REQUIRE_FROM" || die "Error: invalid --require-from '$REQUIRE_FROM'"
fi

ISSUE_JSON=$(gh issue view "$ISSUE" --json number,labels,url)
ISSUE_NUMBER=$(printf '%s' "$ISSUE_JSON" | jq -r '.number')
[ -n "$ISSUE_NUMBER" ] && [ "$ISSUE_NUMBER" != "null" ] || die "Error: could not resolve issue: $ISSUE"

CURRENT_STAGES=$(printf '%s' "$ISSUE_JSON" | jq -r '[.labels[].name | select(startswith("stage:"))] | join("\n")')
STAGE_COUNT=$(printf '%s' "$ISSUE_JSON" | jq '[.labels[].name | select(startswith("stage:"))] | length')
HAS_NEEDS_HUMAN=$(printf '%s' "$ISSUE_JSON" | jq '[.labels[].name | select(. == "needs-human")] | length')
FROM_LIST=$(printf '%s' "$ISSUE_JSON" | jq -c '[.labels[].name | select(startswith("stage:"))]')

if [ -n "$REQUIRE_FROM" ]; then
  printf '%s\n' "$CURRENT_STAGES" | grep -Fxq -- "$REQUIRE_FROM" \
    || die "Error: expected current stage '$REQUIRE_FROM' on #$ISSUE_NUMBER; found: ${CURRENT_STAGES:-"(none)"}"
fi

if [ "$CLEAR_STAGE" -eq 0 ] && [ "$ALLOW_REPAIR" -eq 0 ]; then
  if [ "$STAGE_COUNT" -eq 0 ] || [ "$STAGE_COUNT" -gt 1 ]; then
    die "Error: issue #$ISSUE_NUMBER has $STAGE_COUNT stage:* label(s); use --allow-repair or fix manually (found: ${CURRENT_STAGES:-none})"
  fi
fi

# Ensure target labels exist in the repository before mutating.
REPO_LABELS=$(gh label list --limit 200 --json name -q '.[].name')
label_exists() {
  printf '%s\n' "$REPO_LABELS" | grep -Fxq -- "$1"
}

if [ -n "$TO" ]; then
  label_exists "$TO" || die "Error: repository label '$TO' does not exist; create it before transitioning"
fi
if [ -n "$NEEDS_HUMAN" ]; then
  label_exists "needs-human" || die "Error: repository label 'needs-human' does not exist; create it before transitioning"
fi

REMOVE_STAGES="$CURRENT_STAGES"
PLANNED_NEEDS_HUMAN="$HAS_NEEDS_HUMAN"
if [ -n "$NEEDS_HUMAN" ]; then
  PLANNED_NEEDS_HUMAN=1
elif [ "$CLEAR_NEEDS_HUMAN" -eq 1 ]; then
  PLANNED_NEEDS_HUMAN=0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  TO_JSON="null"
  [ -z "$TO" ] || TO_JSON="\"$(json_escape "$TO")\""
  NEEDS_JSON=false
  [ "$PLANNED_NEEDS_HUMAN" -eq 1 ] && NEEDS_JSON=true
  printf '{"issue":%s,"from":%s,"to":%s,"needs_human":%s,"dry_run":true,"labels":null}\n' \
    "$ISSUE_NUMBER" "$FROM_LIST" "$TO_JSON" "$NEEDS_JSON"
  exit 0
fi

# Remove every existing stage:* label.
if [ -n "$REMOVE_STAGES" ]; then
  printf '%s\n' "$REMOVE_STAGES" | while IFS= read -r stage_label; do
    [ -n "$stage_label" ] || continue
    gh issue edit "$ISSUE_NUMBER" --remove-label "$stage_label" >/dev/null
  done
fi

# Confirm removals before adding (narrows the empty-stage window on failure).
if [ -n "$REMOVE_STAGES" ] || [ -n "$TO" ]; then
  AFTER_REMOVE=$(gh issue view "$ISSUE_NUMBER" --json labels)
  AFTER_REMOVE_COUNT=$(printf '%s' "$AFTER_REMOVE" | jq '[.labels[].name | select(startswith("stage:"))] | length')
  if [ -n "$TO" ] && [ "$AFTER_REMOVE_COUNT" -ne 0 ]; then
    die "Error: expected zero stage:* after remove before adding '$TO'; got $AFTER_REMOVE_COUNT — repair manually or retry with --allow-repair"
  fi
  if [ "$CLEAR_STAGE" -eq 1 ] && [ "$AFTER_REMOVE_COUNT" -ne 0 ]; then
    die "Error: --clear-stage left $AFTER_REMOVE_COUNT stage:* label(s)"
  fi
fi

if [ -n "$TO" ]; then
  gh issue edit "$ISSUE_NUMBER" --add-label "$TO" >/dev/null \
    || die "Error: failed to add '$TO' after removing prior stage:* — issue may have zero stage:*; repair with --allow-repair --to $TO"
fi

if [ -n "$NEEDS_HUMAN" ]; then
  if [ "$HAS_NEEDS_HUMAN" -eq 0 ]; then
    gh issue edit "$ISSUE_NUMBER" --add-label "needs-human" >/dev/null
  fi
elif [ "$CLEAR_NEEDS_HUMAN" -eq 1 ]; then
  if [ "$HAS_NEEDS_HUMAN" -gt 0 ]; then
    gh issue edit "$ISSUE_NUMBER" --remove-label "needs-human" >/dev/null
  fi
fi

CONFIRM=$(gh issue view "$ISSUE_NUMBER" --json labels)
CONFIRM_STAGES=$(printf '%s' "$CONFIRM" | jq '[.labels[].name | select(startswith("stage:"))]')
CONFIRM_STAGE_COUNT=$(printf '%s' "$CONFIRM" | jq '[.labels[].name | select(startswith("stage:"))] | length')
CONFIRM_NEEDS=$(printf '%s' "$CONFIRM" | jq '[.labels[].name | select(. == "needs-human")] | length')
ALL_LABELS=$(printf '%s' "$CONFIRM" | jq -c '[.labels[].name]')

if [ -n "$TO" ]; then
  [ "$CONFIRM_STAGE_COUNT" -eq 1 ] || die "Error: after mutation expected exactly one stage:*; got $CONFIRM_STAGE_COUNT ($CONFIRM_STAGES)"
  printf '%s' "$CONFIRM" | jq -e --arg to "$TO" '[.labels[].name] | index($to) != null' >/dev/null \
    || die "Error: after mutation missing expected label $TO"
elif [ "$CLEAR_STAGE" -eq 1 ]; then
  [ "$CONFIRM_STAGE_COUNT" -eq 0 ] || die "Error: after --clear-stage expected zero stage:*; got $CONFIRM_STAGE_COUNT"
fi

if [ -n "$NEEDS_HUMAN" ]; then
  [ "$CONFIRM_NEEDS" -ge 1 ] || die "Error: after mutation expected needs-human"
elif [ "$CLEAR_NEEDS_HUMAN" -eq 1 ]; then
  [ "$CONFIRM_NEEDS" -eq 0 ] || die "Error: after mutation expected needs-human removed"
fi

TO_JSON="null"
[ -z "$TO" ] || TO_JSON="\"$(json_escape "$TO")\""
NEEDS_JSON=false
[ "$CONFIRM_NEEDS" -ge 1 ] && NEEDS_JSON=true

printf '{"issue":%s,"from":%s,"to":%s,"needs_human":%s,"dry_run":false,"labels":%s}\n' \
  "$ISSUE_NUMBER" "$FROM_LIST" "$TO_JSON" "$NEEDS_JSON" "$ALL_LABELS"
