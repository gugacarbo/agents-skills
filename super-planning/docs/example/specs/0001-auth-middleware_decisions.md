---
status: accepted
date: 2026-07-04
source-phase: brainstorm
related-spec: docs/specs/0001-auth-middleware-spec.md
---

# Decisions for Auth Middleware

> Este arquivo captura as decisões produzidas durante o Phase 1 brainstorming.
> Ele é opcional — foi criado porque o usuário pediu um registro durável antes da spec.

## Summary

Implementar um middleware de autenticação JWT para a API Express existente. O middleware valida tokens, extrai claims e injeta `req.user`. A decisão central foi entre usar Passport.js (mais pesado, mais funcionalidades) vs. uma implementação enxuta com `jsonwebtoken` direto (mais leve, menos dependências).

## Chosen Approach

**Implementação enxuta com `jsonwebtoken` direto**, sem Passport.js.

- A API já usa `jsonwebtoken` para gerar tokens no endpoint de login
- Passport.js adicionaria ~15 dependências transitivas sem necessidade imediata
- O escopo é apenas verificação JWT + controle de role — não precisamos de OAuth, SAML, etc.
- Se no futuro houver necessidade de múltiplas estratégias, migrar para Passport será um refactor isolado

## Requirements Shaping These Decisions

- Tokens JWT já são emitidos pelo endpoint `POST /auth/login`
- O payload contém `{ userId: string, role: 'admin' | 'user' }`
- Rotas protegidas precisam de `req.user` populado
- Rotas admin precisam verificar `role === 'admin'`

## Constraints

- Node.js ≥ 18 (já é o mínimo do projeto)
- TypeScript strict mode
- Não quebrar os testes de integração existentes
- Manter compatibilidade com o logger existente (`pino`)

## Assumptions

- O segredo JWT (`JWT_SECRET`) já está disponível via `process.env`
- O algoritmo de assinatura é HS256 (padrão do `jsonwebtoken`)
- Não há necessidade de refresh token neste escopo
- O token NÃO contém informações sensíveis além de userId e role

## Non-Goals

- Emissão de tokens (já existe em `POST /auth/login`)
- Refresh tokens
- Blacklist de tokens
- OAuth / social login
- Rate limiting (já existe em outro middleware)

## Risks and Tradeoffs

- **Risco:** Sem Passport, migrar para múltiplas estratégias no futuro exige refactor. **Mitigação:** A interface `AuthUser` é genérica o suficiente para ser reutilizada.
- **Risco:** Implementação manual de verificação pode ter bugs de segurança. **Mitigação:** Usamos `jsonwebtoken.verify` que é battle-tested; testes cobrem edge cases (token expirado, assinatura inválida, payload malformado).

## Alternatives Considered

| Option                                        | Why it was not chosen                                                             |
| --------------------------------------------- | --------------------------------------------------------------------------------- |
| Passport.js + passport-jwt                    | Muitas dependências para o escopo atual; overkill                                 |
| `express-jwt`                                 | Deprecated; comunidade migrou para alternativas                                   |
| Middleware como serviço externo (API Gateway) | Adiciona latência e ponto único de falha; não justifica para o tamanho do projeto |

## Open Questions

- [x] ~~Qual algoritmo de assinatura usar?~~ → HS256 (já usado no login)
- [x] ~~Onde colocar os tipos?~~ → `src/types/auth.ts`
- [ ] Nenhuma pendente

## Carry Forward to Spec

- [x] Interface `AuthUser = { userId: string; role: 'admin' | 'user' }`
- [x] Dois middlewares: `requireAuth` (autenticação) e `requireRole` (autorização)
- [x] Respostas de erro: 401 para auth, 403 para role
- [x] Tipos em `src/types/auth.ts`
- [x] Implementação em `src/middleware/auth.ts`
