# Task-B-1: Implementar middleware requireAuth

**Status:** ✅ completed
**Batch:** B (core)
**Subagent:** General (standard model)
**Try:** 1/3

## Summary

Implementado o middleware `requireAuth` que extrai o token Bearer do header `Authorization`, chama `verifyToken`, e popula `req.user`. Adicionados 4 testes para edge cases de header.

## Files Changed

| File                          | Action                              |
| ----------------------------- | ----------------------------------- |
| `src/middleware/auth.ts`      | modified (adicionado `requireAuth`) |
| `src/middleware/auth.test.ts` | modified (adicionados 4 testes)     |

## Implementation Notes

- Extrai token do header `Authorization: Bearer <token>`
- Header ausente → 401 `{ error: "Missing authorization header" }`
- Header sem prefixo `Bearer ` → 401 `{ error: "Invalid authorization format" }`
- Token válido → popula `req.user = { userId: payload.sub, role: payload.role }` e chama `next()`
- Token inválido → loga erro com `pino` (`req.log.error`) e retorna 401 genérico
- Usa `verifyToken` da Task-A-2 — sem reimplementação

## Test Cases (4/4 new, 9/9 total)

6. ✅ Header ausente retorna 401
7. ✅ Header sem prefixo Bearer retorna 401
8. ✅ Token válido popula req.user e chama next()
9. ✅ Token inválido retorna 401

## Verification

```bash
$ npx vitest run src/middleware/auth.test.ts
✓ src/middleware/auth.test.ts (9 tests) 18ms
Tests  9 passed (9)
```

## Blockers / Open Questions

Nenhum.
