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

remove_ignored_artifacts() {
  build_dir=$1

  find "$build_dir" -type d \( \
    -name node_modules -o \
    -name .pnpm-store -o \
    -name build -o \
    -name out -o \
    -name .next -o \
    -name .nuxt -o \
    -name .idea -o \
    -name logs -o \
    -name coverage -o \
    -name .cache -o \
    -name __pycache__ -o \
    -name .turbo -o \
    -name .code-flow \
  \) -prune -exec rm -rf {} \;

  find "$build_dir" -type f \( \
    -name package.json -o \
    -name pnpm-lock.yaml -o \
    -name package-lock.json -o \
    -name yarn.lock -o \
    -name bun.lockb -o \
    -name bun.lock -o \
    -name .env -o \
    \( -name '.env.*' ! -name .env.example \) -o \
    -name '*.swp' -o \
    -name '*.swo' -o \
    -name '*~' -o \
    -name .DS_Store -o \
    -name Thumbs.db -o \
    -name '*.log' -o \
    -name '*.tsbuildinfo' \
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
remove_ignored_artifacts "$BUILD_OUTPUT_DIR"

mkdir -p "$BUILD_TARGET_DIR"
# Migration cleanup: publishing code-flow must not leave the renamed skill
# discoverable under its former name.
rm -rf "$BUILD_TARGET_DIR/code-toolbox"

# Replace only skills owned by this repository so removed files do not survive
# publication while unrelated installed skills remain untouched.
for published_skill_dir in "$BUILD_OUTPUT_DIR"/*; do
  [ -d "$published_skill_dir" ] || continue
  skill_name=${published_skill_dir##*/}
  rm -rf "$BUILD_TARGET_DIR/$skill_name"
  cp -R "$published_skill_dir" "$BUILD_TARGET_DIR/"
done

printf '[OK] Build concluido com %s skill(s) em %s\n' "$copied_count" "$BUILD_OUTPUT_DIR"
printf '[OK] Skills copiadas para %s\n' "$BUILD_TARGET_DIR"
