---
status: accepted
date: 2026-07-04
builds-on:
  - docs/specs/0001-auth-middleware_decisions.md
implemented-by: []
---

# Middleware de autenticação JWT que valida tokens e injeta `req.user` nos handlers downstream

> Shared conventions: Este projeto usa TypeScript strict, Express com tipagem explícita, e `pino` para logging. Testes com `vitest`.

## Objective

Rotas protegidas da API recebem `req.user` populado automaticamente após validação do token JWT. Rotas que exigem role específico rejeitam requisições de usuários sem a permissão necessária.

## Flow

1. Cliente envia `Authorization: Bearer <token>` no header
2. `requireAuth` middleware extrai o token do header
3. Se ausente → 401 `{ error: "Missing authorization header" }`
4. `verifyToken(token)` decodifica e valida (expiração, assinatura, algoritmo)
5. Se inválido/expirado → 401 `{ error: "Invalid or expired token" }`
6. Payload válido → `req.user = { userId: payload.sub, role: payload.role }`
7. `requireRole('admin')` middleware (opcional) verifica `req.user.role`
8. Se role não corresponde → 403 `{ error: "Insufficient permissions" }`
9. Handler downstream acessa `req.user` tipado

## Contract

### `req.user` type

```ts
interface AuthUser {
  userId: string;
  role: 'admin' | 'user';
}
```

### `requireAuth` middleware

- **Input:** `Authorization` header com `Bearer <token>`
- **Output:** `req.user` populado ou erro 401
- **Header ausente:** 401 `{ error: "Missing authorization header" }`
- **Token inválido:** 401 `{ error: "Invalid or expired token" }`
- **Sucesso:** `next()` com `req.user` definido

### `requireRole(...roles: string[])` middleware

- **Input:** `req.user` (deve existir — usar após `requireAuth`)
- **Output:** `next()` ou erro 403
- **Role não autorizada:** 403 `{ error: "Insufficient permissions" }`
- **Sucesso:** `next()`

### `verifyToken(token: string): JwtPayload`

- **Input:** token JWT string
- **Output:** payload decodificado ou throw
- **Throws:** `JsonWebTokenError` | `TokenExpiredError` | `NotBeforeError`

## Edge cases

| # | WHEN ⟨trigger⟩ | the system MUST ⟨response⟩ |
|---|---------------|---------------------------|
| 1 | Header `Authorization` está ausente | Retornar 401 `{ error: "Missing authorization header" }` |
| 2 | Header `Authorization` não começa com `Bearer ` | Retornar 401 `{ error: "Invalid authorization format" }` |
| 3 | Token está expirado (`TokenExpiredError`) | Retornar 401 `{ error: "Invalid or expired token" }` |
| 4 | Token tem assinatura inválida | Retornar 401 `{ error: "Invalid or expired token" }` |
| 5 | Payload não contém `sub` (userId) | Retornar 401 `{ error: "Invalid token payload" }` |
| 6 | Payload não contém `role` | Retornar 401 `{ error: "Invalid token payload" }` |
| 7 | `requireRole` chamado sem `requireAuth` antes | `req.user` é `undefined` → 401 |
| 8 | `role` no token não está na lista permitida | Retornar 403 `{ error: "Insufficient permissions" }` |
| 9 | Token usa algoritmo diferente de HS256 | Rejeitar — `jsonwebtoken.verify` com `algorithms: ['HS256']` |

## Open questions

- [ ] Nenhuma pendente

## Definition of Done

```bash
npx tsc --noEmit                          # exit 0
npx vitest run src/middleware/auth.test.ts # 12/12 passing
npx vitest run --integration              # 3/3 integration tests passing
```

## Human review

- Revisar mensagens de erro — não devem vazar detalhes de implementação
- Confirmar que `JWT_SECRET` está no `.env.example` (não commitar segredos)

## Verification

```text
(fill in at close)
```
