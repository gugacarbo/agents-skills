# Cheatsheet do orquestrador

1. Faça discovery e recalcule Complexity/risco.
   Para criação em batch, mantenha cada pré-issue como Project V2
   `DRAFT_ISSUE` até o issue-writer completar o body e uma promoção autorizada
   por issue-writer ou orquestrador.
2. Conte `stage:*`: um é fallback; zero exige mapeamento nativo; múltiplos são
   drift bloqueante.
3. Se native passar, use-o automaticamente nesta entrada; se falhar em issue
   nova, inicie fallback equivalente; se falhar em header legado native, pause
   para decisão humana.
4. Valide relatório de arquitetura, base e autoria antes de despachar.
   Descubra capacidades de runtime/modelo sem escrever configuração no repo.
5. Evidência precede mutação; agente muta o próprio resultado e orquestrador
   muta decisão humana.
6. Em revisão de relatório de arquitetura, confirme a mesma URL/ID do comentário
   canônico editado e um novo comentário curto de alterações; uma nova cópia
   integral é drift.

## Check rápido

- Header legado foi tratado como compatibilidade, não como estado autoritativo?
- Relatório de arquitetura digest foi calculado somente entre marcadores?
- Hard trigger, escopo ou base mudaram desde o último gate?
- Próximo ator é humano? Só então `needs-human` pode existir.
- `NO_CHANGES` usa close gate, nunca merge gate.
- Em batch, cada ID permanece independente e `--from` não pula gates.
- Batch de pré-issues exige Project V2; nunca use repository issue aberta ou
  label `draft` como substituto.
- Correção de relatório de arquitetura edita o comentário canônico; não acumule
  relatórios completos.
- `/code-flow stop` publica handoff e só limpa labels fallback após decisão
  humana; não fecha issue nem descarta trabalho.
