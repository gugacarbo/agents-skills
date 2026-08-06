#!/usr/bin/env sh
set -eu

USAGE='Usage: update-issue-header.sh <N|URL> --type TYPE --complexity XS|S|M|L|XL --project-guidance TEXT'
ISSUE=''
ISSUE_TYPE=''
COMPLEXITY=''
PROJECT_GUIDANCE=''

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --type)
      [ "$#" -ge 2 ] || die "$USAGE"
      ISSUE_TYPE="$2"
      shift 2
      ;;
    --complexity)
      [ "$#" -ge 2 ] || die "$USAGE"
      COMPLEXITY="$2"
      shift 2
      ;;
    --project-guidance)
      [ "$#" -ge 2 ] || die "$USAGE"
      PROJECT_GUIDANCE="$2"
      shift 2
      ;;
    -h | --help)
      printf '%s\n' "$USAGE"
      exit 0
      ;;
    -*) die "Unknown option: $1\n$USAGE" ;;
    *)
      [ -z "$ISSUE" ] || die "$USAGE"
      ISSUE="$1"
      shift
      ;;
  esac
done

[ -n "$ISSUE" ] && [ -n "$ISSUE_TYPE" ] && [ -n "$COMPLEXITY" ] && [ -n "$PROJECT_GUIDANCE" ] || die "$USAGE"
case "$ISSUE_TYPE" in issue | bug | feature | docs | epic) ;; *) die "Error: invalid issue type '$ISSUE_TYPE'" ;; esac
case "$COMPLEXITY" in XS | S | M | L | XL) ;; *) die "Error: invalid complexity '$COMPLEXITY'" ;; esac
case "$ISSUE_TYPE$COMPLEXITY$PROJECT_GUIDANCE" in *'
'*) die 'Error: header values must be single-line' ;; esac

command -v gh > /dev/null 2>&1 || die 'Error: gh is required'
command -v jq > /dev/null 2>&1 || die 'Error: jq is required'

ISSUE_JSON=$(gh issue view "$ISSUE" --json number,url,body)
ISSUE_NUMBER=$(printf '%s' "$ISSUE_JSON" | jq -r '.number')
ISSUE_URL=$(printf '%s' "$ISSUE_JSON" | jq -r '.url')
ISSUE_REPO=$(printf '%s' "$ISSUE_URL" | sed -n 's#https\?://[^/]*/\([^/]*/[^/]*/\)issues/[0-9][0-9]*#\1#p' | sed 's#/$##')
BODY=$(printf '%s' "$ISSUE_JSON" | jq -r '.body // ""')
[ -n "$ISSUE_REPO" ] || die 'Error: could not resolve issue repository'

if [ -z "$(printf '%s' "$BODY" | tr -d '[:space:]')" ]; then
  printf '{"updated":false,"reason":"blank_body"}\n'
  exit 0
fi

START='<!-- code-flow:issue-header:start -->'
END='<!-- code-flow:issue-header:end -->'
REST=$BODY
case "$BODY" in
  "$START"*)
    printf '%s\n' "$BODY" | grep -Fqx "$END" || die 'Error: issue header start marker has no end marker'
    REST=$(printf '%s\n' "$BODY" | sed "1,/^$END\$/d" | sed '1{/^$/d;}')
    ;;
esac

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT HUP INT TERM
{
  printf '%s\n' "$START"
  printf '> type: %s\n' "$ISSUE_TYPE"
  printf '> Complexity: %s\n' "$COMPLEXITY"
  printf '> project_guidance: %s\n' "$PROJECT_GUIDANCE"
  printf '%s\n\n' "$END"
  printf '%s\n' "$REST"
} > "$TEMP_FILE"

gh issue edit "$ISSUE_NUMBER" --repo "$ISSUE_REPO" --body-file "$TEMP_FILE" > /dev/null
printf '{"updated":true,"issue":%s,"complexity":%s}\n' "$ISSUE_NUMBER" "$(printf '%s' "$COMPLEXITY" | jq -R .)"
