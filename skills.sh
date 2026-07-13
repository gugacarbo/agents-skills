#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
SCRIPT_BASENAME=${0##*/}

case "$SCRIPT_BASENAME" in
  sh|dash)
    IS_STREAMED=1
    ;;
  *)
    IS_STREAMED=0
    ;;
esac

if [ "$IS_STREAMED" -eq 1 ]; then
  INTERNAL_SCRIPTS_DIR=$SCRIPT_DIR/.agents-skills-streamed-bootstrap
else
  INTERNAL_SCRIPTS_DIR=$SCRIPT_DIR/.scripts
fi

AGENTS_SKILLS_OWNER=${AGENTS_SKILLS_OWNER:-gugacarbo}
AGENTS_SKILLS_REPO=${AGENTS_SKILLS_REPO:-agents-skills}
AGENTS_SKILLS_REF=${AGENTS_SKILLS_REF:-main}
AGENTS_SKILLS_ARCHIVE_URL=${AGENTS_SKILLS_ARCHIVE_URL:-https://github.com/$AGENTS_SKILLS_OWNER/$AGENTS_SKILLS_REPO/archive/refs/heads/$AGENTS_SKILLS_REF.tar.gz}

if [ -t 1 ] && [ -z "${NO_COLOR-}" ]; then
  USE_COLOR=1
else
  USE_COLOR=0
fi

color() {
  code=$1
  text=$2

  if [ "$USE_COLOR" -eq 1 ]; then
    printf '\033[%sm%s\033[0m' "$code" "$text"
  else
    printf '%s' "$text"
  fi
}

list_commands() {
  if [ -d "$INTERNAL_SCRIPTS_DIR" ]; then
    find "$INTERNAL_SCRIPTS_DIR" -maxdepth 1 -type f -name '*.sh' -print \
      | sed "s|$INTERNAL_SCRIPTS_DIR/||" \
      | sed 's|\.sh$||' \
      | sort
  else
    printf 'install\n'
  fi
}

usage() {
  cat <<EOF
Uso: ./skills.sh <comando> [args]

Comandos disponiveis:
$(list_commands | sed 's/^/  - /')

Exemplos:
  ./skills.sh install
  ./skills.sh install --path ~/.codex/skills
  ./skills.sh update
  ./skills.sh update --yes
  ./skills.sh build
  ./skills.sh dev
EOF
}

die() {
  printf '%s %s\n' "$(color 31 '[ERROR]')" "$1" >&2
  exit 1
}

download_archive() {
  archive_url=$1
  output_path=$2

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$output_path"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$output_path" "$archive_url"
  else
    die "curl ou wget eh necessario para baixar o pacote de bootstrap"
  fi
}

bootstrap_from_archive() {
  command_name=$1
  shift

  tmp_dir=$(mktemp -d)
  archive_path=$tmp_dir/agents-skills.tar.gz

  cleanup() {
    rm -rf "$tmp_dir"
  }

  trap cleanup EXIT INT TERM

  printf '%s %s\n' "$(color 34 '[INFO]')" "Baixando pacote de bootstrap de $AGENTS_SKILLS_ARCHIVE_URL"
  download_archive "$AGENTS_SKILLS_ARCHIVE_URL" "$archive_path"
  tar -xzf "$archive_path" -C "$tmp_dir"

  extracted_root=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  [ -n "$extracted_root" ] || die "Nao foi possivel localizar os arquivos extraidos"
  [ -f "$extracted_root/skills.sh" ] || die "Arquivo skills.sh nao encontrado no pacote baixado"

  printf '%s %s\n' "$(color 34 '[INFO]')" "Executando comando $command_name a partir do pacote baixado"
  AGENTS_SKILLS_BOOTSTRAPPED=1 sh "$extracted_root/skills.sh" "$command_name" "$@"
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

COMMAND=$1
shift

COMMAND_SCRIPT=$INTERNAL_SCRIPTS_DIR/$COMMAND.sh

if [ ! -f "$COMMAND_SCRIPT" ]; then
  if [ "${AGENTS_SKILLS_BOOTSTRAPPED:-0}" = "1" ]; then
    die "Comando $COMMAND nao encontrado no pacote baixado"
  fi

  bootstrap_from_archive "$COMMAND" "$@"
  exit 0
fi

[ -x "$COMMAND_SCRIPT" ] || die "Script interno sem permissao de execucao: $COMMAND_SCRIPT"

exec "$COMMAND_SCRIPT" "$@"
