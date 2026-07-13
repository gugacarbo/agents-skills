#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
repo="$tmpdir/repo with space"
mkdir -p "$repo"
state_home="$tmpdir/state"
fake="$tmpdir/fake-notifier"
capture="$tmpdir/capture"

cat >"$fake" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" >>"$FAKE_CAPTURE"
if [ "${FAKE_CORRUPT_STATE:-}" = ack ]; then
  printf '{}\n' >"$STATE_FILE"
fi
exit "${FAKE_EXIT:-0}"
EOF
chmod +x "$fake"

json_field() { python3 -c 'import json,sys; json.dump(json.load(sys.stdin)[sys.argv[1]], sys.stdout)' "$1"; }
run_state() { XDG_STATE_HOME="$state_home" python3 "$skill_root/scripts/session-state.py" "$@"; }
dispatch() { XDG_STATE_HOME="$state_home" FAKE_CAPTURE="$capture" FAKE_EXIT="${FAKE_EXIT:-0}" FAKE_CORRUPT_STATE="${FAKE_CORRUPT_STATE:-}" STATE_FILE="${STATE_FILE:-}" python3 "$skill_root/scripts/hook-dispatch.py" --json "$@"; }

[[ "$(run_state status --repo-root "$repo" --agent cursor --session-id s1 | json_field active)" == false ]]
run_state arm --repo-root "$repo" --agent cursor --session-id s1 --delivery-id one --message 'Task complete' --title Done >/dev/null
[[ "$(run_state arm --repo-root "$repo" --agent cursor --session-id s1 --delivery-id one --message duplicate | json_field armed)" == false ]]
active=$(dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id s1)
[[ "$(printf '%s' "$active" | json_field notified)" == true ]]
mapfile -t capture_lines <"$capture"
[[ "${capture_lines[*]}" == '--message Task complete --title Done' ]]
[[ "$(dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id s1 | json_field noop)" == true ]]

# Cursor payloads may identify a conversation rather than a session.
run_state arm --repo-root "$repo" --agent cursor --session-id conversation-1 --message cursor-payload >/dev/null
payload=$(printf '%s\n' '{"conversation_id":"conversation-1","hook_event_name":"stop"}' | dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake")
[[ "$(printf '%s' "$payload" | json_field notified)" == true ]]

# A session preserves a FIFO queue instead of overwriting a prior completion.
run_state arm --repo-root "$repo" --agent cursor --session-id queued --delivery-id first --message first >/dev/null
run_state arm --repo-root "$repo" --agent cursor --session-id queued --delivery-id second --message second >/dev/null
[[ "$(run_state status --repo-root "$repo" --agent cursor --session-id queued | json_field pending_count)" == 2 ]]
dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id queued >/dev/null
dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id queued >/dev/null
first_line=$(grep -n -Fx 'first' "$capture" | head -n 1 | cut -d: -f1)
second_line=$(grep -n -Fx 'second' "$capture" | head -n 1 | cut -d: -f1)
[[ "$first_line" -lt "$second_line" ]]

# The same session ID in a different host cannot consume the pending completion.
run_state arm --repo-root "$repo" --agent cursor --session-id s2 --message isolated >/dev/null
[[ "$(dispatch --agent github-copilot --event agentStop --repo-root "$repo" --notifier "$fake" --session-id s2 | json_field noop)" == true ]]
[[ "$(dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id s2 | json_field notified)" == true ]]

# Failed delivery is released and can be retried.
run_state arm --repo-root "$repo" --agent cursor --session-id retry --message retry-me >/dev/null
if FAKE_EXIT=7 dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id retry >/dev/null; then
  echo 'expected notifier failure' >&2
  exit 1
fi
[[ "$(run_state status --repo-root "$repo" --agent cursor --session-id retry | json_field active)" == true ]]
[[ "$(dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id retry | json_field notified)" == true ]]

# An acknowledgment failure is reported without an unhandled traceback.
run_state arm --repo-root "$repo" --agent cursor --session-id ack-error --message ack-error >/dev/null
STATE_FILE=$(find "$state_home" -name sessions.json -print -quit)
if output=$(FAKE_CORRUPT_STATE=ack dispatch --agent cursor --event stop --repo-root "$repo" --notifier "$fake" --session-id ack-error 2>&1); then
  echo 'expected acknowledgement failure' >&2
  exit 1
fi
[[ "$output" == *'acknowledgment failed'* ]]
[[ "$output" != *Traceback* ]]
rm -f "$STATE_FILE"

# Concurrent lifecycle events can claim a delivery only once.
run_state arm --repo-root "$repo" --agent cursor --session-id race --message race >/dev/null
run_state claim --repo-root "$repo" --agent cursor --session-id race >"$tmpdir/claim-a" &
first=$!
run_state claim --repo-root "$repo" --agent cursor --session-id race >"$tmpdir/claim-b" &
second=$!
wait "$first" "$second"
claims=$(cat "$tmpdir/claim-a" "$tmpdir/claim-b" | python3 -c 'import json,sys; print(sum(json.loads(line)["claimed"] for line in sys.stdin))')
[[ "$claims" == 1 ]]

# A stale claim is recovered into the pending queue by garbage collection.
STATE_FILE=$(find "$state_home" -name sessions.json -print -quit)
python3 - "$STATE_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
state = json.load(open(path, encoding="utf-8"))
for delivery in state["deliveries"].values():
    delivery["claim_deadline"] = 0
json.dump(state, open(path, "w", encoding="utf-8"))
PY
[[ "$(run_state gc --repo-root "$repo" | json_field changed)" == true ]]
[[ "$(run_state status --repo-root "$repo" --agent cursor --session-id race | json_field active)" == true ]]

if dispatch --agent cursor --event agentStop --repo-root "$repo" --notifier "$fake" --session-id race >/dev/null; then
  echo 'expected invalid host event' >&2
  exit 1
fi

# Malformed state is reported as JSON, not a traceback.
printf '{}\n' >"$STATE_FILE"
if output=$(run_state status --repo-root "$repo" --agent cursor --session-id retry 2>&1); then
  echo 'expected invalid state failure' >&2
  exit 1
fi
[[ "$output" == *'state file has an invalid format'* ]]
[[ "$output" != *Traceback* ]]

# Version 2 state is migrated without losing a pending delivery.
legacy="$tmpdir/legacy"
mkdir -p "$legacy"
printf '%s\n' '{"version":2,"sessions":{"cursor:legacy":{"message":"legacy","title":null,"expires_at":9999999999}},"deliveries":{}}' >"$legacy/sessions.json"
[[ "$(python3 "$skill_root/scripts/session-state.py" status --state-dir "$legacy" --agent cursor --session-id legacy | json_field active)" == true ]]
grep -Fq '"version": 3' "$legacy/sessions.json"

printf 'task-completion-notifier runtime tests passed\n'
