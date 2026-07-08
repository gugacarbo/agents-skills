# Task-A-2: Implementar verifyToken com testes unitários

**Status:** ✅ completed
**Batch:** A (foundation)
**Subagent:** Quick (cheap/fast model)
**Try:** 1/3

## Summary

Implementada a função `verifyToken` em `src/middleware/auth.ts` com 5 testes unitários cobrindo todos os edge cases.

## Files Changed

| File                          | Action  |
| ----------------------------- | ------- |
| `src/middleware/auth.ts`      | created |
| `src/middleware/auth.test.ts` | created |

## Implementation Notes

- `verifyToken` usa `jwt.verify` com `algorithms: ['HS256']` fixo
- Validação adicional: payload deve conter `sub` (userId) e `role`
- Erros do `jsonwebtoken` (`TokenExpiredError`, `JsonWebTokenError`) são relançados como `Error` genérico para não vazar detalhes
- `JWT_SECRET` de `process.env` com fallback `'test-secret'` para ambiente de teste

## Test Cases (5/5 passing)

1. ✅ Token válido retorna payload com sub e role
2. ✅ Token expirado lança erro
3. ✅ Token com assinatura inválida lança erro
4. ✅ Payload sem `sub` lança erro
5. ✅ Payload sem `role` lança erro

## Verification

```bash
$ npx vitest run src/middleware/auth.test.ts
✓ src/middleware/auth.test.ts (5 tests) 12ms
Tests  5 passed (5)
```

## Blockers / Open Questions

Nenhum.
