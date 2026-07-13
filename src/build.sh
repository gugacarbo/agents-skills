#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
SKILLS_REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P
)
SKILLS_SOURCE_DIR=$SKILLS_REPO_ROOT/skills
BUILD_OUTPUT_DIR=${AGENTS_SKILLS_BUILD_OUTPUT:-$SKILLS_REPO_ROOT/dist/skills}
BUILD_TARGET_DIR=${AGENTS_SKILLS_BUILD_TARGET:-$HOME/.agents/skills}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

remove_test_artifacts() {
  build_dir=$1

  find "$build_dir" -type d \( \
    -name dev -o \
    -name test -o \
    -name tests -o \
    -name __test__ -o \
    -name __tests__ \
  \) -prune -exec rm -rf {} \;

  find "$build_dir" -type f \( \
    -name '*.test.*' -o \
    -name '*.spec.*' -o \
    -name '*_test.*' -o \
    -name '*_spec.*' -o \
    -name 'test_*' -o \
    -name 'spec_*' \
  \) -exec rm -f {} \;
}

[ -d "$SKILLS_SOURCE_DIR" ] || die "Diretorio de skills nao encontrado: $SKILLS_SOURCE_DIR"
[ "$BUILD_OUTPUT_DIR" != "$SKILLS_SOURCE_DIR" ] || die "A saida de build nao pode ser o diretorio de fontes"
[ "$BUILD_TARGET_DIR" != "$SKILLS_SOURCE_DIR" ] || die "O destino de build nao pode ser o diretorio de fontes"

rm -rf "$BUILD_OUTPUT_DIR"
mkdir -p "$BUILD_OUTPUT_DIR"

copied_count=0
for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  cp -R "$skill_dir" "$BUILD_OUTPUT_DIR/"
  copied_count=$((copied_count + 1))
done

[ "$copied_count" -gt 0 ] || die "Nenhuma skill elegivel foi encontrada para build"

remove_test_artifacts "$BUILD_OUTPUT_DIR"

mkdir -p "$BUILD_TARGET_DIR"
cp -R "$BUILD_OUTPUT_DIR/." "$BUILD_TARGET_DIR/"

printf '[OK] Build concluido com %s skill(s) em %s\n' "$copied_count" "$BUILD_OUTPUT_DIR"
printf '[OK] Skills copiadas para %s\n' "$BUILD_TARGET_DIR"
