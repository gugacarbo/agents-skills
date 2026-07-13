#!/usr/bin/env python3
"""Manage durable, queued completion deliveries for lifecycle hooks."""

import argparse
import fcntl
import hashlib
import json
import os
import sys
import tempfile
import time
import uuid
from contextlib import contextmanager
from pathlib import Path


STATE_FILE = "sessions.json"
SCHEMA_VERSION = 3
DEFAULT_TTL_SECONDS = 3600
CLAIM_LEASE_SECONDS = 60


def emit(payload, status=0):
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return status


def fail(message, session_id=None):
    payload = {"ok": False, "error": message}
    if session_id is not None:
        payload["session_id"] = session_id
    return emit(payload, 1)


def default_state_dir(repo_root):
    base = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    fingerprint = hashlib.sha256(str(Path(repo_root).resolve()).encode()).hexdigest()[:16]
    return base / "task-completion-notifier" / fingerprint


def session_key(agent, session_id):
    if not agent or not session_id:
        raise ValueError("agent and session ID are required")
    return f"{agent}:{session_id}"


def empty_state():
    return {"version": SCHEMA_VERSION, "sessions": {}, "deliveries": {}}


def validate_record(record, delivery=False):
    required = {"delivery_id", "message", "expires_at"}
    if delivery:
        required.update({"claim_deadline", "session_key"})
    if not isinstance(record, dict) or not required.issubset(record):
        raise ValueError("state file has an invalid format")
    if not isinstance(record["delivery_id"], str) or not isinstance(record["message"], str):
        raise ValueError("state file has an invalid format")
    if not isinstance(record["expires_at"], (int, float)):
        raise ValueError("state file has an invalid format")
    if record.get("title") is not None and not isinstance(record["title"], str):
        raise ValueError("state file has an invalid format")
    if delivery and (
        not isinstance(record["claim_deadline"], (int, float))
        or not isinstance(record["session_key"], str)
    ):
        raise ValueError("state file has an invalid format")


def migrate_v2(value):
    sessions = {}
    for key, record in value["sessions"].items():
        if not isinstance(record, dict):
            raise ValueError("state file has an invalid format")
        upgraded = dict(record)
        upgraded["delivery_id"] = upgraded.get("delivery_id") or uuid.uuid4().hex
        sessions[key] = [upgraded]
    deliveries = {}
    for token, record in value["deliveries"].items():
        if not isinstance(record, dict):
            raise ValueError("state file has an invalid format")
        upgraded = dict(record)
        upgraded["delivery_id"] = upgraded.get("delivery_id") or uuid.uuid4().hex
        deliveries[token] = upgraded
    return {"version": SCHEMA_VERSION, "sessions": sessions, "deliveries": deliveries}


def read_state(path):
    if not path.exists():
        return empty_state(), False
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read state: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError("state file has an invalid format")
    migrated = value.get("version") == 2
    if migrated:
        if not isinstance(value.get("sessions"), dict) or not isinstance(value.get("deliveries"), dict):
            raise ValueError("state file has an invalid format")
        value = migrate_v2(value)
    if (
        value.get("version") != SCHEMA_VERSION
        or not isinstance(value.get("sessions"), dict)
        or not isinstance(value.get("deliveries"), dict)
    ):
        raise ValueError("state file has an invalid format")
    for queue in value["sessions"].values():
        if not isinstance(queue, list):
            raise ValueError("state file has an invalid format")
        for record in queue:
            validate_record(record)
    for record in value["deliveries"].values():
        validate_record(record, delivery=True)
    return value, migrated


def secure_directory(path):
    path.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(path, 0o700)
    except OSError:
        # Windows does not implement POSIX mode bits consistently.
        pass


def write_state(path, state):
    secure_directory(path.parent)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            try:
                os.fchmod(stream.fileno(), 0o600)
            except OSError:
                pass
            json.dump(state, stream, ensure_ascii=False, sort_keys=True)
            stream.write("\n")
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


@contextmanager
def locked_state(path):
    secure_directory(path.parent)
    lock_path = path.with_suffix(".lock")
    with lock_path.open("a+", encoding="utf-8") as lock:
        try:
            os.chmod(lock_path, 0o600)
        except OSError:
            pass
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        try:
            yield read_state(path)
        finally:
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def remove_expired(state, now):
    changed = False
    for key, queue in list(state["sessions"].items()):
        active = [record for record in queue if record["expires_at"] > now]
        if len(active) != len(queue):
            changed = True
        if active:
            state["sessions"][key] = active
        else:
            state["sessions"].pop(key, None)
    return changed


def recover_expired_claims(state, now):
    recovered = False
    for token, delivery in list(state["deliveries"].items()):
        if delivery["claim_deadline"] > now:
            continue
        state["deliveries"].pop(token)
        key = delivery.pop("session_key")
        delivery.pop("claim_deadline", None)
        if delivery["expires_at"] > now:
            queue = state["sessions"].setdefault(key, [])
            if not any(item["delivery_id"] == delivery["delivery_id"] for item in queue):
                queue.insert(0, delivery)
        recovered = True
    return recovered


def has_delivery_id(state, delivery_id):
    return any(
        record["delivery_id"] == delivery_id
        for queue in state["sessions"].values()
        for record in queue
    ) or any(record["delivery_id"] == delivery_id for record in state["deliveries"].values())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("arm", "claim", "ack", "release", "deactivate", "status", "gc"))
    parser.add_argument("session_id", nargs="?")
    parser.add_argument("--state-dir")
    parser.add_argument("--repo-root")
    parser.add_argument("--agent")
    parser.add_argument("--session-id", dest="named_session_id")
    parser.add_argument("--message")
    parser.add_argument("--title")
    parser.add_argument("--token")
    parser.add_argument("--delivery-id")
    parser.add_argument("--ttl-seconds", type=int, default=DEFAULT_TTL_SECONDS)
    args = parser.parse_intermixed_args()

    if bool(args.state_dir) == bool(args.repo_root):
        return fail("provide exactly one of --state-dir or --repo-root")
    if args.named_session_id and args.session_id and args.named_session_id != args.session_id:
        return fail("session ID specified more than once")
    session_id = args.named_session_id or args.session_id
    session_actions = {"arm", "claim", "deactivate", "status"}
    if args.action in session_actions and not session_id:
        return fail("session ID is required")
    if args.action in session_actions and not args.agent:
        return fail("--agent is required", session_id)
    if args.action in {"ack", "release"} and not args.token:
        return fail("--token is required")
    if args.action == "arm" and (not args.message or args.ttl_seconds <= 0):
        return fail("--message and a positive --ttl-seconds are required when arming a completion", session_id)

    state_path = Path(args.state_dir) / STATE_FILE if args.state_dir else default_state_dir(args.repo_root) / STATE_FILE
    now = time.time()
    try:
        with locked_state(state_path) as (state, migrated):
            changed = migrated or remove_expired(state, now) or recover_expired_claims(state, now)
            key = session_key(args.agent, session_id) if session_id else None
            if args.action == "gc":
                if changed:
                    write_state(state_path, state)
                return emit({"ok": True, "action": "gc", "changed": changed})
            if args.action == "arm":
                delivery_id = args.delivery_id or uuid.uuid4().hex
                if has_delivery_id(state, delivery_id):
                    if changed:
                        write_state(state_path, state)
                    return emit({"ok": True, "action": "arm", "active": True, "armed": False, "delivery_id": delivery_id, "session_id": session_id})
                state["sessions"].setdefault(key, []).append({
                    "delivery_id": delivery_id,
                    "message": args.message,
                    "title": args.title,
                    "expires_at": now + args.ttl_seconds,
                })
                write_state(state_path, state)
                return emit({"ok": True, "action": "arm", "active": True, "armed": True, "delivery_id": delivery_id, "session_id": session_id})
            if args.action == "claim":
                queue = state["sessions"].get(key, [])
                if not queue:
                    if changed:
                        write_state(state_path, state)
                    return emit({"ok": True, "action": "claim", "claimed": False, "session_id": session_id})
                pending = queue.pop(0)
                if not queue:
                    state["sessions"].pop(key, None)
                token = uuid.uuid4().hex
                pending["session_key"] = key
                pending["claim_deadline"] = now + CLAIM_LEASE_SECONDS
                state["deliveries"][token] = pending
                write_state(state_path, state)
                return emit({"ok": True, "action": "claim", "claimed": True, "token": token, "delivery_id": pending["delivery_id"], "message": pending["message"], "title": pending.get("title"), "session_id": session_id})
            if args.action == "ack":
                removed = state["deliveries"].pop(args.token, None)
                if removed is not None or changed:
                    write_state(state_path, state)
                return emit({"ok": True, "action": "ack", "acknowledged": removed is not None, "delivery_id": removed.get("delivery_id") if removed else None})
            if args.action == "release":
                delivery = state["deliveries"].pop(args.token, None)
                released = False
                if delivery is not None and delivery["expires_at"] > now:
                    delivery_key = delivery.pop("session_key")
                    delivery.pop("claim_deadline", None)
                    queue = state["sessions"].setdefault(delivery_key, [])
                    if not any(item["delivery_id"] == delivery["delivery_id"] for item in queue):
                        queue.insert(0, delivery)
                        released = True
                if delivery is not None or changed:
                    write_state(state_path, state)
                return emit({"ok": True, "action": "release", "released": released, "delivery_id": delivery.get("delivery_id") if delivery else None})
            if args.action == "deactivate":
                queue = state["sessions"].get(key, [])
                if args.delivery_id:
                    kept = [record for record in queue if record["delivery_id"] != args.delivery_id]
                    removed = len(kept) != len(queue)
                    if kept:
                        state["sessions"][key] = kept
                    else:
                        state["sessions"].pop(key, None)
                else:
                    removed = bool(state["sessions"].pop(key, None))
                if removed or changed:
                    write_state(state_path, state)
                return emit({"ok": True, "action": "deactivate", "active": False, "removed": removed, "session_id": session_id})
            queue = state["sessions"].get(key, [])
            if changed:
                write_state(state_path, state)
            return emit({"ok": True, "action": "status", "active": bool(queue), "pending_count": len(queue), "session_id": session_id})
    except (OSError, ValueError) as exc:
        return fail(str(exc), session_id)


if __name__ == "__main__":
    sys.exit(main())
