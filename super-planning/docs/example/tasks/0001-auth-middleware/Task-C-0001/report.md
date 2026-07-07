# Task-C-0001: Integrar middlewares nas rotas e testes de integração

**Status:** ✅ completed
**Batch:** C (surface)
**Subagent:** General (standard model)
**Try:** 1/3

## Summary

Integrados os middlewares `requireAuth` e `requireRole` nas rotas existentes de `src/app.ts`. Escritos 3 testes de integração com `supertest`.

## Files Changed

| File                          | Action                                       |
| ----------------------------- | -------------------------------------------- |
| `src/app.ts`                  | modified (adicionados middlewares nas rotas) |
| `src/app.integration.test.ts` | created                                      |

## Implementation Notes

- Rota `GET /api/profile` protegida com `requireAuth` (qualquer role)
- Rota `GET /api/admin/users` protegida com `requireAuth` + `requireRole('admin')`
- Testes de integração usam `supertest` com tokens JWT reais
- Tokens gerados com `jsonwebtoken.sign` usando `JWT_SECRET` de teste

## Test Cases (3/3 passing)

1. ✅ `GET /api/profile` sem token → 401
2. ✅ `GET /api/admin/users` com role=user → 403
3. ✅ `GET /api/admin/users` com role=admin → 200

## Verification

```bash
$ npx tsc --noEmit && npx vitest run && npx vitest run --integration
# tsc: exit 0
# unit tests: 12/12 passing
# integration tests: 3/3 passing
```

## Blockers / Open Questions

Nenhum. Feature completa.
