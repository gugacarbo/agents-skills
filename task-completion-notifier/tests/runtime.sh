#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
state="$skill_root/tests/.runtime-state-$$"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir" "$state"' EXIT
mkdir -p "$state"

fake="$tmpdir/fake-notifier"
capture="$tmpdir/capture"
cat >"$fake" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" >"$FAKE_CAPTURE"
exit "${FAKE_EXIT:-0}"
EOF
chmod +x "$fake"

json_field() { python3 -c 'import json,sys; json.dump(json.load(sys.stdin)[sys.argv[1]],sys.stdout)' "$1"; }
run_state() { python3 "$skill_root/scripts/session-state.py" "$@"; }
dispatch() { FAKE_CAPTURE="$capture" FAKE_EXIT="${FAKE_EXIT:-0}" python3 "$skill_root/scripts/hook-dispatch.py" "$@"; }

[[ "$(run_state status --state-dir "$state" --session-id s1 | json_field active)" == false ]]
[[ "$(run_state activate --state-dir "$state" --session-id s1 | json_field active)" == true ]]
active=$(dispatch --agent worker --event task-complete --state-dir "$state" --notifier "$fake" --session-id s1)
[[ "$(printf '%s' "$active" | json_field notified)" == true ]]
[[ "$(sed -n '2p' "$capture")" == 'worker: task-complete completed' ]]

run_state deactivate --state-dir "$state" s1 >/dev/null
[[ "$(dispatch --agent worker --event task-complete --state-dir "$state" --notifier "$fake" --session-id s1 | json_field noop)" == true ]]

run_state activate --state-dir "$state" --session-id s1 >/dev/null
if FAKE_EXIT=7 dispatch --agent worker --event failed --state-dir "$state" --notifier "$fake" --session-id s1 >/dev/null; then
  echo 'expected notifier failure' >&2
  exit 1
fi
if dispatch --agent worker --event failed --state-dir "$state" --notifier "$tmpdir/missing" --session-id s1 >/dev/null; then
  echo 'expected missing notifier failure' >&2
  exit 1
fi

echo 'task-completion-notifier runtime tests passed'
