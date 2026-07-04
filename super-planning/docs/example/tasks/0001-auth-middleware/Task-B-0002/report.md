# Task-B-0002: Implementar middleware requireRole

**Status:** ✅ completed
**Batch:** B (core)
**Subagent:** General (standard model)
**Try:** 1/3

## Summary

Implementado o middleware `requireRole` como higher-order function que verifica se `req.user.role` está na lista de roles permitidas. Adicionados 3 testes.

## Files Changed

| File | Action |
|------|--------|
| `src/middleware/auth.ts` | modified (adicionado `requireRole`) |
| `src/middleware/auth.test.ts` | modified (adicionados 3 testes) |

## Implementation Notes

- Higher-order function: `requireRole(...roles: string[])` retorna um middleware `(req, res, next) => void`
- Se `req.user` é `undefined` (requireAuth não executado) → 401
- Se `req.user.role` não está em `roles` → 403 `{ error: "Insufficient permissions" }`
- Suporte a múltiplos roles: `requireRole('admin', 'moderator')`

## Test Cases (3/3 new, 12/12 total)

10. ✅ Role na lista permitida chama next()
11. ✅ Role fora da lista retorna 403
12. ✅ Múltiplos roles no parâmetro funcionam

## Verification

```bash
$ npx vitest run src/middleware/auth.test.ts
✓ src/middleware/auth.test.ts (12 tests) 22ms
Tests  12 passed (12)
```

## Blockers / Open Questions

Nenhum.
