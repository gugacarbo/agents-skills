#!/usr/bin/env bash
# scripts/lib/shared.sh — funções compartilhadas entre scripts do repositório.
# Uso: source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/shared.sh"

# Detecta o runtime e gerenciador de pacotes suportado pelo workspace.
# Define a variável BUN_RUNNER com o nome do comando.
detect_runner() {
  if command -v bun > /dev/null 2>&1; then
    BUN_RUNNER="bun"
  else
    echo "Erro: Bun não encontrado." >&2
    exit 1
  fi
}

# Retorna o caminho absoluto da raiz do repositório via git.
# Funciona independentemente de onde o script chamador está localizado.
repo_root() {
  git rev-parse --show-toplevel
}
