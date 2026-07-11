#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
TITLE='Tarefa concluída'
MESSAGE=''

usage() {
  printf '%s\n' 'Usage: notify.sh --message <text> [--title <text>]' >&2
  exit 2
}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --message)
      [ "$#" -ge 2 ] || usage
      MESSAGE=$2
      shift 2
      ;;
    --title)
      [ "$#" -ge 2 ] || usage
      TITLE=$2
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[ -n "$MESSAGE" ] || fail '--message must not be empty'
[ -n "$TITLE" ] || fail '--title must not be empty'

case "$(uname -s)" in
  Linux)
    # shellcheck source=adapters/ubuntu.sh
    . "$SCRIPT_DIR/adapters/ubuntu.sh"
    notify_ubuntu "$TITLE" "$MESSAGE"
    ;;
  *)
    fail 'unsupported platform; v1 supports Ubuntu desktop only'
    ;;
esac
