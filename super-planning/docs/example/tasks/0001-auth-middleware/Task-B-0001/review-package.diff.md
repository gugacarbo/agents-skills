# Review Package: Task-B-0001

- **Task:** Task-B-0001 — Implementar middleware requireAuth
- **Plan:** 0001-auth-middleware
- **Base:** main
- **Head:** feature/0001-auth-middleware
- **Commit range:** `ghi9012..jkl3456`

## Commits

```
jkl3456 feat(auth): implement requireAuth middleware with tests
```

## Diff Stat

```
 src/middleware/auth.ts      | 22 +++++++++++++++++++++-
 src/middleware/auth.test.ts | 48 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 69 insertions(+), 1 deletion(-)
```

## Review Notes

✅ Extrai token corretamente com `header.slice(7)` após validar prefixo
✅ Header ausente e mal formatado têm mensagens de erro distintas
✅ Erro de verificação logado com `pino` antes de retornar 401 genérico
✅ `req.user` populado com `userId` e `role` do payload
✅ Testes cobrem todos os branches do middleware
✅ Não reimplementa `verifyToken` — reusa da Task-A-0002

**Veredict:** APPROVED — sem alterações necessárias.
