#!/usr/bin/env python3
"""Install, update, diagnose, and remove task-completion-notifier integrations."""

import argparse
import hashlib
import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


SOURCE = Path(__file__).resolve().parents[1]
VERSION = (SOURCE / "VERSION").read_text(encoding="utf-8").strip()
TARGETS = {"codex", "copilot", "opencode", "cursor"}
RUNTIME = (
    "scripts/notify.py",
    "scripts/notify.sh",
    "scripts/session-state.py",
    "scripts/hook-dispatch.py",
)
MANIFEST_NAME = "manifest.json"


def die(message):
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(1)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def repository_root(repo):
    try:
        return Path(subprocess.check_output(["git", "-C", repo, "rev-parse", "--show-toplevel"], text=True, stderr=subprocess.DEVNULL).strip())
    except subprocess.CalledProcessError:
        die(f"--repo must be inside a Git repository: {repo}")


def state_fingerprint(root):
    return hashlib.sha256(str(root.resolve()).encode()).hexdigest()[:16]


def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        die(f"invalid JSON in {path}: {exc}")


def save_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def load_manifest(path):
    if not path.exists():
        return None
    value = load_json(path)
    if not isinstance(value, dict) or value.get("schema") != 1 or not isinstance(value.get("files"), dict):
        die(f"invalid managed-install manifest: {path}")
    return value


def ps_quote(value):
    return "'" + str(value).replace("'", "''") + "'"


def replacements(root, runtime_root):
    runtime = runtime_root / "scripts"
    return {
        "__DISPATCH_SH__": shlex.quote(str(runtime / "hook-dispatch.py")),
        "__NOTIFIER_SH__": shlex.quote(str(runtime / "notify.sh")),
        "__NOTIFIER_PY_SH__": shlex.quote(str(runtime / "notify.py")),
        "__REPO_ROOT_SH__": shlex.quote(str(root)),
        "__DISPATCH_JSON__": json.dumps(str(runtime / "hook-dispatch.py")),
        "__NOTIFIER_JSON__": json.dumps(str(runtime / "notify.py")),
        "__REPO_ROOT_JSON__": json.dumps(str(root)),
        "__DISPATCH_PS__": ps_quote(runtime / "hook-dispatch.py"),
        "__NOTIFIER_PS__": ps_quote(runtime / "notify.py"),
        "__REPO_ROOT_PS__": ps_quote(root),
    }


def rendered_text(source, root, runtime_root):
    value = source.read_text(encoding="utf-8")
    for placeholder, replacement in replacements(root, runtime_root).items():
        value = value.replace(placeholder, replacement)
    return value


def rendered_destination(source, template_root, destination_root):
    relative = source.relative_to(template_root)
    if relative.name == "SKILL.md.template":
        relative = relative.with_name("SKILL.md")
    return destination_root / relative


def render_tree(template_root, destination_root, root, runtime_root):
    for source in template_root.rglob("*"):
        if source.is_file():
            destination = rendered_destination(source, template_root, destination_root)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(rendered_text(source, root, runtime_root), encoding="utf-8")


def rendered_tree_matches(template_root, destination_root, root, runtime_root):
    return destination_root.is_dir() and all(
        destination.is_file() and destination.read_text(encoding="utf-8") == rendered_text(source, root, runtime_root)
        for source in template_root.rglob("*")
        if source.is_file()
        for destination in (rendered_destination(source, template_root, destination_root),)
    )


def rendered_file_matches(template, destination, root, runtime_root):
    return destination.is_file() and destination.read_text(encoding="utf-8") == rendered_text(template, root, runtime_root)


def hook_entry(template, root, runtime_root, event):
    value = load_json(template)
    try:
        entry = value["hooks"][event][0]
    except (KeyError, IndexError, TypeError):
        die(f"invalid hook template: {template}")
    rendered = json.loads(json.dumps(entry))
    for key, item in rendered.items():
        if isinstance(item, str):
            for placeholder, replacement in replacements(root, runtime_root).items():
                item = item.replace(placeholder, replacement)
            rendered[key] = item
    return rendered


def managed_hook(entry, agent):
    return isinstance(entry, dict) and any(
        isinstance(value, str) and "hook-dispatch.py" in value and f"--agent {agent}" in value
        for value in entry.values()
    )


def upsert_hook(path, template, event, field, agent, root, runtime_root):
    data = load_json(path) if path.exists() else {"version": 1, "hooks": {}}
    if not isinstance(data, dict) or not isinstance(data.get("hooks"), dict):
        die(f"unsupported hooks shape: {path}")
    entries = data["hooks"].setdefault(event, [])
    if not isinstance(entries, list):
        die(f"hook event must be a list: {path} ({event})")
    data["hooks"][event] = [entry for entry in entries if not managed_hook(entry, agent)]
    desired = hook_entry(template, root, runtime_root, event)
    if not isinstance(desired.get(field), str):
        die(f"invalid notifier template: {template}")
    data["hooks"][event].append(desired)
    return data


def remove_hook(path, event, agent):
    if not path.exists():
        return False
    data = load_json(path)
    if not isinstance(data, dict) or not isinstance(data.get("hooks"), dict):
        die(f"unsupported hooks shape: {path}")
    entries = data["hooks"].get(event)
    if not isinstance(entries, list):
        return False
    kept = [entry for entry in entries if not managed_hook(entry, agent)]
    if len(kept) == len(entries):
        return False
    if kept:
        data["hooks"][event] = kept
    else:
        data["hooks"].pop(event, None)
    save_json(path, data)
    return True


def managed_matches(path, relative, manifest):
    return bool(manifest and path.is_file() and manifest["files"].get(relative) == sha256(path))


def record_file(files, root, path):
    if path.is_file():
        files[str(path.relative_to(root))] = sha256(path)


def parse_args():
    parser = argparse.ArgumentParser(description="Manage task-completion-notifier integrations.")
    parser.add_argument("--repo", required=True)
    parser.add_argument("--targets", required=True, help="comma-separated: codex,copilot,opencode,cursor")
    parser.add_argument("--scope", choices=("repo", "user"), default="repo")
    parser.add_argument("--apply", action="store_true", help="apply the displayed change")
    parser.add_argument("--approve-merge", action="store_true", help="legacy alias for --apply after explicit approval")
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--update", action="store_true")
    action.add_argument("--uninstall", action="store_true")
    action.add_argument("--doctor", action="store_true")
    parser.add_argument("--purge-state", action="store_true", help="remove this repository's local pending delivery state during uninstall")
    args = parser.parse_args()
    args.apply = args.apply or args.approve_merge
    args.action = "doctor" if args.doctor else "uninstall" if args.uninstall else "update" if args.update else "install"
    requested = []
    for raw in args.targets.split(","):
        name = raw.strip().lower()
        if not name or name not in TARGETS:
            die(f"unknown target: {name}")
        if name not in requested:
            requested.append(name)
    args.targets = requested
    if args.scope == "user" and set(args.targets) != {"copilot"}:
        die("--scope user currently supports only the copilot target")
    return args


def locations(root, scope):
    if scope == "repo":
        runtime_root = root / ".task-completion-notifier"
        destinations = {
            "codex": root / "plugins/task-completion-notifier",
            "copilot": root / ".github/hooks/task-completion-notifier.json",
            "opencode": root / ".opencode/plugin/task-completion-notifier.ts",
            "cursor": root / ".cursor/hooks.json",
        }
        marketplace = root / ".agents/plugins/marketplace.json"
    else:
        data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        runtime_root = data_home / "task-completion-notifier" / state_fingerprint(root)
        copilot_home = Path(os.environ.get("COPILOT_HOME", Path.home() / ".copilot"))
        destinations = {"copilot": copilot_home / "hooks/task-completion-notifier.json"}
        marketplace = None
    return runtime_root, destinations, marketplace


def marketplace_entry():
    return {
        "name": "task-completion-notifier",
        "source": {"source": "local", "path": "./plugins/task-completion-notifier"},
        "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
        "category": "Productivity",
    }


def planned_conflicts(args, root, runtime_root, destinations, marketplace, manifest):
    conflicts, unsafe = [], []
    for relative in RUNTIME:
        target = runtime_root / relative
        if not target.exists():
            continue
        if target.is_symlink() or not target.is_file() or not managed_matches(target, relative, manifest) and target.read_bytes() != (SOURCE / relative).read_bytes():
            conflicts.append(target)
            unsafe.append(target)
    if args.scope == "repo" and "codex" in args.targets:
        target = destinations["codex"]
        if target.exists() and not rendered_tree_matches(SOURCE / "templates/codex-local", target, root, runtime_root) and not managed_matches(target / ".codex-plugin/plugin.json", "plugins/task-completion-notifier/.codex-plugin/plugin.json", manifest):
            conflicts.append(target)
            unsafe.append(target)
    if args.scope == "repo" and "opencode" in args.targets:
        target = destinations["opencode"]
        if target.exists() and not rendered_file_matches(SOURCE / "templates/opencode/.opencode/plugin/task-completion-notifier.ts", target, root, runtime_root) and not managed_matches(target, ".opencode/plugin/task-completion-notifier.ts", manifest):
            conflicts.append(target)
            unsafe.append(target)
    if args.action == "install":
        for name in ("copilot", "cursor"):
            if name in args.targets and destinations[name].exists() and not manifest:
                conflicts.append(destinations[name])
    if marketplace and "codex" in args.targets and marketplace.exists():
        data = load_json(marketplace)
        existing = [item for item in data.get("plugins", []) if isinstance(item, dict) and item.get("name") == "task-completion-notifier"] if isinstance(data, dict) else []
        if existing and existing[0] != marketplace_entry():
            conflicts.append(marketplace)
            unsafe.append(marketplace)
        elif not existing and args.action == "install":
            conflicts.append(marketplace)
    return conflicts, unsafe


def install_or_update(args, root, runtime_root, destinations, marketplace, manifest):
    for relative in RUNTIME:
        source, destination = SOURCE / relative, runtime_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if not destination.exists() or destination.read_bytes() != source.read_bytes():
            shutil.copy2(source, destination)
    if args.scope == "repo" and "codex" in args.targets:
        render_tree(SOURCE / "templates/codex-local", destinations["codex"], root, runtime_root)
        data = load_json(marketplace) if marketplace.exists() else {"name": "repository", "interface": {"displayName": "Repository plugins"}, "plugins": []}
        if not any(isinstance(item, dict) and item.get("name") == "task-completion-notifier" for item in data["plugins"]):
            data["plugins"].append(marketplace_entry())
            save_json(marketplace, data)
    if "copilot" in args.targets:
        template = SOURCE / "templates/github-copilot/.github/hooks/task-completion-notifier.json"
        save_json(destinations["copilot"], upsert_hook(destinations["copilot"], template, "agentStop", "bash", "github-copilot", root, runtime_root))
    if args.scope == "repo" and "cursor" in args.targets:
        template = SOURCE / "templates/cursor/.cursor/hooks.json"
        save_json(destinations["cursor"], upsert_hook(destinations["cursor"], template, "stop", "command", "cursor", root, runtime_root))
    if args.scope == "repo" and "opencode" in args.targets:
        destination = destinations["opencode"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(rendered_text(SOURCE / "templates/opencode/.opencode/plugin/task-completion-notifier.ts", root, runtime_root), encoding="utf-8")

    files = {}
    for relative in RUNTIME:
        record_file(files, runtime_root, runtime_root / relative)
    if args.scope == "repo":
        for name in ("codex", "opencode"):
            if name not in args.targets:
                continue
            target = destinations[name]
            if target.is_file():
                record_file(files, root, target)
            elif target.is_dir():
                for path in target.rglob("*"):
                    if path.is_file():
                        record_file(files, root, path)
    manifest_path = runtime_root / MANIFEST_NAME
    save_json(manifest_path, {"schema": 1, "version": VERSION, "scope": args.scope, "repository": str(root), "files": files})


def uninstall(args, root, runtime_root, destinations, marketplace, manifest):
    changed = []
    if "copilot" in args.targets and remove_hook(destinations["copilot"], "agentStop", "github-copilot"):
        changed.append(destinations["copilot"])
    if args.scope == "repo" and "cursor" in args.targets and remove_hook(destinations["cursor"], "stop", "cursor"):
        changed.append(destinations["cursor"])
    for name in ("codex", "opencode"):
        if name not in args.targets or args.scope != "repo":
            continue
        target = destinations[name]
        managed = manifest and all(
            managed_matches(path, str(path.relative_to(root)), manifest)
            for path in (target.rglob("*") if target.is_dir() else (target,))
            if path.is_file()
        )
        if target.exists() and not managed:
            die(f"refusing to remove modified managed target: {target}")
        if target.is_dir():
            shutil.rmtree(target)
            changed.append(target)
        elif target.exists():
            target.unlink()
            changed.append(target)
    if marketplace and "codex" in args.targets and marketplace.exists():
        data = load_json(marketplace)
        plugins = data.get("plugins") if isinstance(data, dict) else None
        if isinstance(plugins, list):
            kept = [item for item in plugins if not (isinstance(item, dict) and item.get("name") == "task-completion-notifier" and item == marketplace_entry())]
            if len(kept) != len(plugins):
                data["plugins"] = kept
                save_json(marketplace, data)
                changed.append(marketplace)
    if runtime_root.exists():
        if not manifest:
            die(f"refusing to remove unmanaged runtime: {runtime_root}")
        for relative, expected in manifest["files"].items():
            path = (root / relative) if args.scope == "repo" and not relative.startswith("scripts/") else runtime_root / relative
            if path.exists() and path.is_file() and sha256(path) != expected:
                die(f"refusing to remove modified managed runtime: {path}")
        shutil.rmtree(runtime_root)
        changed.append(runtime_root)
    if args.purge_state:
        state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
        state_root = state_home / "task-completion-notifier" / state_fingerprint(root)
        if state_root.exists():
            shutil.rmtree(state_root)
            changed.append(state_root)
    return changed


def doctor(args, root, runtime_root, destinations, manifest):
    notifier = runtime_root / "scripts/notify.py"
    checks = []
    checks.append(("Python runtime", sys.version_info >= (3, 9), sys.version.split()[0]))
    checks.append(("Managed runtime", notifier.is_file(), str(runtime_root)))
    if notifier.is_file():
        completed = subprocess.run([sys.executable, str(notifier), "--message", "check", "--check"], check=False, capture_output=True, text=True)
        checks.append(("Desktop notifier", completed.returncode == 0, completed.stderr.strip() or "available"))
    if manifest:
        checks.append(("Managed version", manifest.get("version") == VERSION, f"installed={manifest.get('version')} source={VERSION}"))
    else:
        checks.append(("Managed manifest", False, "not installed by this version"))
    for name in args.targets:
        checks.append((f"{name} configuration", destinations[name].exists(), str(destinations[name])))
    for name, ok, detail in checks:
        print(f"{'PASS' if ok else 'FAIL'} {name}: {detail}")
    return 0 if all(ok for _, ok, _ in checks) else 1


def main():
    args = parse_args()
    root = repository_root(args.repo)
    runtime_root, destinations, marketplace = locations(root, args.scope)
    manifest = load_manifest(runtime_root / MANIFEST_NAME)
    if args.action == "doctor":
        return doctor(args, root, runtime_root, destinations, manifest)
    if args.action == "uninstall":
        print(f"Repository: {root}\nScope: {args.scope}\nWould remove: {runtime_root}")
        for target in args.targets:
            print(f"Would remove integration: {destinations[target]}")
        if not args.apply:
            print("Preview only. Re-run with --apply to uninstall.")
            return 0
        changed = uninstall(args, root, runtime_root, destinations, marketplace, manifest)
        print("Removed task-completion-notifier integration:")
        for path in changed:
            print(f"- {path}")
        return 0
    conflicts, unsafe = planned_conflicts(args, root, runtime_root, destinations, marketplace, manifest)
    print(f"Repository: {root}\nScope: {args.scope}\nAction: {args.action}\nRuntime: {runtime_root}")
    print("State: XDG_STATE_HOME/task-completion-notifier/<repository-hash>")
    for target in args.targets:
        print(f"Would {args.action}: {destinations[target]}")
    if conflicts:
        print("Existing configuration requires explicit approval:", file=sys.stderr)
        for path in dict.fromkeys(conflicts):
            print(f"- {path}", file=sys.stderr)
        if not args.apply:
            return 1
    if not args.apply:
        print("Preview only. Re-run with --apply to continue.")
        return 0
    if unsafe:
        die("refusing unsafe overwrite; resolve the listed modified file manually")
    install_or_update(args, root, runtime_root, destinations, marketplace, manifest)
    print(f"{args.action.capitalize()}ed task-completion-notifier integration.")
    if args.scope == "repo" and "codex" in args.targets:
        print("The Codex target is registered in the repository marketplace; reinstall it there to activate the update.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
