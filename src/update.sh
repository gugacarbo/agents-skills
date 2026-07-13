#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
SKILLS_REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P
)

AGENTS_SKILLS_OWNER=${AGENTS_SKILLS_OWNER:-gugacarbo}
AGENTS_SKILLS_REPO=${AGENTS_SKILLS_REPO:-agents-skills}
AGENTS_SKILLS_REF=${AGENTS_SKILLS_REF:-main}
AGENTS_SKILLS_ARCHIVE_URL=${AGENTS_SKILLS_ARCHIVE_URL:-https://github.com/$AGENTS_SKILLS_OWNER/$AGENTS_SKILLS_REPO/archive/refs/heads/$AGENTS_SKILLS_REF.tar.gz}

YES=0
USE_GLOBAL=0
TARGET_PATH=''

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

log_line() {
  level=$1
  code=$2
  shift 2

  printf '%s %s\n' "$(color "$code" "[$level]")" "$*"
}

info() {
  log_line INFO 34 "$@"
}

warn() {
  log_line WARN 33 "$@"
}

success() {
  log_line OK 32 "$@"
}

error() {
  log_line ERROR 31 "$@" >&2
}

read_reply_from() {
  IFS= read -r reply <"$1"
}

usage() {
  cat <<'EOF'
Uso: ./src/update.sh [opcoes]

Opcoes:
  -p, --path PATH   Atualiza as skills no PATH informado
  -g, --global      Atualiza ~/.agents/skills
  -y, --yes         Sobrescreve automaticamente se houver diferencas
  -h, --help        Mostra esta ajuda
EOF
}

die() {
  error "$@"
  exit 1
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

resolve_existing_dir() {
  if [ -d "$1" ]; then
    (
      CDPATH='' cd -- "$1" && pwd -P
    )
  else
    printf '%s\n' "$1"
  fi
}

confirm() {
  prompt_message=$1
  prompt_input=${AGENTS_SKILLS_PROMPT_INPUT:-/dev/tty}

  printf '%s %s [y/N]: ' "$(color 36 '[PROMPT]')" "$prompt_message"

  if read_reply_from "$prompt_input" 2>/dev/null; then
    :
  elif ! IFS= read -r reply; then
    printf '\n'
    return 1
  fi

  case "$reply" in
    y|Y|yes|YES|Yes)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

download_archive() {
  archive_url=$1
  output_path=$2

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$output_path"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$output_path" "$archive_url"
  else
    die "curl ou wget eh necessario para baixar a versao remota"
  fi
}

find_extracted_root() {
  find "$1" -mindepth 1 -maxdepth 1 -type d | head -n 1
}

remote_matches_local() {
  source_dir=$1
  destination_dir=$2

  if [ ! -d "$destination_dir" ]; then
    return 1
  fi

  (
    CDPATH='' cd -- "$source_dir"
    find . -type f | while IFS= read -r relative_file; do
      source_file=$source_dir/$relative_file
      destination_file=$destination_dir/$relative_file

      if [ ! -f "$destination_file" ]; then
        exit 1
      fi

      if ! cmp -s "$source_file" "$destination_file"; then
        exit 1
      fi
    done
  )
}

copy_remote_files() {
  source_dir=$1
  destination_dir=$2

  mkdir -p "$destination_dir"
  cp -R "$source_dir/." "$destination_dir/"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--path)
      shift
      [ $# -gt 0 ] || die "A opcao $0 requer um path apos -p/--path"
      TARGET_PATH=$1
      ;;
    -g|--global)
      USE_GLOBAL=1
      ;;
    -y|--yes)
      YES=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Opcao desconhecida: $1"
      ;;
  esac
  shift
done

GLOBAL_TARGET=$(expand_path "~/.agents/skills")
CURRENT_DIR=$(resolve_existing_dir "$PWD")
CURRENT_DIR_NAME=${CURRENT_DIR##*/}

if [ -n "$TARGET_PATH" ]; then
  UPDATE_TARGET=$(expand_path "$TARGET_PATH")
  info "Destino definido via --path: $UPDATE_TARGET"
elif [ "$USE_GLOBAL" -eq 1 ]; then
  UPDATE_TARGET=$GLOBAL_TARGET
  info "Flag --global detectada; atualizando instalacao global"
elif [ "$CURRENT_DIR_NAME" = "skills" ] || [ -f "$CURRENT_DIR/skills.sh" ]; then
  UPDATE_TARGET=$CURRENT_DIR
  info "Atualizando o diretorio atual: $UPDATE_TARGET"
elif [ -d "$GLOBAL_TARGET" ]; then
  UPDATE_TARGET=$GLOBAL_TARGET
  warn "Diretorio atual nao parece ser uma instalacao; usando $GLOBAL_TARGET"
else
  die "Nao foi possivel determinar o destino. Use --path PATH ou --global"
fi

tmp_dir=$(mktemp -d)
archive_path=$tmp_dir/agents-skills.tar.gz

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT INT TERM

info "Baixando versao remota de $AGENTS_SKILLS_ARCHIVE_URL"
download_archive "$AGENTS_SKILLS_ARCHIVE_URL" "$archive_path"
tar -xzf "$archive_path" -C "$tmp_dir"

REMOTE_ROOT=$(find_extracted_root "$tmp_dir")
[ -n "$REMOTE_ROOT" ] || die "Nao foi possivel localizar os arquivos extraidos"
[ -f "$REMOTE_ROOT/skills.sh" ] || die "Arquivo skills.sh nao encontrado no pacote baixado"

[ -d "$UPDATE_TARGET" ] || die "Destino de update nao existe: $UPDATE_TARGET. Use install primeiro."

if remote_matches_local "$REMOTE_ROOT" "$UPDATE_TARGET"; then
  success "Instalacao local ja esta atualizada"
  exit 0
fi

warn "A versao local em $UPDATE_TARGET esta diferente do repositorio remoto"

if [ "$YES" -eq 1 ]; then
  info "Flag --yes aplicada; sobrescrevendo arquivos locais com a versao remota"
elif ! confirm "Sobrescrever os arquivos em $UPDATE_TARGET com a versao remota?"; then
  die "Atualizacao cancelada pelo usuario"
fi

copy_remote_files "$REMOTE_ROOT" "$UPDATE_TARGET"
success "Atualizacao concluida em $UPDATE_TARGET"
