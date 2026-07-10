#!/usr/bin/env sh
set -eu

# Update the helper stack used by a super-planning run from the repository's
# GitHub remote. Existing files outside this list are left untouched.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
  SCRIPT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
else
  SCRIPT_ROOT="$SCRIPT_DIR"
fi
REPO_ROOT="$(git -C "$SCRIPT_ROOT" rev-parse --show-toplevel 2>/dev/null || git rev-parse --show-toplevel)"
REMOTE_URL="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
TARGET=""
REF="${AGENTS_SKILLS_REF:-main}"
TMP_DIR=""

usage() {
  cat <<'EOF'
Usage: super-update.sh [--target <super-planning|.super-planning>] [--repo-url <github-url>] [--ref <git-ref>]

Updates the helper stack from the repository's origin remote. The remote must
contain a super-planning/ directory with the published helper files.
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --repo-url) REMOTE_URL="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) usage ;;
  esac
done

case "$REMOTE_URL" in
  *github.com*|*github.com:*) ;;
  *) printf '%s\n' "Error: origin is not a GitHub remote: ${REMOTE_URL:-<empty>}" >&2; exit 1 ;;
esac

if [ -z "$TARGET" ]; then
  if [ -d "$REPO_ROOT/super-planning" ]; then
    TARGET="$REPO_ROOT/super-planning"
  else
    TARGET="$REPO_ROOT/.super-planning"
  fi
elif [ "${TARGET#/}" = "$TARGET" ]; then
  TARGET="$REPO_ROOT/$TARGET"
fi

if [ "$(basename "$TARGET")" = "super-planning" ] && [ -d "$TARGET/scripts" ]; then
  TARGET_LAYOUT="nested"
else
  TARGET_LAYOUT="flat"
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT HUP INT TERM

CHECKOUT="$TMP_DIR/repository"
git clone --quiet --depth 1 --branch "$REF" --single-branch "$REMOTE_URL" "$CHECKOUT"

SOURCE="$CHECKOUT/super-planning"
[ -d "$SOURCE" ] || { printf '%s\n' "Error: remote has no super-planning/ directory" >&2; exit 1; }
mkdir -p "$TARGET"

if [ "$TARGET_LAYOUT" = "flat" ] && [ ! -e "$TARGET/.gitignore" ]; then
  [ -f "$SOURCE/templates/.gitignore-template" ] || {
    printf '%s\n' "Error: remote file missing: super-planning/templates/.gitignore-template" >&2
    exit 1
  }
  cp "$SOURCE/templates/.gitignore-template" "$TARGET/.gitignore"
fi

for file in \
  scripts/super-plan.sh \
  scripts/super-update.sh \
  scripts/render-progress-ledger.sh \
  scripts/log-task.sh \
  scripts/review-package.sh \
  scripts/render-task-md.sh \
  scripts/summarize-all-tasks.sh \
  interfaces/super-plan.schema.json
do
  [ -f "$SOURCE/$file" ] || { printf '%s\n' "Error: remote file missing: super-planning/$file" >&2; exit 1; }
  if [ "$TARGET_LAYOUT" = "nested" ]; then
    destination="$TARGET/$file"
  else
    destination="$TARGET/$(basename "$file")"
  fi
  mkdir -p "$(dirname "$destination")"
  cp "$SOURCE/$file" "$destination"
done

COMMIT="$(git -C "$CHECKOUT" rev-parse HEAD)"
VERSION="$(git -C "$CHECKOUT" describe --tags --always 2>/dev/null || printf '%s' "$COMMIT")"
python3 - "$TARGET/super-planning-reference.json" "$REMOTE_URL" "$REF" "$COMMIT" "$VERSION" "$TARGET" <<'PY'
import json
import sys
from datetime import datetime, timezone

output, repository, ref_name, commit, version, skill_path = sys.argv[1:]
payload = {
    "format": 1,
    "skill": "super-planning",
    "repository": repository,
    "ref": ref_name,
    "commit": commit,
    "version": version,
    "skillPath": skill_path,
    "generatedAt": datetime.now(timezone.utc).isoformat(),
}
with open(output, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY

if [ "$TARGET_LAYOUT" = "nested" ]; then
  chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
else
  chmod +x "$TARGET/"*.sh 2>/dev/null || true
fi
printf '%s\n' "Updated super-planning helpers in $TARGET from $REMOTE_URL@$REF ($COMMIT)"
