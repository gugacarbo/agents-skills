#!/usr/bin/env sh
set -eu

# Update the helper stack used by a super-planning run from its durable skill
# reference. Existing files outside this list are left untouched.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
  SCRIPT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
else
  SCRIPT_ROOT="$SCRIPT_DIR"
fi
REPO_ROOT="$(git -C "$SCRIPT_ROOT" rev-parse --show-toplevel 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || pwd)"
REMOTE_URL=""
TARGET=""
REF="${AGENTS_SKILLS_REF:-}"
TMP_DIR=""

usage() {
  cat <<'EOF'
Usage: super-update.sh [--target <super-planning|.super-planning>] [--repo-url <github-url>] [--ref <git-ref>]

Updates the helper stack from its super-planning-reference.json. Use --repo-url
and --ref to override that durable source explicitly. The source must contain a
skills/super-planning/ directory with the published helper files.
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

if [ -z "$TARGET" ]; then
  if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
    TARGET="$SCRIPT_ROOT"
  elif [ "$(basename "$SCRIPT_DIR")" = ".super-planning" ]; then
    TARGET="$SCRIPT_DIR"
  elif [ -d "$REPO_ROOT/super-planning" ]; then
    TARGET="$REPO_ROOT/super-planning"
  else
    TARGET="$REPO_ROOT/.super-planning"
  fi
elif [ "${TARGET#/}" = "$TARGET" ]; then
  TARGET="$REPO_ROOT/$TARGET"
fi

REFERENCE_FILE="$TARGET/super-planning-reference.json"
if [ -f "$REFERENCE_FILE" ]; then
  reference_values=$(python3 - "$REFERENCE_FILE" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        reference = json.load(handle)
    repository = reference.get("repository", "")
    ref = reference.get("ref", "")
    if not isinstance(repository, str) or not isinstance(ref, str):
        raise ValueError("repository/ref must be strings")
    print(repository)
    print(ref)
except (OSError, ValueError, json.JSONDecodeError) as error:
    print(f"Error: invalid skill reference: {error}", file=sys.stderr)
    sys.exit(1)
PY
)
  reference_repository=$(printf '%s\n' "$reference_values" | sed -n '1p')
  reference_ref=$(printf '%s\n' "$reference_values" | sed -n '2p')
  if [ -z "$REMOTE_URL" ]; then REMOTE_URL="$reference_repository"; fi
  if [ -z "$REF" ]; then REF="$reference_ref"; fi
fi

# Backward compatibility for pre-reference installations. This fallback is
# deliberately last: a project's origin is not the source of copied helpers.
if [ -z "$REMOTE_URL" ]; then
  REMOTE_URL="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
fi
if [ -z "$REF" ]; then REF="main"; fi

case "$REMOTE_URL" in
  *github.com*|*github.com:*) ;;
  *) printf '%s\n' "Error: helper source is not a GitHub remote: ${REMOTE_URL:-<empty>}" >&2; exit 1 ;;
esac

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

SOURCE="$CHECKOUT/skills/super-planning"
[ -d "$SOURCE" ] || { printf '%s\n' "Error: remote has no skills/super-planning/ directory" >&2; exit 1; }
mkdir -p "$TARGET"

if [ "$TARGET_LAYOUT" = "flat" ] && [ ! -e "$TARGET/.gitignore" ]; then
  [ -f "$SOURCE/templates/.gitignore-template" ] || {
    printf '%s\n' "Error: remote file missing: skills/super-planning/templates/.gitignore-template" >&2
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
  scripts/doctor.sh \
  scripts/bootstrap.sh \
  scripts/visual-companion/start-server.sh \
  scripts/visual-companion/stop-server.sh \
  scripts/visual-companion/server.cjs \
  scripts/visual-companion/helper.js \
  scripts/visual-companion/frame-template.html \
  interfaces/super-plan.schema.json
do
  [ -f "$SOURCE/$file" ] || { printf '%s\n' "Error: remote file missing: skills/super-planning/$file" >&2; exit 1; }
  if [ "$TARGET_LAYOUT" = "nested" ]; then
    destination="$TARGET/$file"
  else
    case "$file" in
      scripts/visual-companion/*)
        destination="$TARGET/visual-companion/$(basename "$file")"
        ;;
      *)
        destination="$TARGET/$(basename "$file")"
        ;;
    esac
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
  chmod +x "$TARGET/scripts/visual-companion/"*.sh 2>/dev/null || true
else
  chmod +x "$TARGET/"*.sh 2>/dev/null || true
  chmod +x "$TARGET/visual-companion/"*.sh 2>/dev/null || true
fi
printf '%s\n' "Updated super-planning helpers in $TARGET from $REMOTE_URL@$REF ($COMMIT)"
