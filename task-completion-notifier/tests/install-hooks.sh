#!/usr/bin/env bash
set -euo pipefail

skill_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
installer=(sh "$skill_root/scripts/install-hooks.sh")
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
}

repo="$tmpdir/clean"
make_repo "$repo"
"${installer[@]}" --repo "$repo" --targets codex,copilot,opencode,cursor >"$tmpdir/preview"
[[ ! -e "$repo/.task-completion-notifier" ]]
grep -Fq 'Preview only' "$tmpdir/preview"
"${installer[@]}" --repo "$repo" --targets codex,copilot,opencode,cursor --approve-merge
if rg -q '__RUNTIME_ROOT__' "$repo"; then
  echo 'installer left an unresolved runtime placeholder' >&2
  exit 1
fi

for path in \
  .task-completion-notifier/scripts/hook-dispatch.py \
  plugins/task-completion-notifier/.codex-plugin/plugin.json \
  .agents/plugins/marketplace.json \
  .github/hooks/task-completion-notifier.json \
  .opencode/plugins/task-completion-notifier.ts \
  .cursor/hooks.json
do
  [[ -f "$repo/$path" ]]
done
rg -l --fixed-strings "$repo/.task-completion-notifier/scripts/hook-dispatch.py" \
  "$repo/plugins/task-completion-notifier" \
  "$repo/.github/hooks" \
  "$repo/.opencode/plugins" \
  "$repo/.cursor/hooks.json" | wc -l | grep -qx '4'

merge="$tmpdir/merge"
make_repo "$merge"
mkdir -p "$merge/.cursor"
printf '%s\n' '{"version":1,"hooks":{"afterFileEdit":[{"command":"echo keep"}]}}' >"$merge/.cursor/hooks.json"
if "${installer[@]}" --repo "$merge" --targets cursor >"$tmpdir/conflict" 2>&1; then
  echo 'expected conflict without approval' >&2
  exit 1
fi
"${installer[@]}" --repo "$merge" --targets cursor --approve-merge
python3 - "$merge/.cursor/hooks.json" <<'PY'
import json
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["hooks"]["afterFileEdit"][0]["command"] == "echo keep"
assert len(value["hooks"]["stop"]) == 1
PY

divergent="$tmpdir/divergent"
make_repo "$divergent"
mkdir -p "$divergent/.task-completion-notifier/scripts"
printf '%s\n' '#!/usr/bin/env sh' 'exit 99' >"$divergent/.task-completion-notifier/scripts/notify.sh"
if "${installer[@]}" --repo "$divergent" --targets cursor --approve-merge >"$tmpdir/divergent-output" 2>&1; then
  echo 'expected divergent runtime refusal' >&2
  exit 1
fi
grep -Fq 'refusing unsafe overwrite' "$tmpdir/divergent-output"

printf 'task-completion-notifier installer tests passed\n'
