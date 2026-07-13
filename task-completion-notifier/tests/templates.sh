#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
templates="$skill_root/templates"
copilot="$templates/github-copilot/.github/hooks/task-completion-notifier.json"
cursor="$templates/cursor/.cursor/hooks.json"
opencode="$templates/opencode/.opencode/plugin/task-completion-notifier.ts"
codex="$templates/codex-local/.codex-plugin/plugin.json"

python3 - "$codex" "$copilot" "$cursor" <<'PY'
import json
import sys

plugin, copilot, cursor = [json.load(open(path, encoding="utf-8")) for path in sys.argv[1:]]
assert plugin["skills"] == "./skills/"
assert "hooks" not in plugin
assert "__DISPATCH_SH__" in copilot["hooks"]["agentStop"][0]["bash"]
assert "__REPO_ROOT_SH__" in copilot["hooks"]["agentStop"][0]["bash"]
assert "__DISPATCH_SH__" in cursor["hooks"]["stop"][0]["command"]
PY

grep -Fq '__DISPATCH_JSON__' "$opencode"
grep -Fq 'event.properties.sessionID' "$opencode"
grep -Fq '__NOTIFIER_PY_SH__' "$templates/codex-local/skills/task-completion-notifier/SKILL.md.template"
! rg -q '__RUNTIME_ROOT__|notify-send' "$templates"

printf 'task-completion-notifier template tests passed\n'
