#!/usr/bin/env bash
set -euo pipefail

usage='Usage: validate-plan.sh FILE | --comments-json FILE|-'

validate_file() {
  local file="$1" start_line end_line required event_marker_count event_json
  [[ -f "$file" ]] || return 1
  [[ "$(grep -Fc '<!-- code-flow:implementation-plan:start -->' "$file" || true)" -eq 1 ]] || return 1
  [[ "$(grep -Fc '<!-- code-flow:implementation-plan:end -->' "$file" || true)" -eq 1 ]] || return 1
  start_line=$(grep -n -m1 -F '<!-- code-flow:implementation-plan:start -->' "$file" | cut -d: -f1)
  end_line=$(grep -n -m1 -F '<!-- code-flow:implementation-plan:end -->' "$file" | cut -d: -f1)
  [[ "$start_line" -lt "$end_line" ]] || return 1
  grep -Fq '> agent: planner' "$file" || return 1
  event_marker_count=$(grep -oF '<!-- code-flow:event:v1' "$file" | wc -l | tr -d '[:space:]')
  [[ "$event_marker_count" -eq 1 ]] || return 1
  event_json=$(sed -nE 's/^[[:space:]]*<!--[[:space:]]*code-flow:event:v1[[:space:]]+(\{.*\})[[:space:]]*-->[[:space:]]*$/\1/p' "$file")
  [[ -n "$event_json" ]] || return 1
  [[ "$(printf '%s\n' "$event_json" | wc -l | tr -d '[:space:]')" -eq 1 ]] || return 1
  printf '%s\n' "$event_json" | jq -e 'type == "object" and .role == "planner"' > /dev/null || return 1
  for required in \
    '## Base SHA, escopo e definição de pronto' \
    '## Ondas e tarefas' \
    '### Onda ' \
    'Task ID' \
    'Owner/subagent' \
    'Dependências' \
    'Áreas/arquivos esperados' \
    'Validação' \
    'Paralelismo seguro' \
    '## Barreiras de integração' \
    '## Validação global' \
    '## Rollback/reconciliação' \
    '## Handoff final'; do
    grep -Fq "$required" <(sed -n "${start_line},${end_line}p" "$file") || return 1
  done
}

if [[ "$#" -eq 1 && "$1" != --comments-json ]]; then
  validate_file "$1"
  exit $?
fi

[[ "$#" -eq 2 && "$1" == --comments-json ]] || { printf '%s\n' "$usage" >&2; exit 2; }
comment_json="$2"
if [[ "$comment_json" == - ]]; then
  comment_json=$(mktemp "${TMPDIR:-/tmp}/code-flow-comments.XXXXXX")
  trap 'rm -f "$comment_json"' EXIT
  cat > "$comment_json"
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/code-flow-plan.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT
valid=0
index=0
while IFS= read -r encoded; do
  index=$((index + 1))
  file="$tmp_dir/comment-$index.md"
  printf '%s' "$encoded" | base64 --decode > "$file"
  if validate_file "$file"; then valid=$((valid + 1)); fi
done < <(jq -r '.comments[]?.body // "" | @base64' "$comment_json")
printf '%s\n' "$valid"
[[ "$valid" -eq 1 ]]
