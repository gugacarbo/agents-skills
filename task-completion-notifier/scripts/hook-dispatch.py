#!/usr/bin/env python3
"""Dispatch a hook event to the notifier when its session is active."""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def output(payload, status=0):
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return status


def session_is_active(state_dir, session_id):
    path = Path(state_dir) / "sessions.json"
    if not path.exists():
        return False
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
        return bool(state.get("sessions", {}).get(session_id, {}).get("active"))
    except (OSError, json.JSONDecodeError, AttributeError):
        raise ValueError("state file has an invalid format")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--agent", required=True)
    parser.add_argument("--event", required=True)
    parser.add_argument("--state-dir", required=True)
    parser.add_argument("--notifier", required=True)
    parser.add_argument("--session-id", default="default")
    args = parser.parse_args()

    base = {"agent": args.agent, "event": args.event, "session_id": args.session_id}
    try:
        active = session_is_active(args.state_dir, args.session_id)
    except ValueError as exc:
        return output({**base, "ok": False, "blocking": True, "error": str(exc)}, 1)
    if not active:
        return output({**base, "active": False, "noop": True, "ok": True})

    message = f"{args.agent}: {args.event} completed"
    try:
        completed = subprocess.run(
            [args.notifier, "--message", message],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return output({**base, "active": True, "blocking": True, "error": str(exc), "ok": False}, 1)
    if completed.returncode != 0:
        error = completed.stderr.strip() or f"notifier exited with status {completed.returncode}"
        return output({**base, "active": True, "blocking": True, "error": error, "ok": False}, 1)
    return output({**base, "active": True, "notified": True, "ok": True})


if __name__ == "__main__":
    sys.exit(main())
