# AGENTS.md (fixture para eval E5)

Este é um fixture de guidance local para validar nearest-wins discovery.

## Convenções

- **Commits:** sempre use Conventional Commits (`feat:`, `fix:`, `docs:`, etc.).
- **Merge:** sempre use squash merge. Nunca use merge commit ou rebase merge.
- **Branches:** nomeie como `<type>/<short-description>` (ex.: `feat/add-login`).
- **Testes:** todo PR deve passar `pnpm test` antes de merge.

## Workflow Git

1. Crie branch a partir de `main`.
2. Commits seguem Conventional Commits.
3. Abra PR com descrição clara.
4. Squash merge após aprovação.
