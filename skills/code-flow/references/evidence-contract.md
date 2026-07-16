# Contrato de evidência

A evidência é append-only e não substitui ADRs/specs aceitos. Publique o
envelope antes de uma mudança de estado e então mutue as labels `stage:*` /
`needs-human` no mesmo turno (ver `references/github-flow.md`).
Mencionar um stage no comentário não é mudança de estado.

## Envelope

Todo resultado de todo papel usa estes campos nesta ordem, incluindo sem
mudança, `BLOCKED`, erros, evidência ausente e rejeições:

```text
Agent: <agent>
Phase/scope: <fase, ciclo ou range>
Summary: <resultado>
Sources/evidence: <links imutáveis, comandos, saída>
Decisions: <aplicadas, pendentes ou nenhuma>
Changes/validation: <mudanças e validação, ou nenhuma>
Blockers: <blocker ou none>
Next action: <ação e owner>
```

### Exceção: source-set no body (`issue-writer`)

O `issue-writer` registra o envelope no **body da issue** (estrutura de
`templates/03-issue-template.md`), não em comentário. Se a issue já existir
(incl. draft), **sobrescreva/edite o body** com a proposta atual; refine e
materialização pós-aprovação também atualizam o body. Comentários append-only
permanecem para os demais papéis.

## Evidência de implementação e review

Um comentário do executor cobre o plano aprovado como uma unidade e inclui
ciclo de plano, base SHA, commits/PR quando houver, arquivos alterados,
verificação e `DONE`, `DONE_WITH_CONCERNS` ou `BLOCKED`. Só os dois primeiros
estão prontos para review. `BLOCKED` para o fluxo até resolução ou cancelamento
explícito do usuário.

Um `delivery-reviewer` independente cobre o range de implementação, cita a
evidência e o range revisado, e dá um veredito literal. Achados
Critical/Important usam `file:line`, impacto, ação necessária e
`Resume: Phase 4`.

## Evidência de fechamento

A Fase 6 publica commit/PR, evidência do executor, review independente,
evidência de DoD e status da entrega. Trabalho cancelado retém evidência
imutável do cancelamento; trabalho bloqueado retém sua resolução. A auditoria
final também usa o envelope.
