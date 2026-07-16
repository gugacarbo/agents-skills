---
status: accepted
date: 2026-07-15
builds-on: []
implemented-by: []
---

# Code-flow coordena entregas com seis agentes e evidência por comentário

## Objetivo

Reduzir a topologia da `code-flow` a seis papéis explícitos, mantendo os
gates humanos e a revisão independente. Toda execução de agente deve deixar
evidência append-only no artefato durável da entrega: um comentário na issue
no modo issue, ou uma seção equivalente no delivery record no modo repositório
direto.

## Fluxo

1. O orquestrador coleta as decisões necessárias do usuário e controla apenas
   dispatch, labels e gates; não escreve plano, não revisa e não implementa.
2. O `issue-writer` investiga o contexto, decide o impacto de spec, cria ou
   atualiza ADR/spec quando necessário e, depois das decisões do usuário,
   cria a delivery issue. Ele registra nela o source set e o resumo da sua
   execução.
3. O `issue-reviewer`, um agente independente, revisa a issue e o source set
   e publica seu parecer. Ambos permanecem em `stage:spec-approval`; somente
   a aprovação humana do source set permite a transição para `stage:needs-plan`.
4. O `plan-writer` publica um plano único (sem decomposição em task IDs); um
   `plan-reviewer` independente publica o veredito do ciclo. As transições
   atuais de plano continuam aplicáveis; aprovação humana do snapshot é
   gate separado.
5. O `executor` implementa o plano aprovado como uma unidade. Ele substitui
   os perfis `general-executor` e `deep-executor`; a profundidade acompanha
   o escopo do plano, sem criar outro papel nem lista de task IDs.
6. Um `delivery-reviewer` fresco revisa a implementação e também executa a
   auditoria final de contrato, DoD e evidências. A instância da auditoria
   final deve ser distinta da que revisou a implementação.
7. Após aprovação da PR, integração/merge continua uma ação opcional e
   explicitamente confirmada pelo usuário.

## Contrato

### Papéis permitidos

O pacote expõe exatamente estes agentes, com estes nomes ASCII:

| Agente              | Responsabilidade                                                                                                        |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `issue-writer`      | Investigação, gate de ADR/spec condicional, consolidação das decisões do usuário, criação da issue e evidência inicial. |
| `issue-reviewer`    | Revisão independente da issue e do source set; não aprova em nome do humano.                                            |
| `plan-writer`       | Plano de implementação append-only (uma unidade), com evidência de origem.                                              |
| `plan-reviewer`     | Veredito independente e literal sobre o plano.                                                                          |
| `executor`          | Implementação do plano aprovado como uma unidade, com evidência, em worktree no modo issue.                             |
| `delivery-reviewer` | Revisão da implementação e auditoria final de contrato, DoD e evidência de fechamento.                                  |

Nenhum dos seguintes agentes ou papéis permanece exposto: `investigator`,
`spec-author`, `general-executor`, `deep-executor`, `code-reviewer`,
`spec-compliance-auditor` ou `spec-document-reviewer`.

O `issue-writer` só cria uma issue depois de as decisões de produto pendentes
serem fornecidas pelo usuário. Para mudança de contrato, comportamento
observável ou decisão durável, ele prepara a ADR/spec; para mudança interna,
registra a justificativa concreta de `Spec impact: not required`. A revisão do
`issue-reviewer` pode apontar correções, mas não substitui a aprovação humana
requerida para o source set.

### Evidência por execução

No modo issue, cada invocação bem-sucedida dos seis agentes publica um novo
comentário append-only na issue. O `issue-writer` publica seu comentário logo
após criar a issue; portanto, não há uma execução de `issue-writer` em modo
issue antes de a issue existir. Cada comentário contém, nesta ordem:

```text
Agent: <nome do agente>
Phase/scope: <fase, ciclo, range ou auditoria>
Summary: <resultado conciso>
Sources/evidence: <links imutáveis, issue/PR, commits, comandos ou saída>
Decisions: <decisões aplicadas, pendentes ou "none">
Changes/validation: <arquivos/efeito e validação, ou "none">
Blockers: <bloqueio e decisão humana necessária, ou "none">
Next action: <ação e responsável>
```

No modo repositório direto, não há issue, labels nem comentários GitHub. Cada
invocação dos mesmos papéis acrescenta uma seção append-only com os mesmos
campos ao delivery record versionado. A ausência de mudança de arquivos não
dispensa o comentário/seção: investigação, revisão, no-spec, aprovação e
bloqueio também são resultados que precisam de evidência.

### Independência e estado

`plan-writer` e `plan-reviewer` são sempre agentes distintos. O
`delivery-reviewer` da implementação é distinto do `plan-writer` e do
`executor`. A instância usada para a auditoria final deve ser fresh e não
pode ter feito a review da implementação; ela também é distinta do
`plan-writer` e do `executor`. O orquestrador preserva as demais regras de
isolamento de worktree e paralelismo entre issues.

Não são criadas labels novas. `issue-writer` e `issue-reviewer` trabalham sob
`stage:spec-approval` com `needs-human` até a aprovação humana do source set.
Depois disso, a sequência continua:

```text
stage:spec-approval → stage:needs-plan → stage:needs-plan-review
→ stage:approved → stage:in-progress → stage:needs-delivery-review
→ stage:ready-to-merge (ou stage:needs-changes → executor → needs-delivery-review)
→ aprovação de PR → integração opcional confirmada → fechamento
```

Rejeições, saída sem veredito, decisão humana pendente, falha de evidência ou
implementação bloqueada usam as regras existentes de `stage:blocked` e
`needs-human`. O modo `direct` permanece exclusivo do modo repositório e nunca
cria uma issue ou estado GitHub.

## Casos de borda

| #   | QUANDO ⟨gatilho⟩                                                       | o sistema DEVE ⟨resposta⟩                                                                                            |
| --- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1   | uma decisão de produto ainda não foi dada                              | o `issue-writer` pede a decisão e não cria a issue nem improvisa o source set.                                       |
| 2   | a mudança altera contrato, comportamento observável ou decisão durável | o `issue-writer` cria/atualiza ADR/spec e a issue inicia em `stage:spec-approval` + `needs-human`.                   |
| 3   | a mudança é interna                                                    | o `issue-writer` registra a justificativa de spec não necessária, e o gate humano continua em `stage:spec-approval`. |
| 4   | o `issue-reviewer` aprova o source set                                 | a issue continua em `stage:spec-approval`; só a aprovação humana a move para `stage:needs-plan`.                     |
| 5   | um agente conclui sem mudanças de código                               | ele ainda publica o comentário/seção com todos os campos de evidência.                                               |
| 6   | há modo repositório `direct`                                           | cada agente escreve no delivery record, sem criar issue, label ou comentário GitHub.                                 |
| 7   | há review da implementação e auditoria final                           | duas instâncias fresh de `delivery-reviewer` são usadas, respeitando as restrições de independência.                 |
| 8   | a implementação está bloqueada ou uma revisão é inválida               | o agente registra o bloqueio e próximo passo; o orquestrador aplica o gate existente e não avança.                   |

## Questões em aberto

Nenhuma. A topologia, o contrato de evidência e os gates humanos foram
aprovados para implementação.

## Definition of Done

- [ ] O pacote fonte e `dist/` expõem somente os seis arquivos/agentes
      permitidos e nenhuma rota, referência, template ou teste nomeia os
      papéis removidos.
- [ ] O router e as fases atribuem investigação, gate condicional de spec e
      criação da issue ao `issue-writer`, e preservam a revisão independente
      do `issue-reviewer` em `stage:spec-approval`.
- [ ] Os templates e referências exigem os oito campos de comentário para
      toda execução no modo issue e a seção equivalente no delivery record
      do modo repositório direto.
- [ ] Os testes estruturais cobrem os casos 1 a 8, inclusive: nenhuma label
      nova, issue-reviewer sem autoaprovação humana, um único executor,
      delivery-reviewer fresh na auditoria final e direct sem GitHub.

```bash
pnpm test
pnpm build
bash skills/code-flow/dev/tests.sh
python3 scripts/docs-check
```

## Revisão humana

- Aprovar o source set da issue (ADR/spec aceita ou justificativa de spec não
  necessária) antes de liberar o plano.
- Confirmar a integração/merge opcional depois da PR aprovada.

## Verificação

```text
Aprovada pelo usuário em 2026-07-15; implementação e evidência de fechamento pendentes.
```
