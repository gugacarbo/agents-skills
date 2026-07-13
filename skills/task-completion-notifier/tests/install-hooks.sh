#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
installer=(sh "$skill_root/scripts/install-hooks.sh")
validator="${CODEX_HOME:-$HOME/.codex}/skills/.system/plugin-creator/scripts/validate_plugin.py"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_repo() { mkdir -p "$1"; git -C "$1" init -q; }
repo="$tmpdir/repo with space"
make_repo "$repo"

"${installer[@]}" --repo "$repo" --targets codex,copilot,opencode,cursor >"$tmpdir/preview"
[[ ! -e "$repo/.task-completion-notifier" ]]
grep -Fq 'Preview only' "$tmpdir/preview"
"${installer[@]}" --repo "$repo" --targets codex,copilot,opencode,cursor --approve-merge
! rg -q '__[A-Z_]+__' "$repo"
python3 "$validator" "$repo/plugins/task-completion-notifier"

for path in \
  .task-completion-notifier/scripts/hook-dispatch.py \
  plugins/task-completion-notifier/.codex-plugin/plugin.json \
  .agents/plugins/marketplace.json \
  .github/hooks/task-completion-notifier.json \
  .opencode/plugin/task-completion-notifier.ts \
  .cursor/hooks.json
do
  [[ -f "$repo/$path" ]]
done

# Generated shell commands survive a repository path containing spaces.
mkdir -p "$tmpdir/bin"
printf '%s\n' '#!/usr/bin/env sh' 'printf "%s\n" "$@" >"$NOTIFY_CAPTURE"' >"$tmpdir/bin/notify-send"
chmod +x "$tmpdir/bin/notify-send"
XDG_STATE_HOME="$tmpdir/state" python3 "$repo/.task-completion-notifier/scripts/session-state.py" arm \
  --repo-root "$repo" --agent cursor --session-id s1 --message 'Installed runtime works' >/dev/null
command=$(python3 - "$repo/.cursor/hooks.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["hooks"]["stop"][0]["command"])
PY
)
printf '%s\n' '{"session_id":"s1"}' | PATH="$tmpdir/bin:$PATH" XDG_STATE_HOME="$tmpdir/state" NOTIFY_OS_RELEASE_FILE="$tmpdir/os-release" DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS=test NOTIFY_CAPTURE="$tmpdir/capture" sh -c "$command"
grep -Fxq 'Installed runtime works' "$tmpdir/capture"

# Managed installs can be diagnosed and updated without clobbering their files.
PATH="$tmpdir/bin:$PATH" DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS=test "${installer[@]}" --repo "$repo" --targets codex,copilot,opencode,cursor --doctor >"$tmpdir/doctor"
grep -Fq 'PASS Managed version' "$tmpdir/doctor"
"${installer[@]}" --repo "$repo" --targets codex,copilot,opencode,cursor --update --apply

# Removing one target preserves the shared runtime for the remaining targets.
"${installer[@]}" --repo "$repo" --targets cursor --uninstall --apply
[[ -d "$repo/.task-completion-notifier" ]]
python3 - "$repo/.cursor/hooks.json" <<'PY'
import json
import sys

hooks = json.load(open(sys.argv[1], encoding="utf-8"))["hooks"].get("stop", [])
assert not any("hook-dispatch.py" in entry.get("command", "") for entry in hooks)
PY

# A modified managed runtime blocks automatic updates.
printf '%s\n' '# modified by user' >>"$repo/.task-completion-notifier/scripts/notify.py"
if "${installer[@]}" --repo "$repo" --targets copilot --update --apply >"$tmpdir/modified-output" 2>&1; then
  echo 'expected modified managed runtime refusal' >&2
  exit 1
fi
grep -Fq 'refusing unsafe overwrite' "$tmpdir/modified-output"

# Existing Cursor and Copilot configurations are merged after approval.
merge="$tmpdir/merge"
make_repo "$merge"
mkdir -p "$merge/.cursor" "$merge/.github/hooks"
printf '%s\n' '{"version":1,"hooks":{"afterFileEdit":[{"command":"echo keep"}]}}' >"$merge/.cursor/hooks.json"
printf '%s\n' '{"version":1,"hooks":{"agentStop":[{"type":"command","bash":"echo keep"}]}}' >"$merge/.github/hooks/task-completion-notifier.json"
if "${installer[@]}" --repo "$merge" --targets cursor,copilot >"$tmpdir/conflict" 2>&1; then
  echo 'expected preview conflict' >&2
  exit 1
fi
"${installer[@]}" --repo "$merge" --targets cursor,copilot --approve-merge
python3 - "$merge/.cursor/hooks.json" "$merge/.github/hooks/task-completion-notifier.json" <<'PY'
import json, sys
cursor, copilot = [json.load(open(path, encoding="utf-8")) for path in sys.argv[1:]]
assert cursor["hooks"]["afterFileEdit"][0]["command"] == "echo keep"
assert len(cursor["hooks"]["stop"]) == 1
assert copilot["hooks"]["agentStop"][0]["bash"] == "echo keep"
assert len(copilot["hooks"]["agentStop"]) == 2
PY

# A divergent dedicated OpenCode plugin is never overwritten.
divergent="$tmpdir/divergent"
make_repo "$divergent"
mkdir -p "$divergent/.opencode/plugin"
printf '%s\n' 'export const different = true' >"$divergent/.opencode/plugin/task-completion-notifier.ts"
if "${installer[@]}" --repo "$divergent" --targets opencode --approve-merge >"$tmpdir/divergent-output" 2>&1; then
  echo 'expected divergent runtime refusal' >&2
  exit 1
fi
grep -Fq 'refusing unsafe overwrite' "$tmpdir/divergent-output"

# User-level Copilot integrations keep their runtime outside the repository.
user_repo="$tmpdir/user-repo"
make_repo "$user_repo"
copilot_home="$tmpdir/copilot-home"
data_home="$tmpdir/data-home"
COPILOT_HOME="$copilot_home" XDG_DATA_HOME="$data_home" "${installer[@]}" --repo "$user_repo" --targets copilot --scope user --apply
[[ -f "$copilot_home/hooks/task-completion-notifier.json" ]]
find "$data_home/task-completion-notifier" -name manifest.json -type f -print -quit | grep -q .

printf 'task-completion-notifier installer tests passed\n'
