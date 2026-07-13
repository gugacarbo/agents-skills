#!/usr/bin/env python3
"""Deliver a single armed completion from a lifecycle hook."""

import argparse
import json
import subprocess
import sys
from pathlib import Path


EXPECTED_EVENTS = {
    "cursor": "stop",
    "github-copilot": "agentStop",
    "opencode": "session.idle",
}


def emit(payload, status, as_json):
    if as_json:
        print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    elif not payload["ok"]:
        print(payload["error"], file=sys.stderr)
    return status


def hook_session_id(explicit):
    if explicit:
        return explicit
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        payload = {}
    if not isinstance(payload, dict):
        return None
    value = (
        payload.get("sessionId")
        or payload.get("session_id")
        or payload.get("conversation_id")
        or payload.get("sessionID")
    )
    if not value and isinstance(payload.get("properties"), dict):
        value = payload["properties"].get("sessionID") or payload["properties"].get("session_id")
    return str(value) if value else None


def state_command(action, args, *extra):
    tool = Path(__file__).with_name("session-state.py")
    return [sys.executable, str(tool), action, "--repo-root", args.repo_root, "--agent", args.agent, *extra]


def run_state(action, args, *extra):
    completed = subprocess.run(state_command(action, args, *extra), check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        raise ValueError(completed.stderr.strip() or completed.stdout.strip() or f"cannot {action} completion")
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise ValueError("state tool returned invalid JSON") from exc


def notifier_command(notifier, claim):
    path = Path(notifier)
    if path.suffix == ".py":
        command = [sys.executable, str(path), "--message", claim["message"]]
    else:
        command = ["sh", str(path), "--message", claim["message"]]
    if claim.get("title"):
        command.extend(["--title", claim["title"]])
    return command


def release_after_error(args, token):
    try:
        run_state("release", args, "--token", token)
        return None
    except ValueError as exc:
        return str(exc)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--agent", required=True)
    parser.add_argument("--event", required=True)
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--notifier", required=True)
    parser.add_argument("--session-id")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    session_id = hook_session_id(args.session_id)
    base = {"agent": args.agent, "event": args.event, "session_id": session_id}
    expected_event = EXPECTED_EVENTS.get(args.agent)
    if expected_event is None:
        return emit({**base, "ok": False, "error": f"unsupported agent: {args.agent}"}, 2, args.json)
    if args.event != expected_event:
        return emit({**base, "ok": False, "error": f"unexpected event for {args.agent}: {args.event}"}, 2, args.json)
    if not session_id:
        return emit({**base, "ok": True, "noop": True, "reason": "missing_session_id"}, 0, args.json)
    try:
        claim = run_state("claim", args, "--session-id", session_id)
    except ValueError as exc:
        return emit({**base, "ok": False, "error": str(exc)}, 1, args.json)
    if not claim.get("claimed"):
        return emit({**base, "ok": True, "noop": True}, 0, args.json)

    command = notifier_command(args.notifier, claim)
    try:
        completed = subprocess.run(command, check=False, capture_output=True, text=True)
    except OSError as exc:
        release_error = release_after_error(args, claim["token"])
        error = str(exc) if not release_error else f"{exc}; completion could not be re-armed: {release_error}"
        return emit({**base, "ok": False, "error": error}, 1, args.json)
    if completed.returncode == 0:
        try:
            run_state("ack", args, "--token", claim["token"])
        except ValueError as exc:
            error = "notification was delivered but its acknowledgment failed; a later retry may duplicate it"
            return emit({**base, "ok": False, "notified": True, "error": f"{error}: {exc}"}, 1, args.json)
        return emit({**base, "ok": True, "notified": True}, 0, args.json)
    release_error = release_after_error(args, claim["token"])
    if release_error:
        error = f"notification failed and could not be re-armed: {release_error}"
        return emit({**base, "ok": False, "error": error}, 1, args.json)
    error = completed.stderr.strip() or f"notifier exited with status {completed.returncode}"
    return emit({**base, "ok": False, "error": error}, 1, args.json)


if __name__ == "__main__":
    sys.exit(main())
