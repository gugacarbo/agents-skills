#!/usr/bin/env bash
set -euo pipefail

SKILL="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

fail() {
  echo "FAIL: $*"
  FAIL=$((FAIL + 1))
}
pass() {
  echo "PASS: $*"
  PASS=$((PASS + 1))
}

test_structure() {
  [ -f "$SKILL/SKILL.md" ] && pass 'SKILL.md' || fail 'missing SKILL.md'
  [ -f "$SKILL/references/brainstorm.md" ] && pass 'references/brainstorm.md' || fail 'missing references/brainstorm.md'
  [ -f "$SKILL/references/visual-companion.md" ] && pass 'references/visual-companion.md' || fail 'missing references/visual-companion.md'
  [ -d "$SKILL/scripts/visual-companion" ] && pass 'scripts/visual-companion/' || fail 'missing scripts/visual-companion/'
  [ -f "$SKILL/scripts/visual-companion/server.cjs" ] && pass 'server.cjs' || fail 'missing server.cjs'
  [ -f "$SKILL/scripts/visual-companion/start-server.sh" ] && pass 'start-server.sh' || fail 'missing start-server.sh'
  [ -f "$SKILL/scripts/visual-companion/stop-server.sh" ] && pass 'stop-server.sh' || fail 'missing stop-server.sh'
  [ -f "$SKILL/scripts/visual-companion/helper.js" ] && pass 'helper.js' || fail 'missing helper.js'
  [ -f "$SKILL/scripts/visual-companion/frame-template.html" ] && pass 'frame-template.html' || fail 'missing frame-template.html'
}

test_syntax() {
  for f in "$SKILL/scripts/visual-companion/"*.sh; do
    [ -f "$f" ] || continue
    sh -n "$f" && pass "syntax: $(basename "$f")" || fail "syntax error in $f"
  done
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  bun build --target=bun "$SKILL/scripts/visual-companion/server.cjs" --outfile "$tmp/server.cjs" && pass 'syntax: server.cjs' || fail 'syntax error in server.cjs'
}

test_structure
test_syntax

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
