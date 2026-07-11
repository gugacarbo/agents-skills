#!/usr/bin/env sh

ubuntu_fail() {
  printf '%s\n' "Error: $*" >&2
  return 1
}

notify_ubuntu() {
  title=$1
  message=$2
  os_release_file=${NOTIFY_OS_RELEASE_FILE:-/etc/os-release}
  notify_send_bin=${NOTIFY_SEND_BIN:-notify-send}

  [ -r "$os_release_file" ] || ubuntu_fail "cannot read $os_release_file to identify Ubuntu"
  os_id=$(sed -n 's/^ID=//p' "$os_release_file" | head -n 1 | tr -d '"')
  [ "$os_id" = 'ubuntu' ] || ubuntu_fail 'unsupported Linux distribution; v1 supports Ubuntu desktop only'

  command -v "$notify_send_bin" >/dev/null 2>&1 || ubuntu_fail 'notify-send is unavailable; install libnotify-bin'
  [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || ubuntu_fail 'no graphical session is available'
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || ubuntu_fail 'no D-Bus session is available'

  "$notify_send_bin" -- "$title" "$message" || ubuntu_fail 'notify-send failed to deliver the notification'
}
