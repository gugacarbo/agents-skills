#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
export NOTIFIER_SOURCE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

SOURCE = Path(os.environ["NOTIFIER_SOURCE_ROOT"])
TARGETS = {"codex", "copilot", "opencode", "cursor"}
RUNTIME = [
    "scripts/notify.sh",
    "scripts/session-state.py",
    "scripts/hook-dispatch.py",
    "scripts/adapters/ubuntu.sh",
]


def die(message):
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        die(f"invalid JSON in {path}: {exc}")


def save_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def render(source, destination, root):
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        source.read_text(encoding="utf-8").replace("__RUNTIME_ROOT__", str(root)),
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser(description="Preview or install task-completion-notifier hooks.")
    parser.add_argument("--repo", required=True)
    parser.add_argument("--targets", required=True)
    parser.add_argument("--approve-merge", action="store_true")
    args = parser.parse_args()

    requested = []
    for raw in args.targets.split(","):
        name = raw.strip().lower()
        if not name:
            continue
        if name not in TARGETS:
            die(f"unknown target: {name}")
        if name not in requested:
            requested.append(name)
    if not requested:
        die("--targets must select at least one integration")

    try:
        root = Path(subprocess.check_output(
            ["git", "-C", args.repo, "rev-parse", "--show-toplevel"], text=True, stderr=subprocess.DEVNULL
        ).strip())
    except subprocess.CalledProcessError:
        die(f"--repo must be inside a Git repository: {args.repo}")

    runtime_root = root / ".task-completion-notifier"
    conflicts = []
    unsafe = []
    for relative in RUNTIME:
        destination = runtime_root / relative
        if destination.exists() and destination.read_bytes() != (SOURCE / relative).read_bytes():
            conflicts.append(destination)
            unsafe.append(destination)

    destinations = {
        "codex": root / "plugins/task-completion-notifier",
        "copilot": root / ".github/hooks/task-completion-notifier.json",
        "opencode": root / ".opencode/plugins/task-completion-notifier.ts",
        "cursor": root / ".cursor/hooks.json",
    }
    for name in requested:
        path = destinations[name]
        if path.exists():
            conflicts.append(path)
            if name not in {"cursor"}:
                unsafe.append(path)
    marketplace = root / ".agents/plugins/marketplace.json"
    if "codex" in requested and marketplace.exists():
        conflicts.append(marketplace)

    print(f"Repository: {root}")
    print(f"Targets: {', '.join(requested)}")
    print(f"Runtime: {runtime_root}")
    for name in requested:
        print(f"Would install: {destinations[name]}")
    if conflicts:
        print("Existing configuration requires merge approval:", file=sys.stderr)
        for path in conflicts:
            print(f"- {path}", file=sys.stderr)
        if not args.approve_merge:
            print("Re-run with --approve-merge only after explicit user approval.", file=sys.stderr)
            return 1
    if not args.approve_merge:
        print("Preview only. Re-run with --approve-merge to install.")
        return 0
    if unsafe:
        die("refusing unsafe overwrite; resolve the listed generated file or divergent runtime manually")

    for relative in RUNTIME:
        source = SOURCE / relative
        destination = runtime_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if not destination.exists():
            shutil.copy2(source, destination)

    if "codex" in requested:
        source = SOURCE / "templates/codex-local"
        destination = destinations["codex"]
        for item in source.rglob("*"):
            if item.is_file():
                render(item, destination / item.relative_to(source), root)
        entry = {
            "name": "task-completion-notifier",
            "source": {"source": "local", "path": "./plugins/task-completion-notifier"},
            "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
            "category": "Productivity",
        }
        data = load_json(marketplace) if marketplace.exists() else {
            "name": "repository", "interface": {"displayName": "Repository plugins"}, "plugins": []
        }
        if not isinstance(data, dict) or not isinstance(data.get("plugins"), list):
            die(f"unsupported marketplace shape: {marketplace}")
        existing = [item for item in data["plugins"] if isinstance(item, dict) and item.get("name") == entry["name"]]
        if existing and existing[0] != entry:
            die(f"marketplace already has a different notifier entry: {marketplace}")
        if not existing:
            data["plugins"].append(entry)
            save_json(marketplace, data)

    simple = {
        "copilot": (SOURCE / "templates/github-copilot/.github/hooks/task-completion-notifier.json", destinations["copilot"]),
        "opencode": (SOURCE / "templates/opencode/.opencode/plugins/task-completion-notifier.ts", destinations["opencode"]),
    }
    for name, (source, destination) in simple.items():
        if name in requested:
            render(source, destination, root)

    if "cursor" in requested:
        source = SOURCE / "templates/cursor/.cursor/hooks.json"
        destination = destinations["cursor"]
        if not destination.exists():
            render(source, destination, root)
        else:
            data = load_json(destination)
            desired = load_json(source)["hooks"]["stop"][0]
            desired["command"] = desired["command"].replace("__RUNTIME_ROOT__", str(root))
            if not isinstance(data, dict) or not isinstance(data.get("hooks"), dict):
                die(f"unsupported Cursor hooks shape: {destination}")
            stop = data["hooks"].setdefault("stop", [])
            if not isinstance(stop, list):
                die(f"Cursor stop hooks must be a list: {destination}")
            if desired not in stop:
                stop.append(desired)
                save_json(destination, data)

    print("Installed task-completion-notifier hooks.")


raise SystemExit(main() or 0)
PY
