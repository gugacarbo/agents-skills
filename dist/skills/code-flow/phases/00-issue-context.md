# Fase 0: Contexto da issue

Use esta fase para `/code-flow issue`, `/code-flow batch` e `/code-flow issue create`.
Fases `plan` / `dispatch` / `review` / `integrate` exigem uma issue elegível;
sem issue, oriente para `issue create`.

Para `issue create`, estabeleça o contexto do pedido antes da Fase 1: resolva o
repositório/branch default, carregue guidance aplicável e ADRs/specs aceitos,
inspecione a área estreita de código/teste e registre a evidência de baseline.
Ainda não há alvo de entrega no GitHub, então não valide labels nem crie estado
GitHub nesta fase. A Fase 2 cria a issue de entrega aprovada ou, quando o
usuário selecionou explicitamente durante o triage de iniciativa, seu Epic de
tracking.

## Validar antes do dispatch

Para alvos issue/batch existentes:

1. Confirme que cada alvo é uma issue de entrega/bug existente, não umbrella, auditoria ou tracking. Esta checagem de elegibilidade vem antes de qualquer reparo de label.
2. Se for inelegível, explique que está fora deste fluxo de entrega e pare sem adicionar, remover ou substituir labels.
3. Leia body, labels, PRs ligados e comentários anteriores de evidência (oito campos), plano e review de uma issue elegível.
4. Liste toda label `stage:*`. Exatamente um stage de `references/github-flow.md` é necessário para uma issue elegível retomável; `needs-human` é ortogonal. O resume segue a tabela de `references/github-flow.md` e o cheatsheet em `references/orchestrator-cheatsheet.md` (labels são a fonte de verdade; não inferir stage só do texto do comentário).
5. Resolva o branch default do repositório e inspecione paths de ADR/spec ligados nos commits registrados.
6. Para batch, retenha uma visão efêmera de dispatch por issue: URL, stage atual, ciclo de plano ativo, links de fontes, blockers e próxima fase. Não escrever arquivo de estado ou registry.

## Tratamento de drift

Só para issue elegível, aplique `stage:blocked` + `needs-human` e pare a issue
afetada quando qualquer um destes for verdadeiro:

- zero ou múltiplas labels `stage:*`;
- um comentário de plano/review ou envelope de evidência obrigatório conflita com o stage ou não tem ciclo/escopo identificável;
- `stage:approved` carece de review aprovadora literal e evidência de aprovação humana do snapshot atual do plano;
- `stage:in-progress` ou `stage:needs-changes` tem evidência `BLOCKED` ou evidência de implementação que não corresponde ao plano atual;
- `stage:needs-delivery-review` carece de evidência não bloqueada do executor para o plano aprovado;
- `stage:ready-to-merge` carece de review aprovadora da implementação para o range atual.

Nunca reparar drift inferindo aprovação de histórico, PR ou claim do implementador.
Não aplicar stage de entrega como atalho para issue inelegível. Uma issue
bloqueada não para issues de batch não relacionadas.
