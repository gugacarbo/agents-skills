#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
SKILLS_REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P
)

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
Uso: ./.scripts/install.sh [opcoes]

Opcoes:
  -p, --path PATH   Instala as skills no PATH informado
  -g, --global      Usa ~/.agents/skills como primeira escolha
  -y, --yes         Aprova automaticamente apenas a instalacao local do repo
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

same_dir() {
  if [ ! -d "$1" ] || [ ! -d "$2" ]; then
    return 1
  fi

  [ "$(resolve_existing_dir "$1")" = "$(resolve_existing_dir "$2")" ]
}

find_repo_root() {
  if command -v git >/dev/null 2>&1; then
    git -C "$1" rev-parse --show-toplevel 2>/dev/null || true
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

copy_skills() {
  destination=$1
  copied_count=0

  mkdir -p "$destination"
  info "Instalando skills em $destination"

  for skill_dir in "$SKILLS_REPO_ROOT"/*; do
    [ -d "$skill_dir" ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue

    skill_name=${skill_dir##*/}
    destination_skill_dir=$destination/$skill_name

    if same_dir "$skill_dir" "$destination_skill_dir"; then
      warn "Pulando $skill_name porque origem e destino sao o mesmo diretorio"
      continue
    fi

    cp -R "$skill_dir" "$destination/"
    copied_count=$((copied_count + 1))
    success "Skill copiada: $skill_name"
  done

  if [ "$copied_count" -eq 0 ]; then
    die "Nenhuma skill elegivel foi encontrada para copiar"
  fi

  success "Instalacao concluida com $copied_count skill(s)"
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
CURRENT_DIR=$PWD
CURRENT_DIR_NAME=${CURRENT_DIR##*/}
CURRENT_REPO_ROOT=$(find_repo_root "$CURRENT_DIR")
INSTALL_TARGET=''
TARGET_KIND=''

if [ -n "$TARGET_PATH" ]; then
  INSTALL_TARGET=$(expand_path "$TARGET_PATH")
  TARGET_KIND=explicit
  info "Destino definido via --path: $INSTALL_TARGET"
elif [ "$USE_GLOBAL" -eq 1 ]; then
  INSTALL_TARGET=$GLOBAL_TARGET
  TARGET_KIND=global
  info "Flag --global detectada; usando instalacao global como primeira escolha"
elif [ "$CURRENT_DIR_NAME" = "skills" ]; then
  INSTALL_TARGET=$CURRENT_DIR
  TARGET_KIND=cwd-skills
  info "Diretorio atual termina com skills; instalando no local atual"
elif [ -n "$CURRENT_REPO_ROOT" ]; then
  INSTALL_TARGET=$CURRENT_REPO_ROOT/.agents/skills
  TARGET_KIND=repo-local
  info "Repositorio git detectado em $CURRENT_REPO_ROOT"
else
  INSTALL_TARGET=$GLOBAL_TARGET
  TARGET_KIND=global-fallback
  warn "Nenhum repo git detectado e a pasta atual nao parece ser skills"
fi

case "$TARGET_KIND" in
  explicit|cwd-skills)
    ;;
  repo-local)
    if [ "$YES" -eq 1 ]; then
      info "Flag --yes aplicada; aprovando instalacao local em $INSTALL_TARGET"
    elif ! confirm "Instalar as skills em $INSTALL_TARGET?"; then
      die "Instalacao cancelada pelo usuario"
    fi
    ;;
  global|global-fallback)
    if [ "$YES" -eq 1 ]; then
      warn "A flag --yes nao pula confirmacao para instalacao global"
    fi

    if ! confirm "Instalar as skills globalmente em $INSTALL_TARGET?"; then
      die "Instalacao global cancelada pelo usuario"
    fi
    ;;
  *)
    die "Nao foi possivel determinar um destino de instalacao"
    ;;
esac

copy_skills "$INSTALL_TARGET"
