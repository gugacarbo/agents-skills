# Task-A-0001: Definir tipos e interfaces de autenticação

**Status:** ✅ completed
**Batch:** A (foundation)
**Subagent:** Quick (cheap/fast model)
**Try:** 1/3

## Summary

Criado `src/types/auth.ts` com as interfaces `JwtPayload`, `AuthUser`, `AuthOptions` e o declaration merging do Express para `req.user`.

## Files Changed

| File                | Action  |
| ------------------- | ------- |
| `src/types/auth.ts` | created |

## Implementation Notes

- `JwtPayload` estende `JwtPayload` do `jsonwebtoken` adicionando `sub: string` e `role: 'admin' | 'user'`
- `AuthUser` é a interface pública exposta em `req.user`
- `AuthOptions` permite override de `secret` e `algorithms` (útil para testes)
- Declaration merging usa `declare global { namespace Express { interface Request { user?: AuthUser } } }`

## Verification

```bash
$ npx tsc --noEmit
# exit 0 — sem erros
```

## Blockers / Open Questions

Nenhum.
