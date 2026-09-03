#!/usr/bin/env sh
set -eu

USAGE='Usage: update-issue-body.sh <N|URL> --body-file FILE --event-file FILE'
ISSUE=''
BODY_FILE=''
EVENT_FILE=''

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --body-file)
      [ "$#" -ge 2 ] || die "$USAGE"
      BODY_FILE="$2"
      shift 2
      ;;
    --event-file)
      [ "$#" -ge 2 ] || die "$USAGE"
      EVENT_FILE="$2"
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

[ -n "$ISSUE" ] && [ -n "$BODY_FILE" ] && [ -n "$EVENT_FILE" ] || die "$USAGE"
[ -f "$BODY_FILE" ] || die "Error: body file not found: $BODY_FILE"
[ -f "$EVENT_FILE" ] || die "Error: event file not found: $EVENT_FILE"
command -v gh > /dev/null 2>&1 || die 'Error: gh is required'
command -v iconv > /dev/null 2>&1 || die 'Error: iconv is required'
command -v jq > /dev/null 2>&1 || die 'Error: jq is required'
iconv -f UTF-8 -t UTF-8 "$BODY_FILE" > /dev/null 2>&1 || die 'Error: body must be valid UTF-8'

CONTRACT=$(cat "$BODY_FILE")
[ -n "$(printf '%s' "$CONTRACT" | tr -d '[:space:]')" ] || die 'Error: body must not be blank'

TRIAGE_START='<!-- code-flow:triage:start -->'
TRIAGE_END='<!-- code-flow:triage:end -->'
ORIGINAL_START='<!-- code-flow:original-report:start -->'
ORIGINAL_END='<!-- code-flow:original-report:end -->'
HEADER_START='<!-- code-flow:issue-header:start -->'
HEADER_END='<!-- code-flow:issue-header:end -->'
EVENT_PREFIX='<!-- code-flow:event:v1 '

for marker in "$TRIAGE_START" "$TRIAGE_END" "$ORIGINAL_START" "$ORIGINAL_END" "$EVENT_PREFIX"; do
  printf '%s\n' "$CONTRACT" | grep -Fq "$marker" && die "Error: prepared body contains managed marker: $marker"
done

EVENT=$(jq -c . "$EVENT_FILE") || die 'Error: event must be valid JSON'
jq -e '
  type == "object" and
  .role == "dispatcher" and
  (.event_id | type == "string" and length > 0) and
  (.run_id | type == "string" and length > 0) and
  (.state_before | type == "string") and
  (.state_after | type == "string") and
  (.result.status | IN("completed", "waiting_human", "blocked"))
' "$EVENT_FILE" > /dev/null || die 'Error: event must be a dispatcher result'

ISSUE_JSON=$(gh issue view "$ISSUE" --json number,url,body)
ISSUE_NUMBER=$(printf '%s' "$ISSUE_JSON" | jq -r '.number')
ISSUE_URL=$(printf '%s' "$ISSUE_JSON" | jq -r '.url')
ISSUE_REPO=$(printf '%s' "$ISSUE_URL" | sed -n 's#https\?://[^/]*/\([^/]*/[^/]*/\)issues/[0-9][0-9]*#\1#p' | sed 's#/$##')
CURRENT_BODY=$(printf '%s' "$ISSUE_JSON" | jq -r '.body // ""')
[ -n "$ISSUE_REPO" ] || die 'Error: could not resolve issue repository'

ORIGINAL=$CURRENT_BODY
case "$CURRENT_BODY" in
  "$TRIAGE_START"*)
    printf '%s\n' "$CURRENT_BODY" | grep -Fqx "$TRIAGE_END" || die 'Error: triage start marker has no end marker'
    if printf '%s\n' "$CURRENT_BODY" | grep -Fqx "$ORIGINAL_START"; then
      printf '%s\n' "$CURRENT_BODY" | grep -Fqx "$ORIGINAL_END" || die 'Error: original report start marker has no end marker'
      ORIGINAL=$(printf '%s\n' "$CURRENT_BODY" | awk -v start="$ORIGINAL_START" -v end="$ORIGINAL_END" '
        $0 == start { capture = 1; next }
        $0 == end && capture { exit }
        capture { print }
      ')
    else
      ORIGINAL=''
    fi
    ;;
  "$HEADER_START"*)
    printf '%s\n' "$CURRENT_BODY" | grep -Fqx "$HEADER_END" || die 'Error: issue header start marker has no end marker'
    ORIGINAL=$(printf '%s\n' "$CURRENT_BODY" | sed "1,/^$HEADER_END\$/d" | sed '1{/^$/d;}')
    ;;
esac

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT HUP INT TERM
{
  printf '%s\n' "$TRIAGE_START"
  printf '<!-- code-flow:event:v1 %s -->\n\n' "$EVENT"
  printf '%s\n' "$CONTRACT"
  if [ -n "$(printf '%s' "$ORIGINAL" | tr -d '[:space:]')" ]; then
    printf '\n## Relato original\n\n'
    printf '%s\n' "$ORIGINAL_START"
    printf '%s\n' "$ORIGINAL"
    printf '%s\n' "$ORIGINAL_END"
  fi
  printf '\n%s\n' "$TRIAGE_END"
} > "$TEMP_FILE"

gh issue edit "$ISSUE_NUMBER" --repo "$ISSUE_REPO" --body-file "$TEMP_FILE" > /dev/null
if [ -n "$(printf '%s' "$ORIGINAL" | tr -d '[:space:]')" ]; then
  PRESERVED=true
else
  PRESERVED=false
fi
printf '{"updated":true,"issue":%s,"preserved_original":%s}\n' "$ISSUE_NUMBER" "$PRESERVED"
