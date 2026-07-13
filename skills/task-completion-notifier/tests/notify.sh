#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$skill_root/scripts/notify.py"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin"

cat >"$tmpdir/bin/notify-send" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" >"$NOTIFY_CAPTURE"
EOF
cat >"$tmpdir/bin/osascript" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" >"$NOTIFY_CAPTURE"
EOF
cat >"$tmpdir/bin/powershell" <<'EOF'
#!/usr/bin/env sh
printf '%s\n%s\n' "$TCN_TITLE" "$TCN_MESSAGE" >"$NOTIFY_CAPTURE"
EOF
chmod +x "$tmpdir/bin/notify-send" "$tmpdir/bin/osascript" "$tmpdir/bin/powershell"

expect_failure() {
  local expected=$1
  shift
  if output=$("$@" 2>&1); then
    printf 'Expected command to fail: %s\n' "$*" >&2
    exit 1
  fi
  [[ "$output" == *"$expected"* ]] || {
    printf 'Expected error containing %q, got: %s\n' "$expected" "$output" >&2
    exit 1
  }
}

linux_env=(env NOTIFIER_PLATFORM=Linux NOTIFY_SEND_BIN="$tmpdir/bin/notify-send" DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS=test NOTIFY_CAPTURE="$tmpdir/capture")
"${linux_env[@]}" python3 "$script" --message 'Task finished' --title Done --urgency low --timeout-ms 5000 --app-name Tests
mapfile -t capture <"$tmpdir/capture"
[[ "${capture[*]}" == '--app-name Tests --urgency low --expire-time 5000 -- Done Task finished' ]]

"${linux_env[@]}" python3 "$script" --message 'token sk_abcdefghijklmnopqrstuvwxyz0123456789 at /home/alice/private' --title Done
grep -Fq '[redacted-secret]' "$tmpdir/capture"
grep -Fq '[redacted-path]' "$tmpdir/capture"
! grep -Fq 'abcdefghijklmnopqrstuvwxyz' "$tmpdir/capture"

env NOTIFIER_PLATFORM=Darwin OSASCRIPT_BIN="$tmpdir/bin/osascript" NOTIFY_CAPTURE="$tmpdir/capture" python3 "$script" --message 'Mac complete' --title Done --sound
grep -Fq 'display notification "Mac complete" with title "Done" sound name "Glass"' "$tmpdir/capture"

env NOTIFIER_PLATFORM=Windows POWERSHELL_BIN="$tmpdir/bin/powershell" NOTIFY_CAPTURE="$tmpdir/capture" python3 "$script" --message 'Windows complete' --title Done
grep -Fxq 'Done' "$tmpdir/capture"
grep -Fxq 'Windows complete' "$tmpdir/capture"

"${linux_env[@]}" python3 "$script" --message check --check
expect_failure 'no graphical session' env NOTIFIER_PLATFORM=Linux NOTIFY_SEND_BIN="$tmpdir/bin/notify-send" DISPLAY= WAYLAND_DISPLAY= python3 "$script" --message hello
expect_failure 'notify-send is unavailable' env NOTIFIER_PLATFORM=Linux NOTIFY_SEND_BIN=missing-notify-send DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS=test python3 "$script" --message hello
expect_failure 'unsupported platform' env NOTIFIER_PLATFORM=Plan9 python3 "$script" --message hello
expect_failure 'required' python3 "$script"

printf 'task-completion-notifier notification tests passed\n'
