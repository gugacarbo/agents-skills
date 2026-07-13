#!/usr/bin/env python3
"""Send a concise desktop notification on Linux, macOS, or Windows."""

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys


DEFAULT_TITLE = "Task complete"
MAX_TITLE_LENGTH = 80
MAX_MESSAGE_LENGTH = 240
TOKEN_PATTERNS = (
    r"\b(?:sk|rk|pk)_[A-Za-z0-9_-]{16,}\b",
    r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b",
    r"\bAIza[A-Za-z0-9_-]{20,}\b",
    r"\bBearer\s+[A-Za-z0-9._~+/-]{16,}\b",
)
PRIVATE_PATH_PATTERNS = (
    r"(?<!\w)/(?:home|Users)/[^\s:]+",
    r"\b[A-Za-z]:\\Users\\[^\s:]+",
)


def fail(message):
    print(f"Error: {message}", file=sys.stderr)
    return 1


def compact(value, limit):
    value = re.sub(r"\s+", " ", value).strip()
    if len(value) <= limit:
        return value
    return value[: max(0, limit - 1)].rstrip() + "…"


def redact(value):
    for pattern in TOKEN_PATTERNS:
        value = re.sub(pattern, "[redacted-secret]", value, flags=re.IGNORECASE)
    for pattern in PRIVATE_PATH_PATTERNS:
        value = re.sub(pattern, "[redacted-path]", value)
    return value


def prepare(value, limit):
    return compact(redact(value), limit)


def command(binary, fallback=None):
    configured = os.environ.get(binary)
    if configured:
        return configured
    return shutil.which(fallback or binary.lower().replace("_BIN", ""))


def notify_linux(title, message, args):
    binary = command("NOTIFY_SEND_BIN", "notify-send")
    if not binary:
        return fail("notify-send is unavailable; install a libnotify implementation")
    if not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY"):
        return fail("no graphical session is available")
    if not os.environ.get("DBUS_SESSION_BUS_ADDRESS"):
        return fail("no D-Bus session is available")
    urgency = args.urgency
    invocation = [binary, "--app-name", args.app_name, "--urgency", urgency, "--expire-time", str(args.timeout_ms)]
    if args.icon:
        invocation.extend(["--icon", args.icon])
    invocation.extend(["--", title, message])
    try:
        completed = subprocess.run(invocation, check=False, capture_output=True, text=True)
    except OSError:
        return fail("notify-send is unavailable; install a libnotify implementation")
    if completed.returncode:
        return fail(completed.stderr.strip() or "notify-send failed to deliver the notification")
    return 0


def applescript_string(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def notify_macos(title, message, args):
    binary = command("OSASCRIPT_BIN", "osascript")
    if not binary:
        return fail("osascript is unavailable")
    script = f'display notification "{applescript_string(message)}" with title "{applescript_string(title)}"'
    if args.sound:
        script += ' sound name "Glass"'
    try:
        completed = subprocess.run([binary, "-e", script], check=False, capture_output=True, text=True)
    except OSError:
        return fail("osascript is unavailable")
    if completed.returncode:
        return fail(completed.stderr.strip() or "osascript failed to deliver the notification")
    return 0


def notify_windows(title, message, args):
    binary = command("POWERSHELL_BIN", "powershell") or command("PWSH_BIN", "pwsh")
    if not binary:
        return fail("PowerShell is unavailable")
    script = r'''
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($template)
$nodes = $xml.GetElementsByTagName("text")
$nodes.Item(0).AppendChild($xml.CreateTextNode($env:TCN_TITLE)) | Out-Null
$nodes.Item(1).AppendChild($xml.CreateTextNode($env:TCN_MESSAGE)) | Out-Null
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($env:TCN_APP_NAME).Show($toast)
'''
    environment = dict(os.environ, TCN_TITLE=title, TCN_MESSAGE=message, TCN_APP_NAME=args.app_name)
    try:
        completed = subprocess.run([binary, "-NoProfile", "-NonInteractive", "-Command", script], check=False, capture_output=True, text=True, env=environment)
    except OSError:
        return fail("PowerShell is unavailable")
    if completed.returncode:
        return fail(completed.stderr.strip() or "PowerShell failed to deliver the notification")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Send a desktop completion notification.")
    parser.add_argument("--message", required=True)
    parser.add_argument("--title", default=DEFAULT_TITLE)
    parser.add_argument("--urgency", choices=("low", "normal", "critical"), default="normal")
    parser.add_argument("--timeout-ms", type=int, default=8000)
    parser.add_argument("--app-name", default="Task Completion Notifier")
    parser.add_argument("--icon")
    parser.add_argument("--sound", action="store_true", help="play the default macOS notification sound")
    parser.add_argument("--check", action="store_true", help="validate that the current platform has a notifier")
    args = parser.parse_args()
    if args.timeout_ms <= 0:
        return fail("--timeout-ms must be positive")
    title = prepare(args.title, MAX_TITLE_LENGTH)
    message = prepare(args.message, MAX_MESSAGE_LENGTH)
    if not title or not message:
        return fail("--title and --message must not be empty")
    current = os.environ.get("NOTIFIER_PLATFORM") or platform.system()
    if args.check:
        if current == "Linux":
            return 0 if command("NOTIFY_SEND_BIN", "notify-send") else fail("notify-send is unavailable; install a libnotify implementation")
        if current == "Darwin":
            return 0 if command("OSASCRIPT_BIN", "osascript") else fail("osascript is unavailable")
        if current == "Windows":
            return 0 if command("POWERSHELL_BIN", "powershell") or command("PWSH_BIN", "pwsh") else fail("PowerShell is unavailable")
        return fail(f"unsupported platform: {current}")
    if current == "Linux":
        return notify_linux(title, message, args)
    if current == "Darwin":
        return notify_macos(title, message, args)
    if current == "Windows":
        return notify_windows(title, message, args)
    return fail(f"unsupported platform: {current}")


if __name__ == "__main__":
    sys.exit(main())
