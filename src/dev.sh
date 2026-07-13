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
DEFAULT_TARGET=$HOME/.agents/skills

info() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

read_reply_from() {
  IFS= read -r reply <"$1"
}

expand_path() {
  path_value=$1
  path_prefix=$(printf '%s' "$path_value" | cut -c1-2)

  if [ "$path_value" = "~" ]; then
    printf '%s\n' "$HOME"
  elif [ "$path_prefix" = "~/" ]; then
    printf '%s/%s\n' "$HOME" "$(printf '%s' "$path_value" | cut -c3-)"
  else
    printf '%s\n' "$path_value"
  fi
}

same_dir() {
  [ -d "$1" ] && [ -d "$2" ] || return 1
  [ "$(CDPATH='' cd -- "$1" && pwd -P)" = "$(CDPATH='' cd -- "$2" && pwd -P)" ]
}

source_signature() {
  (
    cd "$SKILLS_SOURCE_DIR"
    find . -type f -print | sort | while IFS= read -r source_file; do
      cksum "$source_file"
    done
  ) | cksum
}

build_and_deploy() {
  AGENTS_SKILLS_BUILD_OUTPUT="$BUILD_OUTPUT_DIR" sh "$BUILD_SCRIPT"

  if same_dir "$BUILD_OUTPUT_DIR" "$TARGET_PATH"; then
    info "Build ja esta no destino: $TARGET_PATH"
    return 0
  fi

  mkdir -p "$TARGET_PATH"
  cp -R "$BUILD_OUTPUT_DIR/." "$TARGET_PATH/"
  info "Skills enviadas para $TARGET_PATH"
}

case "${1:-}" in
  -h|--help)
    printf '%s\n' 'Uso: ./skills.sh dev'
    printf '%s\n' 'Observa skills/ e publica cada build no diretorio escolhido.'
    exit 0
    ;;
  '')
    ;;
  *)
    die "Opcao desconhecida: $1"
    ;;
esac

[ "${AGENTS_SKILLS_BOOTSTRAPPED:-0}" != "1" ] || die "O comando dev precisa de um checkout local do repositorio"
[ -d "$SKILLS_SOURCE_DIR" ] || die "Diretorio de skills nao encontrado: $SKILLS_SOURCE_DIR"
[ -x "$BUILD_SCRIPT" ] || die "Script de build nao executavel: $BUILD_SCRIPT"

prompt_input=${AGENTS_SKILLS_PROMPT_INPUT:-/dev/tty}
reply=''
printf '[PROMPT] Diretorio de saida [%s]: ' "$DEFAULT_TARGET"

if read_reply_from "$prompt_input" 2>/dev/null; then
  :
elif ! IFS= read -r reply; then
  printf '\n'
  die "Nao foi possivel ler o diretorio de saida"
fi

if [ -z "$reply" ]; then
  TARGET_PATH=$DEFAULT_TARGET
else
  TARGET_PATH=$(expand_path "$reply")
fi

initial_signature=$(source_signature)
build_and_deploy

if [ "${AGENTS_SKILLS_WATCH_ONCE:-0}" = "1" ]; then
  exit 0
fi

info "Observando alteracoes em $SKILLS_SOURCE_DIR. Use Ctrl+C para encerrar."
trap 'info "Observacao encerrada"; exit 0' INT TERM

while :; do
  sleep 1
  current_signature=$(source_signature)

  if [ "$current_signature" != "$initial_signature" ]; then
    info "Alteracao detectada; reconstruindo skills"
    build_and_deploy
    initial_signature=$current_signature
  fi
done
