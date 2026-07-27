#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
SKILLS_REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P
)
SKILLS_SOURCE_DIR=$SKILLS_REPO_ROOT/skills
BUILD_SCRIPT=$SCRIPT_DIR/build.sh
BUILD_OUTPUT_DIR=${AGENTS_SKILLS_BUILD_OUTPUT:-$SKILLS_REPO_ROOT/dist/skills}

info() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

source_signature() {
  (
    cd "$SKILLS_SOURCE_DIR"
    find . -type f -print | sort | while IFS= read -r source_file; do
      cksum "$source_file"
    done
  ) | cksum
}

build() {
  AGENTS_SKILLS_BUILD_OUTPUT="$BUILD_OUTPUT_DIR" \
    AGENTS_SKILLS_BUILD_DEPLOY=0 \
    sh "$BUILD_SCRIPT"
}

case "${1:-}" in
  -h | --help)
    printf '%s\n' 'Uso: ./skills.sh dev'
    printf '%s\n' 'Observa skills/ e atualiza dist/skills sem publicar em ~/.agents/skills.'
    exit 0
    ;;
  '')
    ;;
  *)
    die "Opção desconhecida: $1"
    ;;
esac

[ "${AGENTS_SKILLS_BOOTSTRAPPED:-0}" != "1" ] || die "O comando dev precisa de um checkout local do repositório"
[ -d "$SKILLS_SOURCE_DIR" ] || die "Diretório de skills não encontrado: $SKILLS_SOURCE_DIR"
[ -x "$BUILD_SCRIPT" ] || die "Script de build não executável: $BUILD_SCRIPT"

initial_signature=$(source_signature)
build

if [ "${AGENTS_SKILLS_WATCH_ONCE:-0}" = "1" ]; then
  exit 0
fi

info "Observando alterações em $SKILLS_SOURCE_DIR. Use Ctrl+C para encerrar."
trap 'info "Observação encerrada"; exit 0' INT TERM

while :; do
  sleep 1
  current_signature=$(source_signature)

  if [ "$current_signature" != "$initial_signature" ]; then
    info "Alteração detectada; reconstruindo skills"
    build
    initial_signature=$current_signature
  fi
done
