# Exemplo Completo: Auth Middleware

Este diretório contém um exemplo completo de ponta a ponta do fluxo **super-planning**, simulando a implementação de um middleware de autenticação JWT para uma API Express.

## O que este exemplo demonstra

Cada fase do super-planning está representada com artefatos reais:

| Fase           | Artefato               | Arquivo                                                                                                              |
| -------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1 — Brainstorm | Decisões de design     | [`specs/0001-auth-middleware_decisions.md`](specs/0001-auth-middleware_decisions.md)                                 |
| 2 — Spec       | Contrato com o usuário | [`specs/0001-auth-middleware-spec.md`](specs/0001-auth-middleware-spec.md)                                           |
| 3 — Plan       | Plano de implementação | [`plans/0001-auth-middleware.md`](plans/0001-auth-middleware.md)                                                     |
| 4 — Decompose  | Registro estruturado   | [`jobs/0001-auth-middleware/super-plan.json`](jobs/0001-auth-middleware/super-plan.json)                           |
| 4 — Decompose  | Ledger de progresso    | [`jobs/0001-auth-middleware/progress-ledger.md`](jobs/0001-auth-middleware/progress-ledger.md)                     |
| 5 — Dispatch   | Prompt do worker       | [`jobs/0001-auth-middleware/Task-A-1/worker-prompt.md`](jobs/0001-auth-middleware/Task-A-1/worker-prompt.md) |
| 6 — Review     | Reports e reviews      | `jobs/0001-auth-middleware/Task-*/report.md` e `review-package.diff.md`                                             |
| 6 — Review     | Logs de progresso      | `jobs/0001-auth-middleware/Task-*/progress.log`                                                                     |

## Feature simulada

**Auth Middleware** — Middleware Express que valida tokens JWT, extrai claims do usuário, e injeta `req.user` para uso nas rotas downstream.

### Escopo

- Validar token JWT do header `Authorization: Bearer <token>`
- Extrair `userId` e `role` do payload
- Responder 401 para token ausente, expirado ou inválido
- Responder 403 quando `role` não tem permissão para a rota
- Expor `req.user = { userId, role }` para handlers downstream

### Tech Stack

- Node.js + Express
- `jsonwebtoken` para verificação
- TypeScript

### Tarefas

| Task        | Batch | Phase      | Descrição                                                    |
| ----------- | ----- | ---------- | ------------------------------------------------------------ |
| Task-A-1 | A     | foundation | Tipos e interfaces (`JwtPayload`, `AuthUser`, `AuthOptions`) |
| Task-A-2 | A     | foundation | Função `verifyToken` + testes                                |
| Task-B-1 | B     | core       | Middleware `requireAuth`                                     |
| Task-B-2 | B     | core       | Middleware `requireRole`                                     |
| Task-C-1 | C     | surface    | Integração em `app.ts` + testes de integração                |

### Modo de execução

- **Modo:** Sequencial (tarefas dependentes)
- **Review cadence:** `per_task`
- **Branch:** `feature/0001-auth-middleware` a partir de `main`
