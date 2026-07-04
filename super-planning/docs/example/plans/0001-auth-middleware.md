# Auth Middleware Implementation Plan

> **For agentic workers:** Use subagent-driven development to implement this plan task-by-task.
> The executable source of truth is `docs/tasks/0001-auth-middleware/super-plan.json`.

**Goal:** Implementar middleware Express de autenticação JWT com validação de token e controle de role.

**Architecture:** Dois middlewares independentes (`requireAuth`, `requireRole`) que compõem em cadeia no Express. `requireAuth` valida o token e popula `req.user`; `requireRole` verifica permissões. A função `verifyToken` é extraída para teste isolado. Tipos centralizados em `src/types/auth.ts`.

**Tech Stack:** Node.js ≥ 18, TypeScript strict, Express, `jsonwebtoken`, `vitest`

## Global Constraints

- Node.js ≥ 18
- TypeScript strict mode (`strict: true` no tsconfig)
- Não adicionar novas dependências além de `jsonwebtoken` e `@types/jsonwebtoken` (já presentes)
- Manter compatibilidade com logger `pino` existente
- Mensagens de erro não devem vazar detalhes de implementação
- Algoritmo fixo: HS256
- `JWT_SECRET` via `process.env.JWT_SECRET`

## File Structure

| File/Directory | Owner Task | Notes |
| -------------- | ---------- | ----- |
| `src/types/auth.ts` | `Task-A-0001` | Interfaces `JwtPayload`, `AuthUser`, `AuthOptions` |
| `src/middleware/auth.ts` | `Task-B-0001`, `Task-B-0002` | `verifyToken`, `requireAuth`, `requireRole` |
| `src/middleware/auth.test.ts` | `Task-A-0002`, `Task-B-0001`, `Task-B-0002` | Testes unitários (12 casos) |
| `src/app.ts` | `Task-C-0001` | Integração dos middlewares nas rotas |
| `src/app.integration.test.ts` | `Task-C-0001` | Testes de integração (3 casos) |

## Structured Registry

- **Registry:** `docs/tasks/0001-auth-middleware/super-plan.json`
- **Progress ledger:** `docs/tasks/0001-auth-middleware/progress-ledger.md`
- **Task directories:** `docs/tasks/0001-auth-middleware/<task-id>/`
- **Task-local logs:** `docs/tasks/0001-auth-middleware/<task-id>/progress.log`
- **Task-local logger:** `docs/tasks/0001-auth-middleware/<task-id>/log-task.sh`

---
