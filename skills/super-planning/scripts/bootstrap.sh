#!/usr/bin/env sh
set -eu

# Materialize a complete flat .super-planning helper stack from a known source
# skill installation. Provenance is recorded from the source, never inferred
# from the target application's Git remote.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR=""
REPOSITORY_URL=""
REF_NAME=""
COMMIT_SHA=""

usage() {
  cat <<'EOF'
Usage: bootstrap.sh --target-dir <project/.super-planning> [options]

Options:
  --source-dir <super-planning-dir>  Source skill directory (default: this skill)
  --repo-url <git-url>               Explicit source repository URL
  --ref <git-ref>                    Explicit source ref
  --commit <git-sha>                 Explicit source commit
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift 2 ;;
    --source-dir) SOURCE_DIR="$2"; shift 2 ;;
    --repo-url) REPOSITORY_URL="$2"; shift 2 ;;
    --ref) REF_NAME="$2"; shift 2 ;;
    --commit) COMMIT_SHA="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) usage ;;
  esac
done

[ -n "$TARGET_DIR" ] || usage
[ -f "$SOURCE_DIR/scripts/super-plan.sh" ] || { printf '%s\n' "Error: source is not a super-planning skill: $SOURCE_DIR" >&2; exit 1; }

SOURCE_REPO_ROOT="$(git -C "$SOURCE_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPOSITORY_URL" ] && [ -n "$SOURCE_REPO_ROOT" ]; then
  REPOSITORY_URL="$(git -C "$SOURCE_REPO_ROOT" remote get-url origin 2>/dev/null || true)"
fi
if [ -z "$REF_NAME" ] && [ -n "$SOURCE_REPO_ROOT" ]; then
  REF_NAME="$(git -C "$SOURCE_REPO_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
fi
if [ -z "$COMMIT_SHA" ] && [ -n "$SOURCE_REPO_ROOT" ]; then
  COMMIT_SHA="$(git -C "$SOURCE_REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
fi

if [ -z "$REPOSITORY_URL" ] || [ -z "$REF_NAME" ] || [ -z "$COMMIT_SHA" ]; then
  printf '%s\n' "Error: source provenance is incomplete; pass --repo-url, --ref, and --commit explicitly" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR" "$TARGET_DIR/visual-companion"
for file in \
  super-plan.sh super-update.sh render-progress-ledger.sh log-task.sh \
  review-package.sh render-task-md.sh summarize-all-tasks.sh doctor.sh bootstrap.sh
do
  cp "$SOURCE_DIR/scripts/$file" "$TARGET_DIR/$file"
done
cp "$SOURCE_DIR/interfaces/super-plan.schema.json" "$TARGET_DIR/super-plan.schema.json"
cp "$SOURCE_DIR/templates/.gitignore-template" "$TARGET_DIR/.gitignore"
for file in start-server.sh stop-server.sh server.cjs helper.js frame-template.html; do
  cp "$SOURCE_DIR/scripts/visual-companion/$file" "$TARGET_DIR/visual-companion/$file"
done
chmod +x "$TARGET_DIR"/*.sh "$TARGET_DIR/visual-companion"/*.sh

sh "$TARGET_DIR/super-plan.sh" reference \
  --output "$TARGET_DIR/super-planning-reference.json" \
  --repo-url "$REPOSITORY_URL" \
  --ref "$REF_NAME" \
  --commit "$COMMIT_SHA" >/dev/null

printf '%s\n' "$TARGET_DIR"
