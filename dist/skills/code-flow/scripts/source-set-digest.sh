#!/usr/bin/env bash
set -euo pipefail

usage='Usage: source-set-digest.sh [--print-canonical] [BODY]'
print_canonical=0
body=''

while (($#)); do
  case "$1" in
    --print-canonical) print_canonical=1 ;;
    -h | --help)
      printf '%s\n' "$usage"
      exit 0
      ;;
    -*)
      printf 'Unknown flag: %s\n%s\n' "$1" "$usage" >&2
      exit 2
      ;;
    *)
      [[ -z "$body" ]] || {
        printf '%s\n' "$usage" >&2
        exit 2
      }
      body=$1
      ;;
  esac
  shift
done

command -v iconv > /dev/null 2>&1 || {
  printf 'Error: iconv is required\n' >&2
  exit 1
}
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/code-flow-digest.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT
raw="$tmp_dir/raw"
normalized="$tmp_dir/normalized"
canonical="$tmp_dir/canonical"

if [[ -n "$body" ]]; then
  [[ -f "$body" ]] || {
    printf 'Error: file not found: %s\n' "$body" >&2
    exit 1
  }
  cp "$body" "$raw"
else
  dd of="$raw" status=none
fi

iconv -f UTF-8 -t UTF-8 "$raw" > /dev/null 2>&1 || {
  printf 'Error: body must be valid UTF-8\n' >&2
  exit 1
}

sed $'s/\\r$//; s/\\r/\\n/g' "$raw" > "$normalized"
awk '
  function trimmed(value) {
    sub(/^[[:space:]]+/, "", value)
    sub(/[[:space:]]+$/, "", value)
    return value
  }
  {
    marker = trimmed($0)
    if (marker == "<!-- code-flow:architect-review:start -->") {
      starts++; start_line = NR; inside = 1; next
    }
    if (marker == "<!-- code-flow:architect-review:end -->") {
      ends++; end_line = NR; inside = 0; next
    }
    if (inside) payload[++count] = $0
  }
  END {
    if (starts != 1 || ends != 1 || start_line >= end_line) exit 42
    while (count > 0 && payload[count] == "") count--
    if (count == 0) { printf "\n"; exit }
    for (i = 1; i <= count; i++) print payload[i]
  }
' "$normalized" > "$canonical" || {
  printf 'Error: body must contain exactly one ordered architect-review marker pair\n' >&2
  exit 1
}

((print_canonical == 0)) || cat "$canonical"
if command -v sha256sum > /dev/null 2>&1; then
  sha256sum "$canonical" | awk '{print $1}'
elif command -v shasum > /dev/null 2>&1; then
  shasum -a 256 "$canonical" | awk '{print $1}'
else
  printf 'Error: sha256sum or shasum is required\n' >&2
  exit 1
fi
