#!/usr/bin/env python3
"""Manage the notifier's small, repository-local session state."""

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path


STATE_FILE = "sessions.json"


def emit(payload, status=0):
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return status


def fail(message, session_id=None):
    payload = {"ok": False, "error": message}
    if session_id is not None:
        payload["session_id"] = session_id
    return emit(payload, 1)


def read_state(path):
    if not path.exists():
        return {"version": 1, "sessions": {}}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read state: {exc}") from exc
    if not isinstance(value, dict) or not isinstance(value.get("sessions", {}), dict):
        raise ValueError("state file has an invalid format")
    return {"version": 1, "sessions": value["sessions"]}


def write_state(path, state):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(state, stream, ensure_ascii=False, sort_keys=True)
            stream.write("\n")
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("activate", "deactivate", "status"))
    parser.add_argument("session_id", nargs="?")
    parser.add_argument("--state-dir", required=True)
    parser.add_argument("--session-id", dest="named_session_id")
    # Accept the session ID before or after options, which is convenient for
    # shell callers that append a positional ID.
    args = parser.parse_intermixed_args()
    session_id = args.named_session_id or args.session_id
    if not session_id:
        return fail("session ID is required")
    if args.named_session_id and args.session_id and args.named_session_id != args.session_id:
        return fail("session ID specified more than once")

    state_path = Path(args.state_dir) / STATE_FILE
    try:
        state = read_state(state_path)
        active = session_id in state["sessions"] and bool(state["sessions"][session_id].get("active"))
        if args.action == "activate":
            state["sessions"][session_id] = {"active": True}
            write_state(state_path, state)
            active = True
        elif args.action == "deactivate":
            state["sessions"].pop(session_id, None)
            write_state(state_path, state)
            active = False
    except (OSError, ValueError) as exc:
        return fail(str(exc), session_id)

    return emit({"ok": True, "action": args.action, "active": active, "session_id": session_id})


if __name__ == "__main__":
    sys.exit(main())
