#!/usr/bin/env sh
set -eu

USAGE='Usage: doctor.sh [--github] [--issue N|URL]'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
STATES_FILE="$SCRIPT_DIR/../references/workflow-states.json"
CHECK_GITHUB=0
ISSUE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --github)
      CHECK_GITHUB=1
      shift
      ;;
    --issue)
      [ "$#" -ge 2 ] || {
        printf '%s\n' "$USAGE" >&2
        exit 2
      }
      ISSUE="$2"
      CHECK_GITHUB=1
      shift 2
      ;;
    --help | -h)
      printf '%s\n' "$USAGE"
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n%s\n' "$1" "$USAGE" >&2
      exit 2
      ;;
  esac
done

failed=0
for command_name in git jq python3; do
  command -v "$command_name" > /dev/null 2>&1 && printf 'PASS %s\n' "$command_name" || {
    printf 'FAIL %s\n' "$command_name" >&2
    failed=1
  }
done

jq -e '.schema_version == 2 and (.states | length == 10)' "$STATES_FILE" > /dev/null 2>&1 \
  && printf 'PASS workflow-registry\n' || {
  printf 'FAIL workflow-registry\n' >&2
  failed=1
}

git worktree list > /dev/null 2>&1 && printf 'PASS git-worktree\n' || printf 'WARN current directory is not a Git worktree\n' >&2

if [ "$CHECK_GITHUB" -eq 1 ]; then
  command -v gh > /dev/null 2>&1 || {
    printf 'FAIL gh\n' >&2
    exit 1
  }
  gh auth status > /dev/null 2>&1 && printf 'PASS gh-authentication\n' || {
    printf 'FAIL gh-authentication\n' >&2
    failed=1
  }
  gh repo view --json nameWithOwner > /dev/null 2>&1 && printf 'PASS gh-repository\n' || {
    printf 'FAIL gh-repository\n' >&2
    failed=1
  }

  if [ -n "$ISSUE" ]; then
    if issue_json=$(gh issue view "$ISSUE" --json number,url,labels); then
      printf 'PASS gh-issue %s\n' "$ISSUE"
      active=$(printf '%s' "$issue_json" | jq --slurpfile cfg "$STATES_FILE" '[.labels[].name] | index($cfg[0].activation_label) != null')
      activity=$(printf '%s' "$issue_json" | jq --slurpfile cfg "$STATES_FILE" '[.labels[].name] | index($cfg[0].activity_label) != null')
      human=$(printf '%s' "$issue_json" | jq '[.labels[].name] | index("needs-human") != null')
      primary_count=$(printf '%s' "$issue_json" | jq --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $n | ($cfg[0].states | map(.label) | index($n)) != null)] | length')
      primary=$(printf '%s' "$issue_json" | jq -r --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(. as $n | ($cfg[0].states | map(.label) | index($n)) != null)] | .[0] // empty')
      unknown_count=$(printf '%s' "$issue_json" | jq --slurpfile cfg "$STATES_FILE" '[.labels[].name | select(startswith("stage:")) | select(. != $cfg[0].activity_label) | select(. as $n | ($cfg[0].states | map(.label) | index($n)) == null)] | length')
      kind=$(jq -r --arg label "$primary" '.states[] | select(.label == $label) | .kind' "$STATES_FILE")

      if [ "$active" = true ] && [ "$primary_count" -ne 1 ]; then
        printf 'FAIL drift: active issue needs exactly one primary state\n' >&2
        failed=1
      fi
      if [ "$active" = true ] && [ "$unknown_count" -ne 0 ]; then
        printf 'FAIL drift: active issue has unknown stage labels\n' >&2
        failed=1
      fi
      if [ "$activity" = true ] && [ "$human" = true ]; then
        printf 'FAIL drift: stage:in-progress with needs-human\n' >&2
        failed=1
      fi
      if [ "$active" = true ] && [ "$activity" = false ] && [ "$kind" = human ] && [ "$human" = false ]; then
        printf 'FAIL drift: human state without needs-human\n' >&2
        failed=1
      fi
      if [ "$active" = true ] && [ "$activity" = false ] && [ "$kind" = agent ] && [ "$human" = true ]; then
        printf 'FAIL drift: agent state with needs-human\n' >&2
        failed=1
      fi

      "$SCRIPT_DIR/transition-issue.sh" "$ISSUE" --start-work --role "$(jq -r --arg label "$primary" '.states[] | select(.label == $label) | .actor' "$STATES_FILE")" --require-from "$primary" --dry-run > /dev/null 2>&1 \
        && printf 'PASS transition-issue-dry-run\n' \
        || printf 'WARN transition dry-run not eligible for current state\n' >&2

      if "$SCRIPT_DIR/validate-evidence.sh" "$ISSUE" > /dev/null 2>&1; then
        printf 'PASS validate-evidence\n'
      else
        printf 'FAIL validate-evidence (run validate-evidence.sh for details)\n' >&2
        failed=1
      fi
    else
      printf 'FAIL gh issue access: %s\n' "$ISSUE" >&2
      failed=1
    fi
  fi
fi

[ "$failed" -eq 0 ]
