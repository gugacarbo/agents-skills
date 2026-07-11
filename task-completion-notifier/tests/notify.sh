#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$skill_root/scripts/notify.sh"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin"
printf 'ID=ubuntu\n' >"$tmpdir/os-release"

cat >"$tmpdir/bin/uname" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "${FAKE_UNAME:-Linux}"
EOF

cat >"$tmpdir/bin/notify-send" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" >"$NOTIFY_CAPTURE"
if [ "${NOTIFY_SEND_EXIT:-0}" -ne 0 ]; then
  exit "$NOTIFY_SEND_EXIT"
fi
EOF
chmod +x "$tmpdir/bin/uname" "$tmpdir/bin/notify-send"

run() {
  PATH="$tmpdir/bin:$PATH" \
  NOTIFY_OS_RELEASE_FILE="$tmpdir/os-release" \
  DISPLAY=':1' \
  DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/test-bus' \
  NOTIFY_CAPTURE="$tmpdir/capture" \
  "$@"
}

expect_failure() {
  local expected=$1
  shift
  if output=$(run "$@" 2>&1); then
    printf 'Expected command to fail: %s\n' "$*" >&2
    exit 1
  fi
  [[ "$output" == *"$expected"* ]] || {
    printf 'Expected error containing %q, got: %s\n' "$expected" "$output" >&2
    exit 1
  }
}

run sh "$script" --message 'Task finished' --title 'Done'
mapfile -t capture <"$tmpdir/capture"
[[ "${capture[*]}" == '-- Done Task finished' ]]

expect_failure '--message must not be empty' sh "$script"
expect_failure 'unknown argument' sh "$script" --message hello --unknown
expect_failure 'unsupported platform' env FAKE_UNAME=Darwin sh "$script" --message hello
expect_failure 'unsupported Linux distribution' env NOTIFY_OS_RELEASE_FILE=/dev/null sh "$script" --message hello
expect_failure 'no graphical session' env DISPLAY= WAYLAND_DISPLAY= sh "$script" --message hello
expect_failure 'no D-Bus session' env DBUS_SESSION_BUS_ADDRESS= sh "$script" --message hello
expect_failure 'notify-send failed' env NOTIFY_SEND_EXIT=1 sh "$script" --message hello

expect_failure 'notify-send is unavailable' env NOTIFY_SEND_BIN=missing-notify-send sh "$script" --message hello

printf 'task-completion-notifier tests passed\n'
