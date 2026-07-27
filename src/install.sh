#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
SKILLS_REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd -P
)
SKILLS_SOURCE_DIR=$SKILLS_REPO_ROOT/dist/skills

AGENTS_SKILLS_OWNER=${AGENTS_SKILLS_OWNER:-gugacarbo}
AGENTS_SKILLS_REPO=${AGENTS_SKILLS_REPO:-agents-skills}
AGENTS_SKILLS_REF=${AGENTS_SKILLS_REF:-main}
AGENTS_SKILLS_REPO_URL=${AGENTS_SKILLS_REPO_URL:-https://github.com/$AGENTS_SKILLS_OWNER/$AGENTS_SKILLS_REPO.git}

YES=0
USE_GLOBAL=0
USE_INIT=0
USE_INSTRUCTIONS=0
USE_FRESH=0
TARGET_PATH=''
SELECTED_SKILLS=''

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
  IFS= read -r reply < "$1"
}

usage() {
  cat << 'EOF'
Uso: ./src/install.sh [opções] [SKILL...]

Opções:
  -p, --path PATH   Instala as skills no PATH informado
  -g, --global      Usa ~/.agents/skills como primeira escolha
      --init        Clona o repositório de skills no destino (em vez de copiar)
      --instructions  Copia README.md do repositório para o destino
      --fresh       Remove as skills existentes no destino antes de instalar
  -y, --yes         Aprova automaticamente apenas a instalação local do repo
  -h, --help        Mostra esta ajuda

Argumentos:
  SKILL...          Instala somente uma ou mais skills especificas
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

confirm() {
  prompt_message=$1
  prompt_input=${AGENTS_SKILLS_PROMPT_INPUT:-/dev/tty}

  printf '%s %s [y/N]: ' "$(color 36 '[PROMPT]')" "$prompt_message"

  if read_reply_from "$prompt_input" 2> /dev/null; then
    :
  elif ! IFS= read -r reply; then
    printf '\n'
    return 1
  fi

  case "$reply" in
    y | Y | yes | YES | Yes)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

add_selected_skill() {
  skill_name=$1

  case "$skill_name" in
    '' | .* | */* | *[!a-z0-9_-]*)
      die "Nome de skill inválido: $skill_name"
      ;;
  esac

  case "
$SELECTED_SKILLS
" in
    *"
$skill_name
"*)
      return 0
      ;;
  esac

  if [ -z "$SELECTED_SKILLS" ]; then
    SELECTED_SKILLS=$skill_name
  else
    SELECTED_SKILLS="$SELECTED_SKILLS
$skill_name"
  fi
}

validate_selected_skills() {
  [ -n "$SELECTED_SKILLS" ] || return 0
  [ -d "$SKILLS_SOURCE_DIR" ] || die "Skills geradas não encontradas em $SKILLS_SOURCE_DIR. Execute ./skills.sh build antes de instalar."

  for skill_name in $SELECTED_SKILLS; do
    skill_dir=$SKILLS_SOURCE_DIR/$skill_name
    [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || die "Skill não encontrada: $skill_name"
  done
}

copy_skill_dir() {
  source_skill_dir=$1
  destination=$2
  skill_name=${source_skill_dir##*/}
  destination_skill_dir=$destination/$skill_name

  if same_dir "$source_skill_dir" "$destination_skill_dir"; then
    warn "Pulando $skill_name porque origem e destino são o mesmo diretório"
    return 0
  fi

  cp -R "$source_skill_dir" "$destination/"
  copied_count=$((copied_count + 1))
  success "Skill copiada: $skill_name"
}

copy_skills() {
  destination=$1
  copied_count=0

  mkdir -p "$destination"
  info "Instalando skills em $destination"

  [ -d "$SKILLS_SOURCE_DIR" ] || die "Skills geradas não encontradas em $SKILLS_SOURCE_DIR. Execute ./skills.sh build antes de instalar."

  if [ -n "$SELECTED_SKILLS" ]; then
    for skill_name in $SELECTED_SKILLS; do
      copy_skill_dir "$SKILLS_SOURCE_DIR/$skill_name" "$destination"
    done
  else
    for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
      [ -d "$skill_dir" ] || continue
      [ -f "$skill_dir/SKILL.md" ] || continue

      copy_skill_dir "$skill_dir" "$destination"
    done
  fi

  if [ "$copied_count" -eq 0 ]; then
    die "Nenhuma skill elegível foi encontrada para copiar"
  fi

  success "Instalação concluída com $copied_count skill(s)"
}

remove_installed_skills() {
  destination=$1
  removed_count=0

  [ -d "$destination" ] || return 0

  if same_dir "$SKILLS_SOURCE_DIR" "$destination"; then
    die "--fresh não pode usar o diretório-fonte de skills como destino"
  fi

  if [ -n "$SELECTED_SKILLS" ]; then
    for skill_name in $SELECTED_SKILLS; do
      skill_dir=$destination/$skill_name
      [ -d "$skill_dir" ] || continue
      [ -f "$skill_dir/SKILL.md" ] || continue

      rm -rf "$skill_dir"
      removed_count=$((removed_count + 1))
      info "Skill removida: $skill_name"
    done
  else
    for skill_dir in "$destination"/* "$destination"/.[!.]* "$destination"/..?*; do
      [ -d "$skill_dir" ] || continue
      [ -f "$skill_dir/SKILL.md" ] || continue

      skill_name=${skill_dir##*/}
      rm -rf "$skill_dir"
      removed_count=$((removed_count + 1))
      info "Skill removida: $skill_name"
    done
  fi

  info "--fresh removeu $removed_count skill(s) existente(s) de $destination"
}

copy_instructions() {
  destination=$1
  source_readme=$SKILLS_REPO_ROOT/README.md
  dest_readme=$destination/README.md

  [ -f "$source_readme" ] || die "README.md não encontrado em $SKILLS_REPO_ROOT"

  mkdir -p "$destination"

  if [ -e "$dest_readme" ]; then
    warn "README.md já existe em $destination; mantendo arquivo existente"
    return 0
  fi

  cp "$source_readme" "$dest_readme"
  success "README.md copiado para $destination"
}

dir_is_nonempty() {
  [ -d "$1" ] && [ -n "$(ls -A "$1" 2> /dev/null)" ]
}

merge_without_overwrite() {
  source_dir=$1
  destination_dir=$2

  mkdir -p "$destination_dir"

  if command -v rsync > /dev/null 2>&1; then
    rsync -a --ignore-existing "$source_dir/" "$destination_dir/"
    return 0
  fi

  if cp -Rn "$source_dir/." "$destination_dir/." 2> /dev/null; then
    return 0
  fi

  die "Não foi possível mesclar arquivos sem sobrescrever (instale rsync ou use cp GNU)"
}

merge_clone_into_nonempty() {
  destination=$1
  tmp_dir=$(mktemp -d)
  checkout_dir=$tmp_dir/checkout

  cleanup() {
    rm -rf "$tmp_dir"
  }

  trap cleanup EXIT INT TERM

  info "Clonando $AGENTS_SKILLS_REPO_URL (branch $AGENTS_SKILLS_REF) para mesclar em $destination"
  git clone --branch "$AGENTS_SKILLS_REF" --single-branch --depth 1 "$AGENTS_SKILLS_REPO_URL" "$checkout_dir"

  info "Mesclando arquivos do repositório em $destination sem sobrescrever existentes"
  merge_without_overwrite "$checkout_dir" "$destination"

  if [ ! -d "$destination/.git" ]; then
    cp -R "$checkout_dir/.git" "$destination/.git"
    success "Repositório git inicializado em $destination (arquivos existentes preservados na worktree)"
  else
    warn "Destino já possui .git; mantendo o repositório git existente"
    success "Arquivos do repositório de skills mesclados em $destination"
  fi
}

clone_skills_repo() {
  destination=$1

  command -v git > /dev/null 2>&1 || die "git é necessário para --init"

  if same_dir "$destination" "$SKILLS_REPO_ROOT"; then
    die "Destino igual ao repositório atual; use install sem --init para copiar skills"
  fi

  if dir_is_nonempty "$destination"; then
    if [ "$YES" -eq 1 ]; then
      info "Flag --yes aplicada; mesclando repositório em $destination mantendo arquivos existentes"
    elif ! confirm "Destino $destination já contém arquivos. Continuar mesclando o repositório de skills e mantendo os arquivos existentes na worktree?"; then
      die "Instalação cancelada pelo usuário"
    fi

    merge_clone_into_nonempty "$destination"
    return 0
  fi

  mkdir -p "$destination"

  info "Clonando $AGENTS_SKILLS_REPO_URL (branch $AGENTS_SKILLS_REF) em $destination"
  git clone --branch "$AGENTS_SKILLS_REF" --single-branch --depth 1 "$AGENTS_SKILLS_REPO_URL" "$destination"
  success "Repositório clonado em $destination"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p | --path)
      shift
      [ $# -gt 0 ] || die "A opção $0 requer um path após -p/--path"
      TARGET_PATH=$1
      ;;
    -g | --global)
      USE_GLOBAL=1
      ;;
    --init)
      USE_INIT=1
      ;;
    --instructions)
      USE_INSTRUCTIONS=1
      ;;
    --fresh)
      USE_FRESH=1
      ;;
    -y | --yes)
      YES=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage >&2
      die "Opção desconhecida: $1"
      ;;
    *)
      add_selected_skill "$1"
      ;;
  esac
  shift
done

if [ "$USE_INIT" -eq 1 ]; then
  info "Flag --init detectada; o destino será um git clone do repositório de skills"
fi

if [ "$USE_INIT" -eq 1 ] && [ "$USE_FRESH" -eq 1 ]; then
  die "--fresh não pode ser usado com --init"
fi

if [ "$USE_INIT" -eq 1 ] && [ -n "$SELECTED_SKILLS" ]; then
  die "A seleção de skills não pode ser usada com --init"
fi

validate_selected_skills

GLOBAL_TARGET=$(expand_path "~/.agents/skills")
CURRENT_DIR=$PWD
CURRENT_DIR_NAME=${CURRENT_DIR##*/}
INSTALL_TARGET=''
TARGET_KIND=''

if [ -n "$TARGET_PATH" ]; then
  INSTALL_TARGET=$(expand_path "$TARGET_PATH")
  TARGET_KIND=explicit
  info "Destino definido via --path: $INSTALL_TARGET"
elif [ "$USE_GLOBAL" -eq 1 ]; then
  INSTALL_TARGET=$GLOBAL_TARGET
  TARGET_KIND=global
  info "Flag --global detectada; usando instalação global como primeira escolha"
elif [ "$CURRENT_DIR_NAME" = "skills" ]; then
  INSTALL_TARGET=$CURRENT_DIR
  TARGET_KIND=cwd-skills
  info "Diretório atual termina com skills; instalando no local atual"
else
  INSTALL_TARGET=$GLOBAL_TARGET
  TARGET_KIND=global
  info "Diretório atual não termina com skills; usando o destino padrão global"
fi

case "$TARGET_KIND" in
  explicit | cwd-skills)
    ;;
  global)
    if [ "$YES" -eq 1 ]; then
      warn "A flag --yes não pula confirmação para instalação global"
    fi

    if ! confirm "Instalar as skills globalmente em $INSTALL_TARGET?"; then
      die "Instalação global cancelada pelo usuário"
    fi
    ;;
  *)
    die "Não foi possível determinar um destino de instalação"
    ;;
esac

if [ "$USE_INIT" -eq 1 ]; then
  clone_skills_repo "$INSTALL_TARGET"
else
  if [ "$USE_FRESH" -eq 1 ]; then
    remove_installed_skills "$INSTALL_TARGET"
  fi

  copy_skills "$INSTALL_TARGET"
fi

if [ "$USE_INSTRUCTIONS" -eq 1 ]; then
  copy_instructions "$INSTALL_TARGET"
fi
