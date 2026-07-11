#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
templates="$skill_root/templates"
runtime='.task-completion-notifier/scripts/hook-dispatch.py'
state_dir='.task-completion-notifier/state'
notifier='.task-completion-notifier/scripts/notify.sh'

codex_hooks="$templates/codex-local/hooks/hooks.json"
copilot_hooks="$templates/github-copilot/.github/hooks/task-completion-notifier.json"
opencode_plugin="$templates/opencode/.opencode/plugins/task-completion-notifier.ts"
cursor_hooks="$templates/cursor/.cursor/hooks.json"

for path in \
  "$templates/codex-local/.codex-plugin/plugin.json" \
  "$templates/codex-local/skills/task-completion-notifier/SKILL.md" \
  "$codex_hooks" \
  "$copilot_hooks" \
  "$opencode_plugin" \
  "$cursor_hooks"; do
  [[ -f "$path" ]] || { printf 'Missing template: %s\n' "$path" >&2; exit 1; }
done

python3 - "$templates/codex-local/.codex-plugin/plugin.json" "$codex_hooks" "$copilot_hooks" "$cursor_hooks" <<'PY'
import json
import sys

plugin_path, codex_path, copilot_path, cursor_path = sys.argv[1:]
plugin = json.load(open(plugin_path, encoding="utf-8"))
codex = json.load(open(codex_path, encoding="utf-8"))
copilot = json.load(open(copilot_path, encoding="utf-8"))
cursor = json.load(open(cursor_path, encoding="utf-8"))

assert plugin["skills"] == ["./skills/task-completion-notifier"]
assert plugin["hooks"] == "./hooks/hooks.json"
assert "Stop" in codex["hooks"]
assert "agentStop" in copilot["hooks"]
assert "stop" in cursor["hooks"]
PY

for path in "$codex_hooks" "$copilot_hooks" "$opencode_plugin" "$cursor_hooks"; do
  grep -Fq "$runtime" "$path" || {
    printf 'Missing dispatcher path in %s\n' "$path" >&2
    exit 1
  }
  if grep -Fq 'notify-send' "$path"; then
    printf 'Direct notify-send usage in %s\n' "$path" >&2
    exit 1
  fi
done

assert_dispatch_args() {
  local path=$1
  local agent=$2
  local event=$3
  grep -Fq -- "--agent $agent" "$path" || {
    printf 'Missing agent argument in %s\n' "$path" >&2
    exit 1
  }
  grep -Fq -- "--event $event" "$path" || {
    printf 'Missing event argument in %s\n' "$path" >&2
    exit 1
  }
  grep -Fq -- "--state-dir __RUNTIME_ROOT__/$state_dir" "$path" || {
    printf 'Missing state-dir argument in %s\n' "$path" >&2
    exit 1
  }
  grep -Fq -- "--notifier __RUNTIME_ROOT__/$notifier" "$path" || {
    printf 'Missing notifier argument in %s\n' "$path" >&2
    exit 1
  }
}

assert_dispatch_args "$codex_hooks" codex Stop
assert_dispatch_args "$copilot_hooks" github-copilot agentStop
assert_dispatch_args "$cursor_hooks" cursor stop

grep -Fq -- '--agent opencode' "$opencode_plugin"
grep -Fq -- '--event session.idle' "$opencode_plugin"
grep -Fq -- '--state-dir ${stateDir}' "$opencode_plugin"
grep -Fq -- '--notifier ${notifier}' "$opencode_plugin"

grep -Fq 'session.idle' "$opencode_plugin"
grep -Fq 'event.type !== "session.idle"' "$opencode_plugin"
grep -Fq 'const runtime = ' "$opencode_plugin"
grep -Fq 'const stateDir = ' "$opencode_plugin"
grep -Fq 'const notifier = ' "$opencode_plugin"
! grep -Fq 'notify-send' "$templates/opencode/.opencode/plugins/task-completion-notifier.ts"

printf 'task-completion-notifier template tests passed\n'
